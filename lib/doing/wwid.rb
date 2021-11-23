#!/usr/bin/ruby
# frozen_string_literal: true

require 'deep_merge'
require 'open3'
require 'pp'
require 'shellwords'
require 'erb'

module Doing
  ##
  ## Main "What Was I Doing" methods
  ##
  class WWID
    attr_reader   :additional_configs, :current_section, :doing_file, :content

    attr_accessor :config, :config_file, :auto_tag, :default_option

    # include Util

    ##
    ## Initializes the object.
    ##
    def initialize
      @timers = {}
      @recorded_items = []
      @content = {}
      @doingrc_needs_update = false
      @default_config_file = '.doingrc'
      @auto_tag = true
      @user_home = Util.user_home
    end

    ##
    ## Logger
    ##
    ## Responds to :debug, :info, :warn, and :error
    ##
    ## Each method takes a topic, and a message or block
    ##
    ## Example: debug('Hooks', 'Hook 1 triggered')
    ##
    def logger
      @logger ||= Doing.logger
    end

    ##
    ## Initializes the doing file.
    ##
    ## @param      path  [String] Override path to a doing file, optional
    ##
    def init_doing_file(path = nil)
      @doing_file =  File.expand_path(@config['doing_file'])

      if path.nil?
        create(@doing_file) unless File.exist?(@doing_file)
        input = IO.read(@doing_file)
        input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
      elsif File.exist?(File.expand_path(path)) && File.file?(File.expand_path(path)) && File.stat(File.expand_path(path)).size.positive?
        @doing_file = File.expand_path(path)
        input = IO.read(File.expand_path(path))
        input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
      elsif path.length < 256
        @doing_file = File.expand_path(path)
        create(path)
        input = IO.read(File.expand_path(path))
        input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
      end

      @other_content_top = []
      @other_content_bottom = []

      section = 'Uncategorized'
      lines = input.split(/[\n\r]/)
      current = 0

      lines.each do |line|
        next if line =~ /^\s*$/

        if line =~ /^(\S[\S ]+):\s*(@\S+\s*)*$/
          section = Regexp.last_match(1)
          @content[section] = {}
          @content[section][:original] = line
          @content[section][:items] = []
          current = 0
        elsif line =~ /^\s*- (\d{4}-\d\d-\d\d \d\d:\d\d) \| (.*)/
          date = Regexp.last_match(1).strip
          title = Regexp.last_match(2).strip
          item = Item.new(date, title, section)
          @content[section][:items].push(item)
          current += 1
        elsif current.zero?
          # if content[section][:items].length - 1 == current
          @other_content_top.push(line)
        elsif line =~ /^\S/
          @other_content_bottom.push(line)
        else
          prev_item = @content[section][:items][current - 1]
          prev_item.note = Note.new unless prev_item.note

          prev_item.note.add(line)
          # end
        end
      end
      Hooks.trigger :post_read, self
    end

    ##
    ## Create a new doing file
    ##
    def create(filename = nil)
      filename = @doing_file if filename.nil?
      return if File.exist?(filename) && File.stat(filename).size.positive?

      File.open(filename, 'w+') do |f|
        f.puts "#{@config['current_section']}:"
      end
    end

    ##
    ## Create a process for an editor and wait for the file handle to return
    ##
    ## @param      input  [String] Text input for editor
    ##
    def fork_editor(input = '')
      # raise NonInteractive, 'Non-interactive terminal' unless $stdout.isatty || ENV['DOING_EDITOR_TEST']

      raise MissingEditor, 'No EDITOR variable defined in environment' if Util.default_editor.nil?

      tmpfile = Tempfile.new(['doing', '.md'])

      File.open(tmpfile.path, 'w+') do |f|
        f.puts input
        f.puts "\n# The first line is the entry title, any lines after that are added as a note"
      end

      pid = Process.fork { system("#{Util.editor_with_args} #{tmpfile.path}") }

      trap('INT') do
        begin
          Process.kill(9, pid)
        rescue StandardError
          Errno::ESRCH
        end
        tmpfile.unlink
        tmpfile.close!
        exit 0
      end

      Process.wait(pid)

      begin
        if $?.exitstatus == 0
          input = IO.read(tmpfile.path)
        else
          exit_now! 'Cancelled'
        end
      ensure
        tmpfile.close
        tmpfile.unlink
      end

      input.split(/\n/).delete_if(&:ignore?).join("\n")
    end

    ##
    ## Takes a multi-line string and formats it as an entry
    ##
    ## @param      input  [String] The string to parse
    ##
    ## @return     [Array] [[String]title, [Note]note]
    ##
    def format_input(input)
      raise EmptyInput, 'No content in entry' if input.nil? || input.strip.empty?

      input_lines = input.split(/[\n\r]+/).delete_if(&:ignore?)
      title = input_lines[0]&.strip
      raise EmptyInput, 'No content in first line' if title.nil? || title.strip.empty?

      note = Note.new
      note.add(input_lines[1..-1]) if input_lines.length > 1
      # If title line ends in a parenthetical, use that as the note
      if note.empty? && title =~ /\s+\(.*?\)$/
        title.sub!(/\s+\((.*?)\)$/) do
          m = Regexp.last_match
          note.add(m[1])
          ''
        end
      end

      note.strip_lines!
      note.compress

      [title, note]
    end

    ##
    ## Converts input string into a Time object when input takes on the
    ##             following formats:
    ##             - interval format e.g. '1d2h30m', '45m' etc.
    ##             - a semantic phrase e.g. 'yesterday 5:30pm'
    ##             - a strftime e.g. '2016-03-15 15:32:04 PDT'
    ##
    ## @param      input  [String] String to chronify
    ##
    ## @return     [DateTime] result
    ##
    def chronify(input, future: false, guess: :begin)
      now = Time.now
      raise InvalidTimeExpression, "Invalid time expression #{input.inspect}" if input.to_s.strip == ''

      secs_ago = if input.match(/^(\d+)$/)
                   # plain number, assume minutes
                   Regexp.last_match(1).to_i * 60
                 elsif (m = input.match(/^(?:(?<day>\d+)d)?(?:(?<hour>\d+)h)?(?:(?<min>\d+)m)?$/i))
                   # day/hour/minute format e.g. 1d2h30m
                   [[m['day'], 24 * 3600],
                    [m['hour'], 3600],
                    [m['min'], 60]].map { |qty, secs| qty ? (qty.to_i * secs) : 0 }.reduce(0, :+)
                 end

      if secs_ago
        now - secs_ago
      else
        Chronic.parse(input, { guess: guess, context: future ? :future : :past, ambiguous_time_range: 8 })
      end
    end

    ##
    ## Converts simple strings into seconds that can be added to a Time
    ##             object
    ##
    ## @param      qty   [String] HH:MM or XX[dhm][[XXhm][XXm]] (1d2h30m, 45m,
    ##                   1.5d, 1h20m, etc.)
    ##
    ## @return     [Integer] seconds
    ##
    def chronify_qty(qty)
      minutes = 0
      case qty.strip
      when /^(\d+):(\d\d)$/
        minutes += Regexp.last_match(1).to_i * 60
        minutes += Regexp.last_match(2).to_i
      when /^(\d+(?:\.\d+)?)([hmd])?$/
        amt = Regexp.last_match(1)
        type = Regexp.last_match(2).nil? ? 'm' : Regexp.last_match(2)

        minutes = case type.downcase
                  when 'm'
                    amt.to_i
                  when 'h'
                    (amt.to_f * 60).round
                  when 'd'
                    (amt.to_f * 60 * 24).round
                  else
                    minutes
                  end
      end
      minutes * 60
    end

    ##
    ## List sections
    ##
    ## @return     [Array] section titles
    ##
    def sections
      @content.keys
    end

    ##
    ## Adds a section.
    ##
    ## @param      title  [String] The new section title
    ##
    def add_section(title)
      if @content.key?(title.cap_first)
        raise InvalidSection, %(section "#{title.cap_first}" already exists)
      end

      @content[title.cap_first] = { :original => "#{title}:", :items => [] }
      logger.info('New section:', %("#{title.cap_first}"))
    end

    ##
    ## Attempt to match a string with an existing section
    ##
    ## @param      frag     [String] The user-provided string
    ## @param      guessed  [Boolean] already guessed and failed
    ##
    def guess_section(frag, guessed: false, suggest: false)
      return 'All' if frag =~ /^all$/i
      frag ||= @config['current_section']

      sections.each { |sect| return sect.cap_first if frag.downcase == sect.downcase }
      section = false
      re = frag.split('').join('.*?')
      sections.each do |sect|
        next unless sect =~ /#{re}/i

        logger.debug('Match:', %(Assuming "#{sect}" from "#{frag}"))
        section = sect
        break
      end

      return section if suggest

      unless section || guessed
        alt = guess_view(frag, guessed: true, suggest: true)
        if alt
          meant_view = yn("#{Color.boldwhite}Did you mean `#{Color.yellow}doing view #{alt}#{Color.boldwhite}`?", default_response: 'n')

          raise WrongCommand.new("run again with #{"doing view #{alt}".boldwhite}", topic: 'Try again:') if meant_view

        end

        res = yn("#{Color.boldwhite}Section #{frag.yellow}#{Color.boldwhite} not found, create it", default_response: 'n')

        if res
          add_section(frag.cap_first)
          write(@doing_file)
          return frag.cap_first
        end

        raise InvalidSection.new("unknown section #{frag.yellow}", topic: 'Missing:')
      end
      section ? section.cap_first : guessed
    end

    ##
    ## Ask a yes or no question in the terminal
    ##
    ## @param      question          [String] The question
    ##                               to ask
    ## @param      default_response  (Bool)   default
    ##                               response if no input
    ##
    ## @return     (Bool) yes or no
    ##
    def yn(question, default_response: false)
      if default_response.is_a?(String)
        default = default_response =~ /y/i ? true : false
      else
        default = default_response
      end

      # if global --default is set, answer default
      return default if @default_option

      # if this isn't an interactive shell, answer default
      return default unless $stdout.isatty

      # clear the buffer
      if ARGV&.length
        ARGV.length.times do
          ARGV.shift
        end
      end
      system 'stty cbreak'

      cw = Color.white
      cbw = Color.boldwhite
      cbg = Color.boldgreen
      cd = Color.default

      options = unless default.nil?
                  "#{cw}[#{default ? "#{cbg}Y#{cw}/#{cbw}n" : "#{cbw}y#{cw}/#{cbg}N"}#{cw}]#{cd}"
                else
                  "#{cw}[#{cbw}y#{cw}/#{cbw}n#{cw}]#{cd}"
                end
      $stdout.syswrite "#{cbw}#{question.sub(/\?$/, '')} #{options}#{cbw}?#{cd} "
      res = $stdin.sysread 1
      puts
      system 'stty cooked'

      res.chomp!
      res.downcase!

      return default if res.empty?

      res =~ /y/i ? true : false
    end

    ##
    ## Attempt to match a string with an existing view
    ##
    ## @param      frag     [String] The user-provided string
    ## @param      guessed  [Boolean] already guessed
    ##
    def guess_view(frag, guessed: false, suggest: false)
      views.each { |view| return view if frag.downcase == view.downcase }
      view = false
      re = frag.split('').join('.*?')
      views.each do |v|
        next unless v =~ /#{re}/i

        logger.debug('Match:', %(Assuming "#{v}" from "#{frag}"))
        view = v
        break
      end
      unless view || guessed
        alt = guess_section(frag, guessed: true, suggest: true)
        meant_view = yn("Did you mean `doing show #{alt}`?", default_response: 'n')

        raise WrongCommand.new("run again with #{"doing show #{alt}".yellow}", topic: 'Try again:') if meant_view

        raise InvalidView.new(%(unkown view #{alt.yellow}), topic: 'Missing:')
      end
      view
    end

    ##
    ## Adds an entry
    ##
    ## @param      title    [String] The entry title
    ## @param      section  [String] The section to add to
    ## @param      opt      [Hash] Additional Options: :date, :note, :back, :timed
    ##
    def add_item(title, section = nil, opt = {})
      section ||= @config['current_section']
      add_section(section) unless @content.key?(section)
      opt[:date] ||= Time.now
      opt[:note] ||= []
      opt[:back] ||= Time.now
      opt[:timed] ||= false

      opt[:note] = opt[:note].lines if opt[:note].is_a?(String)

      title = [title.strip.cap_first]
      title = title.join(' ')

      if @auto_tag
        title = autotag(title)
        title.add_tags!(@config['default_tags']) unless @config['default_tags'].empty?
      end

      title.gsub!(/ +/, ' ')
      entry = Item.new(opt[:back], title.strip, section)
      entry.note = opt[:note].map(&:chomp) unless opt[:note].join('').strip == ''
      items = @content[section][:items]
      if opt[:timed]
        items.reverse!
        items.each_with_index do |i, x|
          next if i.title =~ / @done/

          items[x].title = "#{i.title} @done(#{opt[:back].strftime('%F %R')})"
          break
        end
        items.reverse!
      end

      items.push(entry)
      # logger.count(:added, level: :debug)
      logger.info('New entry:', %(added "#{entry.title}" to #{section}))
    end

    ##
    ## Remove items from a list that already exist in @content
    ##
    ## @param      items       [Array] The items to deduplicate
    ## @param      no_overlap  [Boolean] Remove items with overlapping time spans
    ##
    def dedup(items, no_overlap = false)

      combined = []
      @content.each do |_k, v|
        combined += v[:items]
      end

      items.delete_if do |item|
        duped = false
        combined.each do |comp|
          duped = no_overlap ? item.overlapping_time?(comp) : item.same_time?(comp)
          break if duped
        end
        logger.count(:skipped, level: :debug, message: '%count overlapping %items') if duped
        # logger.log_now(:debug, 'Skipped:', "overlapping entry: #{item.title}") if duped
        duped
      end
    end

    ##
    ## Imports external entries
    ##
    ## @param      paths  [String] Path to JSON report file
    ## @param      opt    [Hash] Additional Options
    ##
    def import(paths, opt = {})
      Plugins.plugins[:import].each do |_, options|
        next unless opt[:type] =~ /^(#{options[:trigger].normalize_trigger})$/i

        if paths.count.positive?
          paths.each do |path|
            options[:class].import(self, path, options: opt)
          end
        else
          options[:class].import(self, nil, options: opt)
        end
        break
      end
    end

    ##
    ## Return the content of the last note for a given section
    ##
    ## @param      section  [String] The section to retrieve from, default
    ##                      All
    ##
    def last_note(section = 'All')
      section = guess_section(section)

      last_item = last_entry({ section: section })

      raise NoEntryError, 'No entry found' unless last_item

      logger.log_now(:info, 'Edit note:', last_item.title)

      note = last_item.note&.to_s || ''
      "#{last_item.title}\n# EDIT BELOW THIS LINE ------------\n#{note}"
    end

    def reset_item(item, resume: false)
      item.date = Time.now
      if resume
        item.tag('done', remove: true)
      end
      logger.info('Reset:', %(Reset #{resume ? 'and resumed ' : ''} "#{item.title}" in #{item.section}))
      item
    end

    def repeat_item(item, opt = {})
      original = item.dup
      if item.should_finish?
        if item.should_time?
          item.title.tag!('done', value: Time.now.strftime('%F %R'))
        else
          item.title.tag!('done')
        end
      end

      # Remove @done tag
      title = item.title.sub(/\s*@done(\(.*?\))?/, '').chomp
      section = opt[:in].nil? ? item.section : guess_section(opt[:in])
      @auto_tag = false

      note = opt[:note] || Note.new

      if opt[:editor]
        to_edit = title
        to_edit += "\n#{note.to_s}" unless note.empty?
        new_item = fork_editor(to_edit)
        title, note = format_input(new_item)

        if title.nil? || title.empty?
          logger.warn('Skipped:', 'No content provided')
          return
        end
      end

      update_item(original, item)
      add_item(title, section, { note: note, back: opt[:date], timed: true })
      write(@doing_file)
    end

    ##
    ## Restart the last entry
    ##
    ## @param      opt   [Hash] Additional Options
    ##
    def repeat_last(opt = {})
      opt[:section] ||= 'all'
      opt[:note] ||= []
      opt[:tag] ||= []
      opt[:tag_bool] ||= :and

      last = last_entry(opt)
      if last.nil?
        logger.warn('Skipped:', 'No previous entry found')
        return
      end

      repeat_item(last, opt)
    end

    ##
    ## Get the last entry
    ##
    ## @param      opt   [Hash] Additional Options
    ##
    def last_entry(opt = {})
      opt[:tag_bool] ||= :and
      opt[:section] ||= @config['current_section']

      items = filter_items([], opt: opt)

      logger.debug('Filtered:', "Parameters matched #{items.count} entries")

      if opt[:interactive]
        last_entry = choose_from_items(items, {
          menu: true,
          header: '',
          prompt: 'Select an entry > ',
          multiple: false,
          sort: false,
          show_if_single: true
        }, include_section: opt[:section] =~ /^all$/i )
      else
        last_entry = items.max_by { |item| item.date }
      end

      last_entry
    end

    def fzf
      fzf_dir = File.join(File.dirname(__FILE__), '../helpers/fzf')
      FileUtils.mkdir_p(fzf_dir) unless File.directory?(fzf_dir)
      fzf = File.join(fzf_dir, 'bin/fzf')
      return fzf if File.exist?(fzf)

      Doing.logger.log_now(:warn, 'Downloading and installing FZF. This will only happen once')
      Doing.logger.log_now(:warn, 'fzf is copyright Junegunn Choi <https://github.com/junegunn/fzf/blob/master/LICENSE>')
      res = `git clone --depth 1 https://github.com/junegunn/fzf.git #{fzf_dir}`
      res = `#{fzf_dir}/install --bin --no-key-bindings --no-completion --no-update-rc --no-bash --no-zsh --no-fish`

      raise DoingRuntimeError unless File.exist?(fzf)

      fzf
    end

    ##
    ## Generate a menu of options and allow user selection
    ##
    ## @return     [String] The selected option
    ##
    def choose_from(options, prompt: 'Make a selection: ', multiple: false, sorted: true, fzf_args: [])
      return nil unless $stdout.isatty

      # fzf_args << '-1' # User is expecting a menu, and even if only one it seves as confirmation
      fzf_args << %(--prompt "#{prompt}")
      fzf_args << '--multi' if multiple
      header = "esc: cancel,#{multiple ? ' tab: multi-select, ctrl-a: select all,' : ''} return: confirm"
      fzf_args << %(--header "#{header}")
      options.sort! if sorted
      res = `echo #{Shellwords.escape(options.join("\n"))}|#{fzf} #{fzf_args.join(' ')}`
      return false if res.strip.size.zero?

      res
    end

    def all_tags(items, opt: {})
      all_tags = []
      items.each { |item| all_tags.concat(item.tags).uniq! }
      all_tags.sort
    end

    def tag_groups(items, opt: {})
      all_items = filter_items(items, opt: opt)
      tags = all_tags(all_items, opt: {})
      tag_groups = {}
      tags.each do |tag|
        tag_groups[tag] ||= []
        tag_groups[tag] = filter_items(all_items, opt: { tag: tag, tag_bool: :or })
      end

      tag_groups
    end

    def fuzzy_filter_items(items, opt: {})
      scannable = items.map.with_index { |item, idx| "#{item.title} #{item.note.join(' ')}".gsub(/[|*?!]/, '') + "|#{idx}"  }.join("\n")

      fzf_args = [
        '--multi',
        %(--filter="#{opt[:search].sub(/^'?/, "'")}"),
        '--no-sort',
        '-d "\|"',
        '--nth=1'
      ]
      if opt[:case]
        fzf_args << case opt[:case].normalize_case
                    when :sensitive
                      '+i'
                    when :ignore
                      '-i'
                    end
      end
      # fzf_args << '-e' if opt[:exact]
      # puts fzf_args.join(' ')
      res = `echo #{Shellwords.escape(scannable)}|#{fzf} #{fzf_args.join(' ')}`
      selected = []
      res.split(/\n/).each do |item|
        idx = item.match(/\|(\d+)$/)[1].to_i
        selected.push(items[idx])
      end
      selected
    end

    ##
    ## Filter items based on search criteria
    ##
    ## @param      items  [Array] The items to filter (if empty, filters all items)
    ## @param      opt    [Hash] The filter parameters
    ##
    ## @option opt [String] :section
    ## @option opt [Boolean] :unfinished
    ## @option opt [Array or String] :tag  (Array or comma-separated string)
    ## @option opt [Symbol] :tag_bool  (:and, :or, :not)
    ## @option opt [String] :search  (string, optional regex with //)
    ## @option opt [Array] :date_filter  [[Time]start, [Time]end]
    ## @option opt [Boolean] :only_timed
    ## @option opt [String] :before  (Date/Time string, unparsed)
    ## @option opt [String] :after  (Date/Time string, unparsed)
    ## @option opt [Boolean] :today
    ## @option opt [Boolean] :yesterday
    ## @option opt [Number] :count  (Number to return)
    ## @option opt [String] :age  ('old' or 'new')
    ##
    def filter_items(items = [], opt: {})
      if items.nil? || items.empty?
        section = opt[:section] ? guess_section(opt[:section]) : 'All'

        items = if section =~ /^all$/i
                  @content.each_with_object([]) { |(_k, v), arr| arr.concat(v[:items].dup) }
                else
                  @content[section][:items].dup
                end
      end

      items.sort_by! { |item| [item.date, item.title.downcase] }.reverse

      filtered_items = items.select do |item|
        keep = true
        if opt[:unfinished]
          finished = item.tags?('done', :and)
          finished = opt[:not] ? !finished : finished
          keep = false if finished
        end

        if keep && opt[:tag]
          opt[:tag_bool] ||= :and
          tag_match = opt[:tag].nil? || opt[:tag].empty? ? true : item.tags?(opt[:tag], opt[:tag_bool])
          keep = false unless tag_match
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:search]
          search_match = if opt[:search].nil? || opt[:search].empty?
                           true
                         else
                           item.search(opt[:search], case_type: opt[:case].normalize_case, fuzzy: opt[:fuzzy])
                         end

          keep = false unless search_match
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:date_filter]&.length == 2
          start_date = opt[:date_filter][0]
          end_date = opt[:date_filter][1]

          in_date_range = if end_date
                            item.date >= start_date && item.date <= end_date
                          else
                            item.date.strftime('%F') == start_date.strftime('%F')
                          end
          keep = false unless in_date_range
          keep = opt[:not] ? !keep : keep
        end

        keep = false if keep && opt[:only_timed] && !item.interval

        if keep && opt[:tag_filter] && !opt[:tag_filter]['tags'].empty?
          keep = item.tags?(opt[:tag_filter]['tags'], opt[:tag_filter]['bool'])
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:before]
          time_string = opt[:before]
          cutoff = chronify(time_string, guess: :begin)
          keep = cutoff && item.date <= cutoff
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:after]
          time_string = opt[:after]
          cutoff = chronify(time_string, guess: :end)
          keep = cutoff && item.date >= cutoff
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:today]
          keep = item.date >= Date.today.to_time && item.date < Date.today.next_day.to_time
          keep = opt[:not] ? !keep : keep
        elsif keep && opt[:yesterday]
          keep = item.date >= Date.today.prev_day.to_time && item.date < Date.today.to_time
          keep = opt[:not] ? !keep : keep
        end

        keep
      end
      count = opt[:count] && opt[:count].positive? ? opt[:count] : filtered_items.length

      if opt[:age] =~ /^o/i
        filtered_items.slice(0, count).reverse
      else
        filtered_items.reverse.slice(0, count)
      end

    end

    ##
    ## Display an interactive menu of entries
    ##
    ## @param      opt   [Hash] Additional options
    ##
    ## Options hash is shared with #filter_items and #act_on
    ##
    def interactive(opt = {})
      section = opt[:section] ? guess_section(opt[:section]) : 'All'

      search = nil

      if opt[:search]
        search = opt[:search]
        search.sub!(/^'?/, "'") if opt[:exact]
        opt[:search] = search
      end

      opt[:query] = opt[:search] if opt[:search] && !opt[:query]
      opt[:query] = "!#{opt[:query]}" if opt[:not]
      opt[:multiple] = true
      opt[:show_if_single] = true
      items = filter_items([], opt: { section: section, search: opt[:search], fuzzy: opt[:fuzzy], case: opt[:case], not: opt[:not] })

      selection = choose_from_items(items, opt, include_section: section =~ /^all$/i)

      raise NoResults, 'no items selected' if selection.nil? || selection.empty?

      act_on(selection, opt)
    end

    ##
    ## Create an interactive menu to select from a set of Items
    ##
    ## @param      items            [Array] list of items
    ## @param      opt              [Hash] options
    ## @param      include_section  [Boolean] include section
    ##
    ## @option opt [String] :header
    ## @option opt [String] :prompt
    ## @option opt [String] :query
    ## @option opt [Boolean] :show_if_single
    ## @option opt [Boolean] :menu
    ## @option opt [Boolean] :sort
    ## @option opt [Boolean] :multiple
    ## @option opt [Symbol] :case (:sensitive, :ignore, :smart)
    ##
    def choose_from_items(items, opt = {}, include_section: false)
      return items unless $stdout.isatty

      return nil unless items.count.positive?

      opt[:case] ||= :smart
      opt[:header] ||= "Arrows: navigate, tab: mark for selection, ctrl-a: select all, enter: commit"
      opt[:prompt] ||= "Select entries to act on > "

      pad = items.length.to_s.length
      options = items.map.with_index do |item, i|
        out = [
          format("%#{pad}d", i),
          ') ',
          format('%13s', item.date.relative_date),
          ' | ',
          item.title
        ]
        if include_section
          out.concat([
            ' (',
            item.section,
            ') '
          ])
        end
        out.join('')
      end

      fzf_args = [
        %(--header="#{opt[:header]}"),
        %(--prompt="#{opt[:prompt].sub(/ *$/, ' ')}"),
        opt[:multiple] ? '--multi' : '--no-multi',
        '-0',
        '--bind ctrl-a:select-all',
        %(-q "#{opt[:query]}"),
        '--info=inline'
      ]
      fzf_args.push('-1') unless opt[:show_if_single]
      fzf_args << case opt[:case].normalize_case
                  when :sensitive
                    '+i'
                  when :ignore
                    '-i'
                  end
      fzf_args << '-e' if opt[:exact]


      unless opt[:menu]
        raise InvalidArgument, "Can't skip menu when no query is provided" unless opt[:query] && !opt[:query].empty?

        fzf_args.concat([%(--filter="#{opt[:query]}"), opt[:sort] ? '' : '--no-sort'])
      end

      res = `echo #{Shellwords.escape(options.join("\n"))}|#{fzf} #{fzf_args.join(' ')}`
      selected = []
      res.split(/\n/).each do |item|
        idx = item.match(/^ *(\d+)\)/)[1].to_i
        selected.push(items[idx])
      end

      opt[:multiple] ? selected : selected[0]
    end

    ##
    ## Perform actions on a set of entries. If
    ##             no valid action is included in the opt
    ##             hash and the terminal is a TTY, a menu
    ##             will be presented
    ##
    ## @param      items  [Array] Array of Items to affect
    ## @param      opt    [Hash] Options and actions to perform
    ##
    ## @option opt [Boolean] :editor
    ## @option opt [Boolean] :delete
    ## @option opt [String] :tag
    ## @option opt [Boolean] :flag
    ## @option opt [Boolean] :finish
    ## @option opt [Boolean] :cancel
    ## @option opt [Boolean] :archive
    ## @option opt [String] :output
    ## @option opt [String] :save_to
    ## @option opt [Boolean] :again
    ## @option opt [Boolean] :resume
    ##
    def act_on(items, opt = {})
      actions = %i[editor delete tag flag finish cancel archive output save_to again resume]
      has_action = false
      single = items.count == 1

      actions.each do |a|
        if opt[a]
          has_action = true
          break
        end
      end

      unless has_action
        actions = [
          'add tag',
          'remove tag',
          'cancel',
          'delete',
          'finish',
          'flag',
          'archive',
          'move',
          'edit',
          'output formatted'
        ]

        actions.concat(['resume/repeat', 'begin/reset']) if items.count == 1

        choice = choose_from(actions,
                             prompt: 'What do you want to do with the selected items? > ',
                             multiple: true,
                             sorted: false,
                             fzf_args: ["--height=#{actions.count + 3}", '--tac', '--no-sort', '--info=hidden'])
        return unless choice

        to_do = choice.strip.split(/\n/)
        to_do.each do |action|
          case action
          when /resume/
            opt[:resume] = true
          when /reset/
            opt[:reset] = true
          when /(add|remove) tag/
            type = action =~ /^add/ ? 'add' : 'remove'
            raise InvalidArgument, "'add tag' and 'remove tag' can not be used together" if opt[:tag]

            print "#{Color.yellow}Tag to #{type}: #{Color.reset}"
            tag = $stdin.gets
            next if tag =~ /^ *$/

            opt[:tag] = tag.strip.sub(/^@/, '')
            opt[:remove] = true if type == 'remove'
          when /output formatted/
            plugins = Plugins.available_plugins(type: :export).sort
            output_format = choose_from(plugins,
                                        prompt: 'Which output format? > ',
                                        fzf_args: ["--height=#{plugins.count + 3}", '--tac', '--no-sort', '--info=hidden'])
            next if tag =~ /^ *$/

            raise UserCancelled unless output_format

            opt[:output] = output_format.strip
            res = opt[:force] ? false : yn('Save to file?', default_response: 'n')
            if res
              print "#{Color.yellow}File path/name: #{Color.reset}"
              filename = $stdin.gets.strip
              next if filename.empty?

              opt[:save_to] = filename
            end
          when /archive/
            opt[:archive] = true
          when /delete/
            opt[:delete] = true
          when /edit/
            opt[:editor] = true
          when /finish/
            opt[:finish] = true
          when /cancel/
            opt[:cancel] = true
          when /move/
            section = choose_section.strip
            opt[:move] = section.strip unless section =~ /^ *$/
          when /flag/
            opt[:flag] = true
          end
        end
      end

      if opt[:resume] || opt[:reset]
        if items.count > 1
          raise InvalidArgument, 'resume and restart can only be used on a single entry'
        else
          item = items[0]
          if opt[:resume] && !opt[:reset]
            repeat_item(item, { editor: opt[:editor] })
          elsif opt[:reset]
            if item.tags?('done', :and) && !opt[:resume]
              res = opt[:force] ? true : yn('Remove @done tag?', default_response: 'y')
            else
              res = opt[:resume]
            end
            update_item(item, reset_item(item, resume: res))
          end
          write(@doing_file)
        end
        return
      end

      if opt[:delete]
        res = opt[:force] ? true : yn("Delete #{items.size} items?", default_response: 'y')
        if res
          items.each { |item| delete_item(item, single: items.count == 1) }
          write(@doing_file)
        end
        return
      end

      if opt[:flag]
        tag = @config['marker_tag'] || 'flagged'
        items.map! do |item|
          tag_item(item, tag, date: false, remove: opt[:remove], single: single)
        end
      end

      if opt[:finish] || opt[:cancel]
        tag = 'done'
        items.map! do |item|
          if item.should_finish?
            should_date = !opt[:cancel] && item.should_time?
            tag_item(item, tag, date: should_date, remove: opt[:remove], single: single)
          end
        end
      end

      if opt[:tag]
        tag = opt[:tag]
        items.map! do |item|
          tag_item(item, tag, date: false, remove: opt[:remove], single: single)
        end
      end

      if opt[:archive] || opt[:move]
        section = opt[:archive] ? 'Archive' : guess_section(opt[:move])
        items.map! {|item| move_item(item, section) }
      end

      write(@doing_file)

      if opt[:editor]

        editable_items = []

        items.each do |item|
          editable = "#{item.date} | #{item.title}"
          old_note = item.note ? item.note.to_s : nil
          editable += "\n#{old_note}" unless old_note.nil?
          editable_items << editable
        end
        divider = "\n-----------\n"
        input = editable_items.map(&:strip).join(divider) + "\n\n# You may delete entries, but leave all divider lines in place"

        new_items = fork_editor(input).split(/#{divider}/)

        new_items.each_with_index do |new_item, i|

          input_lines = new_item.split(/[\n\r]+/).delete_if(&:ignore?)
          title = input_lines[0]&.strip

          if title.nil? || title =~ /^#{divider.strip}$/ || title.strip.empty?
            delete_item(items[i], single: new_items.count == 1)
          else
            note = input_lines.length > 1 ? input_lines[1..-1] : []

            note.map!(&:strip)
            note.delete_if(&:ignore?)

            date = title.match(/^([\d\-: ]+) \| /)[1]
            title.sub!(/^([\d\-: ]+) \| /, '')

            item = items[i]
            item.title = title
            item.note = note
            item.date = Time.parse(date) || items[i].date
          end
        end

        write(@doing_file)
      end

      if opt[:output]
        items.map! do |item|
          item.title = "#{item.title} @project(#{item.section})"
          item
        end

        @content = { 'Export' => { :original => 'Export:', :items => items } }
        options = { section: 'Export' }


        if opt[:output] =~ /doing/
          options[:output] = 'template'
          options[:template] = '- %date | %title%note'
        else
          options[:output] = opt[:output]
          options[:template] = opt[:template] || nil
        end

        output = list_section(options)

        if opt[:save_to]
          file = File.expand_path(opt[:save_to])
          if File.exist?(file)
            # Create a backup copy for the undo command
            FileUtils.cp(file, "#{file}~")
          end

          File.open(file, 'w+') do |f|
            f.puts output
          end

          logger.warn('File written:', file)
        else
          Doing::Pager.page output
        end
      end
    end

    ##
    ## Tag an item from the index
    ##
    ## @param      item    [Item] The item to tag
    ## @param      tags    [String] The tag to apply
    ## @param      remove  [Boolean] remove tags?
    ## @param      date    [Boolean] Include timestamp?
    ## @param      single  [Boolean] Log as a single change?
    ##
    ## @return     [Item] updated item
    ##
    def tag_item(item, tags, remove: false, date: false, single: false)
      added = []
      removed = []

      tags = tags.to_tags if tags.is_a? ::String

      done_date = Time.now

      tags.each do |tag|
        bool = remove ? :and : :not
        if item.tags?(tag, bool)
          item.tag(tag, remove: remove, value: date ? done_date.strftime('%F %R') : nil)
          remove ? removed.push(tag) : added.push(tag)
        end
      end

      log_change(tags_added: added, tags_removed: removed, count: 1, item: item, single: single)

      item
    end

    ##
    ## Tag the last entry or X entries
    ##
    ## @param      opt   [Hash] Additional Options (see
    ##                   #filter_items for filtering
    ##                   options)
    ##
    ## @see        #filter_items
    ##
    def tag_last(opt = {})
      opt[:count] ||= 1
      opt[:archive] ||= false
      opt[:tags] ||= ['done']
      opt[:sequential] ||= false
      opt[:date] ||= false
      opt[:remove] ||= false
      opt[:autotag] ||= false
      opt[:back] ||= false
      opt[:unfinished] ||= false
      opt[:section] = opt[:section] ? guess_section(opt[:section]) : 'All'

      items = filter_items([], opt: opt)

      if opt[:interactive]
        items = choose_from_items(items, {
                                    menu: true,
                                    header: '',
                                    prompt: 'Select entries to tag > ',
                                    multiple: true,
                                    sort: true,
                                    show_if_single: true
                                  }, include_section: opt[:section] =~ /^all$/i)

        raise NoResults, 'no items selected' if items.empty?

      end

      raise NoResults, 'no items matched your search' if items.empty?

      items.each do |item|
        added = []
        removed = []

        if opt[:autotag]
          new_title = autotag(item.title) if @auto_tag
          if new_title == item.title
            logger.count(:skipped, level: :debug, message: '%count unchaged %items')
            # logger.debug('Autotag:', 'No changes')
          else
            logger.count(:added_tags)
            logger.write(items.count == 1 ? :info : :debug, 'Tagged:', new_title)
            item.title = new_title
          end
        else
          if opt[:sequential]
            next_entry = next_item(item)

            done_date = if next_entry.nil?
                          Time.now
                        else
                          next_entry.date - 60
                        end
          elsif opt[:took]
            if item.date + opt[:took] > Time.now
              item.date = Time.now - opt[:took]
              done_date = Time.now
            else
              done_date = item.date + opt[:took]
            end
          elsif opt[:back]
            done_date = if opt[:back].is_a? Integer
                          item.date + opt[:back]
                        else
                          item.date + (opt[:back] - item.date)
                        end
          else
            done_date = Time.now
          end

          opt[:tags].each do |tag|
            if tag == 'done' && !item.should_finish?

              Doing.logger.debug('Skipped:', "Item in never_finish: #{item.title}")
              logger.count(:skipped, level: :debug)
              next
            end

            tag = tag.strip
            if opt[:remove] || opt[:rename]
              rename_to = nil
              if opt[:rename]
                rename_to = tag
                tag = opt[:rename]
              end
              old_title = item.title.dup
              item.title.tag!(tag, remove: opt[:remove], rename_to: rename_to, regex: opt[:regex])
              if old_title != item.title
                removed << tag
                added << rename_to if rename_to
              else
                logger.count(:skipped, level: :debug)
              end
            else
              old_title = item.title.dup
              should_date = opt[:date] && item.should_time?
              item.title.tag!('done', remove: true) if tag =~ /done/ && !should_date
              item.title.tag!(tag, value: should_date ? done_date.strftime('%F %R') : nil)
              added << tag if old_title != item.title
            end
          end
        end

        log_change(tags_added: added, tags_removed: removed, item: item, single: items.count == 1)

        item.note.add(opt[:note]) if opt[:note]

        if opt[:archive] && opt[:section] != 'Archive' && (opt[:count]).positive?
          move_item(item, 'Archive', label: true)
        elsif opt[:archive] && opt[:count].zero?
          logger.warn('Skipped:', 'Archiving is skipped when operating on all entries')
        end
      end

      write(@doing_file)
    end

    ##
    ## Move item from current section to
    ##             destination section
    ##
    ## @param      item     [Item] The item to move
    ## @param      section  [String] The destination section
    ##
    ## @return     [Item] Updated item
    ##
    def move_item(item, section, label: true)
      from = item.section
      new_item = @content[item.section][:items].delete(item)
      new_item.title.sub!(/(?:@from\(.*?\))?(.*)$/, "\\1 @from(#{from})") if label
      new_item.section = section

      @content[section][:items].concat([new_item])

      logger.count(section == 'Archive' ? :archived : :moved)
      logger.debug("#{section == 'Archive' ? 'Archived' : 'Moved'}:",
                  "#{new_item.title.truncate(60)} from #{from} to #{section}")
      new_item
    end

    ##
    ## Get next item in the index
    ##
    ## @param      item     [Item] target item
    ## @param      options  [Hash] additional options
    ## @see #filter_items
    ##
    ## @return     [Item] the next chronological item in the index
    ##
    def next_item(item, options = {})
      items = filter_items([], opt: options)

      idx = items.index(item)

      idx.positive? ? items[idx - 1] : nil
    end

    ##
    ## Delete an item from the index
    ##
    ## @param      item  The item
    ##
    def delete_item(item, single: false)
      section = item.section

      section_items = @content[section][:items]
      deleted = section_items.delete(item)
      logger.count(:deleted)
      logger.info('Entry deleted:', deleted.title) if single
    end

    ##
    ## Update an item in the index with a modified item
    ##
    ## @param      old_item  The old item
    ## @param      new_item  The new item
    ##
    def update_item(old_item, new_item)
      section = old_item.section

      section_items = @content[section][:items]
      s_idx = section_items.index { |item| item.equal?(old_item) }

      raise ItemNotFound, 'Unable to find item in index, did it mutate?' unless s_idx

      return if section_items[s_idx].equal?(new_item)

      section_items[s_idx] = new_item
      logger.count(:updated)
      logger.info('Entry updated:', section_items[s_idx].title.truncate(60))
      new_item
    end

    ##
    ## Edit the last entry
    ##
    ## @param      section  [String] The section, default "All"
    ##
    def edit_last(section: 'All', options: {})
      options[:section] = guess_section(section)

      item = last_entry(options)

      if item.nil?
        logger.debug('Skipped:', 'No entries found')
        return
      end

      content = [item.title.dup]
      content << item.note.to_s unless item.note.empty?
      new_item = fork_editor(content.join("\n"))
      title, note = format_input(new_item)

      if title.nil? || title.empty?
        logger.debug('Skipped:', 'No content provided')
      elsif title == item.title && note.equal?(item.note)
        logger.debug('Skipped:', 'No change in content')
      else
        item.title = title
        item.note.add(note, replace: true)
        logger.info('Edited:', item.title)

        write(@doing_file)
      end
    end

    ##
    ## Accepts one tag and the raw text of a new item if the
    ## passed tag is on any item, it's replaced with @done.
    ## if new_item is not nil, it's tagged with the passed
    ## tag and inserted. This is for use where only one
    ## instance of a given tag should exist (@meanwhile)
    ##
    ## @param      target_tag  [String] Tag to replace
    ## @param      opt         [Hash] Additional Options
    ##
    def stop_start(target_tag, opt = {})
      tag = target_tag.dup
      opt[:section] ||= @config['current_section']
      opt[:archive] ||= false
      opt[:back] ||= Time.now
      opt[:new_item] ||= false
      opt[:note] ||= false

      opt[:section] = guess_section(opt[:section])

      tag.sub!(/^@/, '')

      found_items = 0

      @content[opt[:section]][:items].each_with_index do |item, i|
        next unless item.title =~ /@#{tag}/

        item.title.add_tags!([tag, 'done'], remove: true)
        item.tag('done', value: opt[:back].strftime('%F %R'))

        found_items += 1

        if opt[:archive] && opt[:section] != 'Archive'
          item.title = item.title.sub(/(?:@from\(.*?\))?(.*)$/, "\\1 @from(#{item.section})")
          move_item(item, 'Archive', label: false)
          logger.count(:completed_archived)
          logger.info('Completed/archived:', item.title)
        else
          logger.count(:completed)
          logger.info('Completed:', item.title)
        end
      end

      logger.debug('Skipped:', "No active @#{tag} tasks found.") if found_items.zero?

      if opt[:new_item]
        title, note = format_input(opt[:new_item])
        note.add(opt[:note]) if opt[:note]
        title.tag!(tag)
        add_item(title.cap_first, opt[:section], { note: note, back: opt[:back] })
      end

      write(@doing_file)
    end

    ##
    ## Write content to file or STDOUT
    ##
    ## @param      file  [String] The filepath to write to
    ##
    def write(file = nil, backup: true)
      Hooks.trigger :pre_write, self, file
      output = combined_content

      if file.nil?
        $stdout.puts output
      else
        Util.write_to_file(file, output, backup: backup)
        run_after if @config.key?('run_after')
      end
    end

    ##
    ## Restore a backed up version of a file
    ##
    ## @param      file  [String] The filepath to restore
    ##
    def restore_backup(file)
      if File.exist?("#{file}~")
        FileUtils.cp("#{file}~", file)
        logger.warn('File update:', "Restored #{file.sub(/^#{@user_home}/, '~')}")
      else
        logger.error('Restore error:', 'No backup file found')
      end
    end

    ##
    ## Rename doing file with date and start fresh one
    ##
    def rotate(opt = {})
      keep = opt[:keep] || 0
      tags = []
      tags.concat(opt[:tag].split(/ *, */).map { |t| t.sub(/^@/, '').strip }) if opt[:tag]
      bool  = opt[:bool] || :and
      sect = opt[:section] !~ /^all$/i ? guess_section(opt[:section]) : 'all'

      if sect =~ /^all$/i
        all_sections = sections.dup
      else
        all_sections = [sect]
      end

      counter = 0
      new_content = {}


      all_sections.each do |section|
        items = @content[section][:items].dup
        new_content[section] = {}
        new_content[section][:original] = @content[section][:original]
        new_content[section][:items] = []

        moved_items = []
        if !tags.empty? || opt[:search] || opt[:before]
          if opt[:before]
            time_string = opt[:before]
            cutoff = chronify(time_string, guess: :begin)
          end

          items.delete_if do |item|
            if ((!tags.empty? && item.tags?(tags, bool)) || (opt[:search] && item.search(opt[:search].to_s)) || (opt[:before] && item.date < cutoff))
              moved_items.push(item)
              counter += 1
              true
            else
              false
            end
          end
          @content[section][:items] = items
          new_content[section][:items] = moved_items
          logger.warn('Rotated:', "#{moved_items.length} items from #{section}")
        else
          new_content[section][:items] = []
          moved_items = []

          count = items.length < keep ? items.length : keep

          if items.count > count
            moved_items.concat(items[count..-1])
          else
            moved_items.concat(items)
          end

          @content[section][:items] = if count.zero?
                                         []
                                       else
                                         items[0..count - 1]
                                       end
          new_content[section][:items] = moved_items

          logger.warn('Rotated:', "#{items.length - count} items from #{section}")
        end
      end

      write(@doing_file)

      file = @doing_file.sub(/(\.\w+)$/, "_#{Time.now.strftime('%Y-%m-%d')}\\1")
      if File.exist?(file)
        init_doing_file(file)
        @content.deep_merge(new_content)
        logger.warn('File update:', "added entries to existing file: #{file}")
      else
        @content = new_content
        logger.warn('File update:', "created new file: #{file}")
      end

      write(file, backup: false)
    end

    ##
    ## Generate a menu of sections and allow user selection
    ##
    ## @return     [String] The selected section name
    ##
    def choose_section
      choice = choose_from(sections.sort, prompt: 'Choose a section > ', fzf_args: ['--height=60%'])
      choice ? choice.strip : choice
    end

    ##
    ## List available views
    ##
    ## @return     [Array] View names
    ##
    def views
      @config.has_key?('views') ? @config['views'].keys : []
    end

    ##
    ## Generate a menu of views and allow user selection
    ##
    ## @return     [String] The selected view name
    ##
    def choose_view
      choice = choose_from(views.sort, prompt: 'Choose a view > ', fzf_args: ['--height=60%'])
      choice ? choice.strip : choice
    end

    ##
    ## Gets a view from configuration
    ##
    ## @param      title  [String] The title of the view to retrieve
    ##
    def get_view(title)
      return @config['views'][title] if @config['views'].has_key?(title)

      false
    end

    ##
    ## Display contents of a section based on options
    ##
    ## @param      opt   [Hash] Additional Options
    ##
    def list_section(opt = {})
      opt[:config_template] ||= 'default'
      cfg = @config.dig('templates', opt[:config_template]).deep_merge({
        'wrap_width' => @config['wrap_width'] || 0,
        'date_format' => @config['default_date_format'],
        'order' => @config['order'] || 'asc',
        'tags_color' => @config['tags_color']
      })
      opt[:count] ||= 0
      opt[:age] ||= 'newest'
      opt[:format] ||= cfg['date_format']
      opt[:order] ||= cfg['order'] || 'asc'
      opt[:tag_order] ||= 'asc'
      if opt[:tags_color].nil?
        opt[:tags_color] = cfg['tags_color'] || false
      end
      opt[:template] ||= cfg['template']

      # opt[:highlight] ||= true
      title = ''
      is_single = true
      if opt[:section].nil?
        opt[:section] = choose_section
        title = opt[:section]
      elsif opt[:section].instance_of?(String)
        if opt[:section] =~ /^all$/i
          title = if opt[:page_title]
                    opt[:page_title]
                  elsif opt[:tag_filter] && opt[:tag_filter]['bool'].normalize_bool != :not
                    opt[:tag_filter]['tags'].map { |tag| "@#{tag}" }.join(' + ')
                  else
                    'doing'
                  end
        else
          title = guess_section(opt[:section])
        end
      end

      items = filter_items([], opt: opt).reverse

      items.reverse! if opt[:order] =~ /^d/i

      if opt[:interactive]
        opt[:menu] = !opt[:force]
        opt[:query] = '' # opt[:search]
        opt[:multiple] = true
        selected = choose_from_items(items, opt, include_section: opt[:section] =~ /^all$/i )

        raise NoResults, 'no items selected' if selected.empty?

        act_on(selected, opt)
        return
      end


      opt[:output] ||= 'template'

      opt[:wrap_width] ||= @config['templates']['default']['wrap_width'] || 0

      output(items, title, is_single, opt)
    end

    ##
    ## Move entries from a section to Archive or other specified
    ##             section
    ##
    ## @param      section      [String] The source section
    ## @param      options      [Hash] Options
    ##
    def archive(section = @config['current_section'], options = {})
      count       = options[:keep] || 0
      destination = options[:destination] || 'Archive'
      tags        = options[:tags] || []
      bool        = options[:bool] || :and

      section = choose_section if section.nil? || section =~ /choose/i
      archive_all = section =~ /^all$/i # && !(tags.nil? || tags.empty?)
      section = guess_section(section) unless archive_all

      add_section('Archive') if destination =~ /^archive$/i && !sections.include?('Archive')

      destination = guess_section(destination)

      if sections.include?(destination) && (sections.include?(section) || archive_all)
        do_archive(section, destination, { count: count, tags: tags, bool: bool, search: options[:search], label: options[:label], before: options[:before] })
        write(doing_file)
      else
        raise InvalidArgument, 'Either source or destination does not exist'
      end
    end

    ##
    ## Show all entries from the current day
    ##
    ## @param      times   [Boolean] show times
    ## @param      output  [String] output format
    ## @param      opt     [Hash] Options
    ##
    def today(times = true, output = nil, opt = {})
      opt[:totals] ||= false
      opt[:sort_tags] ||= false

      cfg = @config['templates']['today'].deep_merge(@config['templates']['default']).deep_merge({
        'wrap_width' => @config['wrap_width'] || 0,
        'date_format' => @config['default_date_format'],
        'order' => @config['order'] || 'asc',
        'tags_color' => @config['tags_color']
      })
      options = {
        after: opt[:after],
        before: opt[:before],
        count: 0,
        format: cfg['date_format'],
        order: cfg['order'] || 'asc',
        output: output,
        section: opt[:section],
        sort_tags: opt[:sort_tags],
        template: cfg['template'],
        times: times,
        today: true,
        totals: opt[:totals],
        wrap_width: cfg['wrap_width'],
        tags_color: cfg['tags_color'],
        config_template: 'today'
      }
      list_section(options)
    end

    ##
    ## Display entries within a date range
    ##
    ## @param      dates    [Array] [start, end]
    ## @param      section  [String] The section
    ## @param      times    (Bool) Show times
    ## @param      output   [String] Output format
    ## @param      opt      [Hash] Additional Options
    ##
    def list_date(dates, section, times = nil, output = nil, opt = {})
      opt[:totals] ||= false
      opt[:sort_tags] ||= false
      section = guess_section(section)
      # :date_filter expects an array with start and end date
      dates = [dates, dates] if dates.instance_of?(String)

      list_section({ section: section, count: 0, order: 'asc', date_filter: dates, times: times,
                     output: output, totals: opt[:totals], sort_tags: opt[:sort_tags], config_template: 'default' })
    end

    ##
    ## Show entries from the previous day
    ##
    ## @param      section  [String] The section
    ## @param      times    (Bool) Show times
    ## @param      output   [String] Output format
    ## @param      opt      [Hash] Additional Options
    ##
    def yesterday(section, times = nil, output = nil, opt = {})
      opt[:totals] ||= false
      opt[:sort_tags] ||= false
      section = guess_section(section)
      y = (Time.now - (60 * 60 * 24)).strftime('%Y-%m-%d')
      opt[:after] = "#{y} #{opt[:after]}" if opt[:after]
      opt[:before] = "#{y} #{opt[:before]}" if opt[:before]

      options = {
        after: opt[:after],
        before: opt[:before],
        count: 0,
        order: opt[:order],
        output: output,
        section: section,
        sort_tags: opt[:sort_tags],
        tag_order: opt[:tag_order],
        times: times,
        totals: opt[:totals],
        yesterday: true,
        config_template: 'today'
      }

      list_section(options)
    end

    ##
    ## Show recent entries
    ##
    ## @param      count    [Integer] The number to show
    ## @param      section  [String] The section to show from, default Currently
    ## @param      opt      [Hash] Additional Options
    ##
    def recent(count = 10, section = nil, opt = {})
      times = opt[:t] || true
      opt[:totals] ||= false
      opt[:sort_tags] ||= false

      cfg = @config['templates']['recent'].deep_merge(@config['templates']['default']).deep_merge({
        'wrap_width' => @config['wrap_width'] || 0,
        'date_format' => @config['default_date_format'],
        'order' => @config['order'] || 'asc',
        'tags_color' => @config['tags_color']
      })
      section ||= @config['current_section']
      section = guess_section(section)

      list_section({ section: section, wrap_width: cfg['wrap_width'], count: count,
                     format: cfg['date_format'], template: cfg['template'],
                     order: 'asc', times: times, totals: opt[:totals],
                     sort_tags: opt[:sort_tags], tags_color: opt[:tags_color], config_template: 'recent' })
    end

    ##
    ## Show the last entry
    ##
    ## @param      times    (Bool) Show times
    ## @param      section  [String] Section to pull from, default Currently
    ##
    def last(times: true, section: nil, options: {})
      section = section.nil? || section =~ /all/i ? 'All' : guess_section(section)
      cfg = @config['templates']['last'].deep_merge(@config['templates']['default']).deep_merge({
        'wrap_width' => @config['wrap_width'] || 0,
        'date_format' => @config['default_date_format'],
        'order' => @config['order'] || 'asc',
        'tags_color' => @config['tags_color']
      })

      opts = {
        section: section,
        wrap_width: cfg['wrap_width'],
        count: 1,
        format: cfg['date_format'],
        template: cfg['template'],
        times: times
      }

      if options[:tag]
        opts[:tag_filter] = {
          'tags' => options[:tag],
          'bool' => options[:tag_bool]
        }
      end

      opts[:search] = options[:search] if options[:search]
      opts[:case] = options[:case]
      opts[:not] = options[:negate]
      opts[:config_template] = 'last'
      list_section(opts)
    end

    ##
    ## Uses 'autotag' configuration to turn keywords into tags for time tracking.
    ## Does not repeat tags in a title, and only converts the first instance of an
    ## untagged keyword
    ##
    ## @param      text  [String] The text to tag
    ##
    def autotag(text)
      return unless text
      return text unless @auto_tag

      original = text.dup

      current_tags = text.scan(/@\w+/).map { |t| t.sub(/^@/, '') }
      tagged = {
        whitelisted: [],
        synonyms: [],
        transformed: [],
        replaced: []
      }

      @config['autotag']['whitelist'].each do |tag|
        next if text =~ /@#{tag}\b/i

        text.sub!(/(?<= |\A)(#{tag.strip})(?= |\Z)/i) do |m|
          m.downcase! unless tag =~ /[A-Z]/
          tagged[:whitelisted].push(m)
          "@#{m}"
        end
      end

      @config['autotag']['synonyms'].each do |tag, v|
        v.each do |word|
          next unless text =~ /\b#{word}\b/i

          unless current_tags.include?(tag) || tagged[:whitelisted].include?(tag)
            tagged[:synonyms].push(tag)
            tagged[:synonyms] = tagged[:synonyms].uniq
          end
        end
      end

      if @config['autotag'].key? 'transform'
        @config['autotag']['transform'].each do |tag|
          next unless tag =~ /\S+:\S+/

          rx, r = tag.split(/:/)
          flag_rx = %r{/([r]+)$}
          if r =~ flag_rx
            flags = r.match(flag_rx)[1].split(//)
            r.sub!(flag_rx, '')
          end
          r.gsub!(/\$/, '\\')
          rx.sub!(/^@?/, '@')
          regex = Regexp.new("(?<= |\\A)#{rx}(?= |\\Z)")

          text.sub!(regex) do
            m = Regexp.last_match
            new_tag = r

            m.to_a.slice(1, m.length - 1).each_with_index do |v, idx|
              new_tag.gsub!("\\#{idx + 1}", v)
            end
            # Replace original tag if /r
            if flags&.include?('r')
              tagged[:replaced].concat(new_tag.split(/ /).map { |t| t.sub(/^@/, '') })
              new_tag.split(/ /).map { |t| t.sub(/^@?/, '@') }.join(' ')
            else
              tagged[:transformed].concat(new_tag.split(/ /).map { |t| t.sub(/^@/, '') })
              tagged[:transformed] = tagged[:transformed].uniq
              m[0]
            end
          end
        end
      end


      logger.debug('Autotag:', "whitelisted tags: #{tagged[:whitelisted].log_tags}") unless tagged[:whitelisted].empty?
      logger.debug('Autotag:', "synonyms: #{tagged[:synonyms].log_tags}") unless tagged[:synonyms].empty?
      logger.debug('Autotag:', "transforms: #{tagged[:transformed].log_tags}") unless tagged[:transformed].empty?
      logger.debug('Autotag:', "transform replaced: #{tagged[:replaced].log_tags}") unless tagged[:replaced].empty?

      tail_tags = tagged[:synonyms].concat(tagged[:transformed])
      tail_tags.sort!
      tail_tags.uniq!

      text.add_tags!(tail_tags) unless tail_tags.empty?

      if text == original
        logger.debug('Autotag:', "no change to \"#{text}\"")
      else
        new_tags = tagged[:whitelisted].concat(tail_tags).concat(tagged[:replaced])
        logger.debug('Autotag:', "added #{new_tags.log_tags} to \"#{text}\"")
        logger.count(:autotag, level: :info, count: 1, message: 'autotag updated %count %items')
      end

      text.dedup_tags
    end

    ##
    ## Get total elapsed time for all tags in
    ##             selection
    ##
    ## @param      format        [String] return format (html,
    ##                           json, or text)
    ## @param      sort_by_name  [Boolean] Sort by name if true, otherwise by time
    ## @param      sort_order    [String] The sort order (asc or desc)
    ##
    def tag_times(format: :text, sort_by_name: false, sort_order: 'asc')
      return '' if @timers.empty?

      max = @timers.keys.sort_by { |k| k.length }.reverse[0].length + 1

      total = @timers.delete('All')

      tags_data = @timers.delete_if { |_k, v| v == 0 }
      sorted_tags_data = if sort_by_name
                           tags_data.sort_by { |k, _v| k }
                         else
                           tags_data.sort_by { |_k, v| v }
                         end

      sorted_tags_data.reverse! if sort_order =~ /^asc/i
      case format
      when :html

        output = <<EOS
          <table>
          <caption id="tagtotals">Tag Totals</caption>
          <colgroup>
          <col style="text-align:left;"/>
          <col style="text-align:left;"/>
          </colgroup>
          <thead>
          <tr>
            <th style="text-align:left;">project</th>
            <th style="text-align:left;">time</th>
          </tr>
          </thead>
          <tbody>
EOS
        sorted_tags_data.reverse.each do |k, v|
          if v > 0
            output += "<tr><td style='text-align:left;'>#{k}</td><td style='text-align:left;'>#{'%02d:%02d:%02d' % format_time(v)}</td></tr>\n"
          end
        end
        tail = <<EOS
        <tr>
          <td style="text-align:left;" colspan="2"></td>
        </tr>
        </tbody>
        <tfoot>
        <tr>
          <td style="text-align:left;"><strong>Total</strong></td>
          <td style="text-align:left;">#{'%02d:%02d:%02d' % format_time(total)}</td>
        </tr>
        </tfoot>
        </table>
EOS
        output + tail
      when :markdown
        pad = sorted_tags_data.map {|k, v| k }.group_by(&:size).max.last[0].length
        output = <<~EOS
  | #{' ' * (pad - 7) }project | time     |
  | #{'-' * (pad - 1)}: | :------- |
        EOS
        sorted_tags_data.reverse.each do |k, v|
          if v > 0
            output += "| #{' ' * (pad - k.length)}#{k} | #{'%02d:%02d:%02d' % format_time(v)} |\n"
          end
        end
        tail = "[Tag Totals]"
        output + tail
      when :json
        output = []
        sorted_tags_data.reverse.each do |k, v|
          d, h, m = format_time(v)
          output << {
            'tag' => k,
            'seconds' => v,
            'formatted' => format('%<d>02d:%<h>02d:%<m>02d', d: d, h: h, m: m)
          }
        end
        output
      when :human
        output = []
        sorted_tags_data.reverse.each do |k, v|
          spacer = ''
          (max - k.length).times do
            spacer += ' '
          end
          _d, h, m = format_time(v, human: true)
          output.push("┃ #{spacer}#{k}:#{format('%<h> 4dh %<m>02dm', h: h, m: m)} ┃")
        end

        header = '┏━━ Tag Totals '
        (max - 2).times { header += '━' }
        header += '┓'
        footer = '┗'
        (max + 12).times { footer += '━' }
        footer += '┛'
        divider = '┣'
        (max + 12).times { divider += '━' }
        divider += '┫'
        output = output.empty? ? '' : "\n#{header}\n#{output.join("\n")}"
        d, h, m = format_time(total, human: true)
        output += "\n#{divider}"
        spacer = ''
        (max - 6).times do
          spacer += ' '
        end
        total = "┃ #{spacer}total: "
        total += format('%<h> 4dh %<m>02dm', h: h, m: m)
        total += ' ┃'
        output += "\n#{total}"
        output += "\n#{footer}"
        output
      else
        output = []
        sorted_tags_data.reverse.each do |k, v|
          spacer = ''
          (max - k.length).times do
            spacer += ' '
          end
          d, h, m = format_time(v)
          output.push("#{k}:#{spacer}#{format('%<d>02d:%<h>02d:%<m>02d', d: d, h: h, m: m)}")
        end

        output = output.empty? ? '' : "\n--- Tag Totals ---\n#{output.join("\n")}"
        d, h, m = format_time(total)
        output += "\n\nTotal tracked: #{format('%<d>02d:%<h>02d:%<m>02d', d: d, h: h, m: m)}\n"
        output
      end
    end

    ##
    ## Gets the interval between entry's start
    ##             date and @done date
    ##
    ## @param      item       [Item] The entry
    ## @param      formatted  [Boolean] Return human readable
    ##                        time (default seconds)
    ## @param      record     [Boolean] Add the interval to the
    ##                        total for each tag
    ##
    ## @return     Interval in seconds, or [d, h, m] array if
    ##             formatted is true. False if no end date or
    ##             interval is 0
    ##
    def get_interval(item, formatted: true, record: true)
      if item.interval
        seconds = item.interval
        record_tag_times(item, seconds) if record
        return seconds.positive? ? seconds : false unless formatted

        return seconds.positive? ? format('%02d:%02d:%02d', *format_time(seconds)) : false
      end

      false
    end

    ##
    ## Format human readable time from seconds
    ##
    ## @param      seconds  [Integer] Seconds
    ##
    def format_time(seconds, human: false)
      return [0, 0, 0] if seconds.nil?

      if seconds.class == String && seconds =~ /(\d+):(\d+):(\d+)/
        h = Regexp.last_match(1)
        m = Regexp.last_match(2)
        s = Regexp.last_match(3)
        seconds = (h.to_i * 60 * 60) + (m.to_i * 60) + s.to_i
      end
      minutes = (seconds / 60).to_i
      hours = (minutes / 60).to_i
      if human
        minutes = (minutes % 60).to_i
        [0, hours, minutes]
      else
        days = (hours / 24).to_i
        hours = (hours % 24).to_i
        minutes = (minutes % 60).to_i
        [days, hours, minutes]
      end
    end

    private

    ##
    ## Wraps doing file content with additional
    ##             header/footer content
    ##
    ## @return     [String] concatenated content
    ##
    def combined_content
      output = @other_content_top ? "#{@other_content_top.join("\n")}\n" : ''

      @content.each do |title, section|
        output += "#{section[:original]}\n"
        output += list_section({ section: title, template: "\t- %date | %title%t2note", highlight: false, wrap_width: 0, tags_color: false })
      end

      output += @other_content_bottom.join("\n") unless @other_content_bottom.nil?
      output.uncolor
    end

    ##
    ## Generate output using available export plugins
    ##
    ## @param      items      [Array] The items
    ## @param      title      [String] Page title
    ## @param      is_single  [Boolean] Indicates if single
    ##                        section
    ## @param      opt        [Hash] Additional options
    ##
    ## @return     [String] formatted output based on opt[:output]
    ##             template trigger
    ##
    def output(items, title, is_single, opt = {})
      out = nil

      raise InvalidArgument, 'Unknown output format' unless opt[:output] =~ Plugins.plugin_regex(type: :export)

      export_options = { page_title: title, is_single: is_single, options: opt }

      Plugins.plugins[:export].each do |_, options|
        next unless opt[:output] =~ /^(#{options[:trigger].normalize_trigger})$/i

        out = options[:class].render(self, items, variables: export_options)
        break
      end

      out
    end

    ##
    ## Record times for item tags
    ##
    ## @param      item  [Item] The item to record
    ##
    def record_tag_times(item, seconds)
      item_hash = "#{item.date.strftime('%s')}#{item.title}#{item.section}"
      return if @recorded_items.include?(item_hash)
      item.title.scan(/(?mi)@(\S+?)(\(.*\))?(?=\s|$)/).each do |m|
        k = m[0] == 'done' ? 'All' : m[0].downcase
        if @timers.key?(k)
          @timers[k] += seconds
        else
          @timers[k] = seconds
        end
        @recorded_items.push(item_hash)
      end
    end

    ##
    ## Helper function, performs the actual archiving
    ##
    ## @param      sect         [String] The source section
    ## @param      destination  [String] The destination
    ##                          section
    ## @param      opt          [Hash] Additional Options
    ##
    def do_archive(sect, destination, opt = {})
      count = opt[:count] || 0
      tags  = opt[:tags] || []
      bool  = opt[:bool] || :and
      label = opt[:label] || true

      if sect =~ /^all$/i
        all_sections = sections.dup
        all_sections.delete(destination)
      else
        all_sections = [sect]
      end

      counter = 0

      all_sections.each do |section|
        items = @content[section][:items].dup

        moved_items = []
        if !tags.empty? || opt[:search] || opt[:before]
          if opt[:before]
            time_string = opt[:before]
            cutoff = chronify(time_string, guess: :begin)
          end

          items.delete_if do |item|
            if ((!tags.empty? && item.tags?(tags, bool)) || (opt[:search] && item.search(opt[:search].to_s)) || (opt[:before] && item.date < cutoff))
              moved_items.push(item)
              counter += 1
              true
            else
              false
            end
          end
          moved_items.each do |item|
            if label
              item.title = if section == @config['current_section']
                             item.title.sub(/(?: ?@from\(.*?\))?(.*)$/, '\1')
                           else
                             item.title.sub(/(?: ?@from\(.*?\))?(.*)$/, "\\1 @from(#{section})")
                           end
              logger.debug('Moved:', "#{item.title} from #{section} to #{destination}")
            end
          end

          @content[section][:items] = items
          @content[destination][:items].concat(moved_items)
          if moved_items.length.positive?
            logger.count(destination == 'Archive' ? :archived : :moved,
                         level: :info,
                         count: moved_items.length,
                         message: "%count %items from #{section} to #{destination}")
          else
            logger.info('Skipped:', 'No items were moved')
          end
        else
          count = items.length if items.length < count

          items.map! do |item|
            if label
              item.title = if section == @config['current_section']
                             item.title.sub(/(?: ?@from\(.*?\))?(.*)$/, '\1')
                           else
                             item.title.sub(/(?: ?@from\(.*?\))?(.*)$/, "\\1 @from(#{section})")
                           end
              logger.debug('Moved:', "#{item.title} from #{section} to #{destination}")
            end
            item
          end

          if items.count > count
            @content[destination][:items].concat(items[count..-1])
          else
            @content[destination][:items].concat(items)
          end

          @content[section][:items] = if count.zero?
                                        []
                                      else
                                        items[0..count - 1]
                                      end

          logger.count(destination == 'Archive' ? :archived : :moved,
                       level: :info,
                       count: items.length - count,
                       message: "%count %items from #{section} to #{destination}")
        end
      end
    end

    def run_after
      return unless @config.key?('run_after')

      _, stderr, status = Open3.capture3(@config['run_after'])
      return unless status.exitstatus.positive?

      logger.log_now(:error, 'Script error:', "Error running #{@config['run_after']}")
      logger.log_now(:error, 'STDERR output:', stderr)
    end

    def log_change(tags_added: [], tags_removed: [], count: 1, item: nil, single: false)
      if tags_added.empty? && tags_removed.empty?
        logger.count(:skipped, level: :debug, message: '%count %items with no change', count: count)
      else
        if tags_added.empty?
          logger.count(:skipped, level: :debug, message: 'no tags added to %count %items')
        else
          if single && item
            logger.info('Tagged:', %(added #{tags_added.count == 1 ? 'tag' : 'tags'} #{tags_added.map {|t| "@#{t}"}.join(', ')} to #{item.title}))
          else
            logger.count(:added_tags, level: :info, tag: tags_added, message: '%tags added to %count %items')
          end
        end

        if tags_removed.empty?
          logger.count(:skipped, level: :debug, message: 'no tags removed from %count %items')
        else
          if single && item
            logger.info('Untagged:', %(removed #{tags_removed.count == 1 ? 'tag' : 'tags'} #{tags_added.map {|t| "@#{t}"}.join(', ')} from #{item.title}))
          else
            logger.count(:removed_tags, level: :info, tag: tags_removed, message: '%tags removed from %count %items')
          end
        end
      end
    end
  end
end
