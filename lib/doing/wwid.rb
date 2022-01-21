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

    include Color
    # include Util

    ##
    ## Initializes the object.
    ##
    def initialize
      @timers = {}
      @recorded_items = []
      @content = Items.new
      @auto_tag = true
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
        logger.debug('Read:', "read file #{@doing_file}")
      elsif File.exist?(File.expand_path(path)) && File.file?(File.expand_path(path)) && File.stat(File.expand_path(path)).size.positive?
        @doing_file = File.expand_path(path)
        input = IO.read(File.expand_path(path))
        input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
        logger.debug('Read:', "read file #{File.expand_path(path)}")
      elsif path.length < 256
        @doing_file = File.expand_path(path)
        create(path)
        input = IO.read(File.expand_path(path))
        input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
        logger.debug('Read:', "read file #{File.expand_path(path)}")
      end

      @other_content_top = []
      @other_content_bottom = []

      section = nil
      lines = input.split(/[\n\r]/)

      lines.each do |line|
        next if line =~ /^\s*$/

        if line =~ /^(\S[\S ]+):\s*(@\S+\s*)*$/
          section = Regexp.last_match(1)
          @content.add_section(Section.new(section, original: line), log: false)
        elsif line =~ /^\s*- (\d{4}-\d\d-\d\d \d\d:\d\d) \| (.*)/
          if section.nil?
            section = 'Uncategorized'
            @content.add_section(Section.new(section, original: 'Uncategorized:'), log: false)
          end

          date = Regexp.last_match(1).strip
          title = Regexp.last_match(2).strip
          item = Item.new(date, title, section)
          @content.push(item)
        elsif @content.count.zero?
          # if content[section].items.length - 1 == current
          @other_content_top.push(line)
        elsif line =~ /^\S/
          @other_content_bottom.push(line)
        else
          prev_item = @content.last
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

      FileUtils.mkdir_p(File.dirname(filename)) unless File.directory?(File.dirname(filename))

      File.open(filename, 'w+') do |f|
        f.puts "#{@config['current_section']}:"
      end
    end

    ##
    ## Create a process for an editor and wait for the file handle to return
    ##
    ## @param      input  [String] Text input for editor
    ##
    def fork_editor(input = '', message: :default)
      # raise NonInteractive, 'Non-interactive terminal' unless $stdout.isatty || ENV['DOING_EDITOR_TEST']

      raise MissingEditor, 'No EDITOR variable defined in environment' if Util.default_editor.nil?

      tmpfile = Tempfile.new(['doing', '.md'])

      File.open(tmpfile.path, 'w+') do |f|
        f.puts input
        unless message.nil?
          f.puts message == :default ? "# The first line is the entry title, any lines after that are added as a note" : message
        end
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

      date = nil
      iso_rx = /\d{4}-\d\d-\d\d \d\d:\d\d/
      date_rx = /^(?:\s*- )?(?<date>.*?) \| (?=\S)/

      raise EmptyInput, 'No content' if title.sub(/^.*?\| */, '').strip.empty?

      title.expand_date_tags(@config['date_tags'])

      if title =~ date_rx
        m = title.match(date_rx)
        d = m['date']
        date = if d =~ iso_rx
                 Time.parse(d)
               else
                 d.chronify(guess: :begin)
               end
        title.sub!(date_rx, '').strip!
      end

      note = Note.new
      note.add(input_lines[1..-1]) if input_lines.length > 1
      # If title line ends in a parenthetical, use that as the note
      if note.empty? && title =~ /\s+\(.*?\)$/
        title.sub!(/\s+\((?<note>.*?)\)$/) do
          m = Regexp.last_match
          note.add(m['note'])
          ''
        end
      end

      note.strip_lines!
      note.compress

      [date, title, note]
    end

    ##
    ## List sections
    ##
    ## @return     [Array] section titles
    ##
    def sections
      @content.section_titles
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

      return frag.cap_first if @content.section?(frag)

      section = nil
      re = frag.to_rx(distance: 2, case_type: :ignore)
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
          meant_view = Prompt.yn("#{boldwhite("Did you mean")} `#{yellow("doing view #{alt}")}#{boldwhite}`?", default_response: 'n')

          raise WrongCommand.new("run again with #{"doing view #{alt}".boldwhite}", topic: 'Try again:') if meant_view

        end

        res = Prompt.yn("#{boldwhite}Section #{frag.yellow}#{boldwhite} not found, create it", default_response: 'n')

        if res
          @content.add_section(frag.cap_first, log: true)
          write(@doing_file)
          return frag.cap_first
        end

        raise InvalidSection.new("unknown section #{frag.bold.white}", topic: 'Missing:')
      end
      section ? section.cap_first : guessed
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
      re = frag.to_rx(distance: 2, case_type: :ignore)
      views.each do |v|
        next unless v =~ /#{re}/i

        logger.debug('Match:', %(Assuming "#{v}" from "#{frag}"))
        view = v
        break
      end
      unless view || guessed
        alt = guess_section(frag, guessed: true, suggest: true)

        raise InvalidView.new(%(unknown view #{frag.bold.white}), topic: 'Missing:') unless alt

        meant_view = Prompt.yn("Did you mean `doing show #{alt}`?", default_response: 'n')

        raise WrongCommand.new("run again with #{"doing show #{alt}".yellow}", topic: 'Try again:') if meant_view

        raise InvalidView.new(%(unknown view #{alt.bold.white}), topic: 'Missing:')
      end
      view
    end

    def add_with_editor(**options)
      raise MissingEditor, 'No EDITOR variable defined in environment' if Util.default_editor.nil?

      input = options[:date].strftime('%F %R | ')
      input += options[:title]
      input += "\n#{options[:note]}" if options[:note]
      input = fork_editor(input).strip

      d, title, note = format_input(input)
      raise EmptyInput, 'No content' if title.empty?

      if options[:ask]
        ask_note = Doing::Prompt.read_lines(prompt: 'Add a note')
        note.add(ask_note) unless ask_note.empty?
      end

      date = d.nil? ? options[:date] : d
      finish = options[:finish_last] || false
      add_item(title.cap_first, options[:section], { note: note, back: date, timed: finish })
      write(@doing_file)
    end

    ##
    ## Adds an entry
    ##
    ## @param      title    [String] The entry title
    ## @param      section  [String] The section to add to
    ## @param      opt      [Hash] Additional Options
    ##
    ## @option opt :date [Date] item start date
    ## @option opt :note [Array] item note (will be converted if value is String)
    ## @option opt :back [Date] backdate
    ## @option opt :timed [Boolean] new item is timed entry, marks previous entry as @done
    ##
    def add_item(title, section = nil, opt)
      opt ||= {}
      section ||= @config['current_section']
      @content.add_section(section, log: false)
      opt[:back] ||= opt[:date] ? opt[:date] : Time.now
      opt[:date] ||= Time.now
      note = Note.new
      opt[:timed] ||= false

      note.add(opt[:note]) if opt[:note]

      title = [title.strip.cap_first]
      title = title.join(' ')

      if @auto_tag
        title = autotag(title)
        title.add_tags!(@config['default_tags']) unless @config['default_tags'].empty?
      end

      title.compress!
      entry = Item.new(opt[:back], title.strip, section)
      entry.note = note

      items = @content.dup
      if opt[:timed]
        items.reverse!
        items.each_with_index do |i, x|
          next if i.title =~ / @done/

          finish_date = verify_duration(i.date, opt[:back], title: i.title)
          items[x].tag('done', value: finish_date.strftime('%F %R'))
          break
        end
      end

      Hooks.trigger :pre_entry_add, self, entry

      @content.push(entry)
      # logger.count(:added, level: :debug)
      logger.info('New entry:', %(added "#{entry.date.relative_date}: #{entry.title}" to #{section}))

      Hooks.trigger :post_entry_added, self, entry.dup
    end

    ##
    ## Remove items from an array that already exist in
    ## @content based on start and end times
    ##
    ## @param      items       [Array] The items to
    ##                         deduplicate
    ## @param      no_overlap  [Boolean] Remove items with
    ##                         overlapping time spans
    ##
    def dedup(items, no_overlap: false)
      items.delete_if do |item|
        duped = false
        @content.each do |comp|
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
    def import(paths, opt)
      opt ||= {}
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

    # Reset start date to current time, optionally remove
    # done tag (resume)
    #
    # @param      item    [Item] the item to reset/resume
    # @param      resume  [Boolean] removing @done tag if true
    #
    def reset_item(item, date: nil, resume: false)
      date ||= Time.now
      item.date = date
      item.tag('done', remove: true) if resume
      logger.info('Reset:', %(Reset #{resume ? 'and resumed ' : ''} "#{item.title}" in #{item.section}))
      item
    end

    # Duplicate an item and add it as a new item
    #
    # @param      item    [Item] the item to duplicate
    # @param      opt     [Hash] additional options
    #
    # @option opt :editor [Boolean] open new item in editor
    # @option opt :date   [String] set start date
    # @option opt :in     [String] add new item to section :in
    # @option opt :note   [Note] add note to new item
    #
    # @return     nothing
    #
    def repeat_item(item, opt)
      opt ||= {}
      if item.should_finish?
        if item.should_time?
          finish_date = verify_duration(item.date, Time.now, title: item.title)
          item.title.tag!('done', value: finish_date.strftime('%F %R'))
        else
          item.title.tag!('done')
        end
        Hooks.trigger :post_entry_updated, self, item
      end

      # Remove @done tag
      title = item.title.sub(/\s*@done(\(.*?\))?/, '').chomp
      section = opt[:in].nil? ? item.section : guess_section(opt[:in])
      @auto_tag = false

      note = opt[:note] || Note.new

      if opt[:editor]
        start = opt[:date] ? opt[:date] : Time.now
        to_edit = "#{start.strftime('%F %R')} | #{title}"
        to_edit += "\n#{note.strip_lines.join("\n")}" unless note.empty?
        new_item = fork_editor(to_edit)
        date, title, note = format_input(new_item)

        opt[:date] = date unless date.nil?

        if title.nil? || title.empty?
          logger.warn('Skipped:', 'No content provided')
          return
        end
      end

      # @content.update_item(original, item)
      add_item(title, section, { note: note, back: opt[:date], timed: false })
    end

    ##
    ## Restart the last entry
    ##
    ## @param      opt   [Hash] Additional Options
    ##
    def repeat_last(opt)
      opt ||= {}
      opt[:section] ||= 'all'
      opt[:section] = guess_section(opt[:section])
      opt[:note] ||= []
      opt[:tag] ||= []
      opt[:tag_bool] ||= :and

      last = last_entry(opt)
      if last.nil?
        logger.warn('Skipped:', 'No previous entry found')
        return
      end

      repeat_item(last, opt)
      write(@doing_file)
    end

    ##
    ## Get the last entry
    ##
    ## @param      opt   [Hash] Additional Options
    ##
    def last_entry(opt)
      opt ||= {}
      opt[:tag_bool] ||= :and
      opt[:section] ||= @config['current_section']

      items = filter_items(Items.new, opt: opt)

      logger.debug('Filtered:', "Parameters matched #{items.count} entries")

      if opt[:interactive]
        last_entry = Prompt.choose_from_items(items, include_section: opt[:section] =~ /^all$/i,
          menu: true,
          header: '',
          prompt: 'Select an entry > ',
          multiple: false,
          sort: false,
          show_if_single: true
         )
      else
        last_entry = items.max_by { |item| item.date }
      end

      last_entry
    end

    def all_tags(items, opt: {}, counts: false)
      if counts
        all_tags = {}
        items.each do |item|
          item.tags.each do |tag|
            if all_tags.key?(tag.downcase)
              all_tags[tag.downcase] += 1
            else
              all_tags[tag.downcase] = 1
            end
          end
        end

        all_tags.sort_by { |tag, count| count }
      else
        all_tags = []
        items.each { |item| all_tags.concat(item.tags.map(&:downcase)).uniq! }
        all_tags.sort
      end
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
      res = `echo #{Shellwords.escape(scannable)}|#{Prompt.fzf} #{fzf_args.join(' ')}`
      selected = Items.new
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
    ## @option opt [String] :section ('all')
    ## @option opt [Boolean] :unfinished (false)
    ## @option opt [Array or String] :tag ([]) Array or comma-separated string
    ## @option opt [Symbol] :tag_bool (:and) :and, :or, :not
    ## @option opt [String] :search ('') string, optional regex with `/string/`
    ## @option opt [Array] :date_filter (nil) [[Time]start, [Time]end]
    ## @option opt [Boolean] :only_timed (false)
    ## @option opt [String] :before (nil) Date/Time string, unparsed
    ## @option opt [String] :after  (nil) Date/Time string, unparsed
    ## @option opt [Boolean] :today (false) limit to entries from today
    ## @option opt [Boolean] :yesterday (false) limit to entries from yesterday
    ## @option opt [Number] :count (0) max entries to return
    ## @option opt [String] :age (new) 'old' or 'new'
    ## @option opt [Array] :val (nil) Array of tag value queries
    ##
    def filter_items(items = Items.new, opt: {})
      time_rx = /^(\d{1,2}+(:\d{1,2}+)?( *(am|pm))?|midnight|noon)$/

      if items.nil? || items.empty?
        section = opt[:section] ? guess_section(opt[:section]) : 'All'
        items = section =~ /^all$/i ? @content.dup : @content.in_section(section)
      end

      opt[:time_filter] = [nil, nil]
      if opt[:from] && !opt[:date_filter]
        if opt[:from][0].is_a?(String) && opt[:from][0] =~ time_rx
          opt[:time_filter] = opt[:from]
        elsif opt[:from][0].is_a?(Time)
          opt[:date_filter] = opt[:from]
        end
      end

      if opt[:before].is_a?(String) && opt[:before] =~ time_rx
        opt[:time_filter][1] = opt[:before]
        opt[:before] = nil
      end

      if opt[:after].is_a?(String) && opt[:after] =~ time_rx
        opt[:time_filter][0] = opt[:after]
        opt[:after] = nil
      end

      items.sort_by! { |item| [item.date, item.title.downcase] }.reverse

      filtered_items = items.select do |item|
        keep = true
        if opt[:unfinished]
          finished = item.tags?('done', :and)
          finished = opt[:not] ? !finished : finished
          keep = false if finished
        end

        if keep && opt[:val]&.count&.positive?
          bool = opt[:bool].normalize_bool if opt[:bool]
          bool ||= :and
          bool = :and if bool == :pattern

          val_match = opt[:val].nil? || opt[:val].empty? ? true : item.tag_values?(opt[:val], bool)
          keep = false unless val_match
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:tag]
          opt[:tag_bool] = opt[:bool].normalize_bool if opt[:bool]
          opt[:tag_bool] ||= :and
          tag_match = opt[:tag].nil? || opt[:tag].empty? ? true : item.tags?(opt[:tag], opt[:tag_bool])
          keep = false unless tag_match
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:search]
          search_match = if opt[:search].nil? || opt[:search].empty?
                           true
                         else
                           item.search(opt[:search], case_type: opt[:case].normalize_case)
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

        if keep && opt[:time_filter][0] || opt[:time_filter][1]
          start_string = if opt[:time_filter][0].nil?
                           "#{item.date.strftime('%Y-%m-%d')} 12am"
                         else
                           "#{item.date.strftime('%Y-%m-%d')} #{opt[:time_filter][0]}"
                         end
          start_time = start_string.chronify(guess: :begin)

          end_string = if opt[:time_filter][1].nil?
                         "#{item.date.to_datetime.next_day.strftime('%Y-%m-%d')} 12am"
                       else
                         "#{item.date.strftime('%Y-%m-%d')} #{opt[:time_filter][1]}"
                       end
          end_time = end_string.chronify(guess: :end)

          in_time_range = item.date >= start_time && item.date <= end_time
          keep = false unless in_time_range
          keep = opt[:not] ? !keep : keep
        end

        keep = false if keep && opt[:only_timed] && !item.interval

        if keep && opt[:tag_filter]
          keep = item.tags?(opt[:tag_filter]['tags'], opt[:tag_filter]['bool'])
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:before]
          before = opt[:before]
          if before =~ time_rx
            cutoff = "#{item.date.strftime('%Y-%m-%d')} #{before}".chronify(guess: :begin)
          elsif before.is_a?(String)
            cutoff = before.chronify(guess: :begin)
          else
            cutoff = before
          end
          keep = cutoff && item.date <= cutoff
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:after]
          after = opt[:after]
          if after =~ time_rx
            cutoff = "#{item.date.strftime('%Y-%m-%d')} #{after}".chronify(guess: :end)
          elsif after.is_a?(String)
            cutoff = after.chronify(guess: :end)
          else
            cutoff = after
          end
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
      count = opt[:count].to_i&.positive? ? opt[:count].to_i : filtered_items.count

      output = Items.new

      if opt[:age] && opt[:age].normalize_age == :oldest
        output.concat(filtered_items.slice(0, count).reverse)
      else
        output.concat(filtered_items.reverse.slice(0, count))
      end

      output
    end

    def delete_items(items, force: false)
      items.slice(0, 5).each { |i| puts i.to_pretty } unless force
      puts softpurple("+ #{items.size - 5} additional #{'item'.to_p(items.size - 5)}") if items.size > 5 && !force

      res = force ? true : Prompt.yn("Delete #{items.size} #{'item'.to_p(items.size)}?", default_response: 'y')
      return unless res

      items.each { |i| Hooks.trigger :post_entry_removed, self, @content.delete_item(i, single: items.count == 1) }
      write(@doing_file)
    end

    def edit_items(items)
      items.sort_by! { |i| i.date }
      editable_items = []

      items.each do |i|
        editable = "#{i.date.strftime('%F %R')} | #{i.title}"
        old_note = i.note ? i.note.strip_lines.join("\n") : nil
        editable += "\n#{old_note}" unless old_note.nil?
        editable_items << editable
      end
      divider = "-----------"
      notice =<<~EONOTICE
      # - You may delete entries, but leave all divider lines (---) in place.
      # - Start and @done dates replaced with a time string (yesterday 3pm) will
      #   be parsed automatically. Do not delete the pipe (|) between start date
      #   and entry title.
      EONOTICE
      input =  "#{editable_items.map(&:strip).join("\n#{divider}\n")}\n\n#{notice}"

      new_items = fork_editor(input).split(/^#{divider}/).map(&:strip)

      new_items.each_with_index do |new_item, i|
        input_lines = new_item.split(/[\n\r]+/).delete_if(&:ignore?)
        first_line = input_lines[0]&.strip

        if first_line.nil? || first_line =~ /^#{divider.strip}$/ || first_line.strip.empty?
          deleted = @content.delete_item(items[i], single: new_items.count == 1)
          Hooks.trigger :post_entry_removed, self, deleted
          Doing.logger.info('Deleted:', deleted.title)
        else
          date, title, note = format_input(new_item)

          note.map!(&:strip)
          note.delete_if(&:ignore?)
          item = items[i]
          old_item = item.dup
          item.date = date || items[i].date
          item.title = title
          item.note = note
          if (item.equal?(old_item))
            Doing.logger.count(:skipped, level: :debug)
          else
            Doing.logger.count(:updated)
            Hooks.trigger :post_entry_updated, self, item
          end
        end
      end
    end

    ##
    ## Display an interactive menu of entries
    ##
    ## @param      opt   [Hash] Additional options
    ##
    ## Options hash is shared with #filter_items and #act_on
    ##
    def interactive(opt)
      opt ||= {}
      opt[:section] = opt[:section] ? guess_section(opt[:section]) : 'All'

      search = nil

      if opt[:search]
        search = opt[:search]
        search.sub!(/^'?/, "'") if opt[:exact]
        opt[:search] = search
      end

      # opt[:query] = opt[:search] if opt[:search] && !opt[:query]
      opt[:query] = "!#{opt[:query]}" if opt[:query] && opt[:not]
      opt[:multiple] = true
      opt[:show_if_single] = true
      filter_options = %i[after before case date_filter from fuzzy not search section val].each_with_object({}) {
        |k, hsh| hsh[k] = opt[k]
      }
      items = filter_items(Items.new, opt: filter_options)

      menu_options = %i[search query exact multiple show_if_single menu sort case].each_with_object({}) {
        |k, hsh| hsh[k] = opt[k]
      }

      selection = Prompt.choose_from_items(items, include_section: opt[:section] =~ /^all$/i, **menu_options)

      raise NoResults, 'no items selected' if selection.nil? || selection.empty?

      act_on(selection, opt)
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
    def act_on(items, opt)
      opt ||= {}
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
          'autotag',
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

        choice = Prompt.choose_from(actions,
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
          when /autotag/
            opt[:autotag] = true
          when /(add|remove) tag/
            type = action =~ /^add/ ? 'add' : 'remove'
            raise InvalidArgument, "'add tag' and 'remove tag' can not be used together" if opt[:tag]

            tags = type == 'add' ? all_tags(@content) : all_tags(items)

            puts "#{yellow}Separate multiple tags with spaces, hit tab to complete known tags#{type == 'add' ? ', include values with tag(value)' : ''}"
            puts "#{boldgreen}Available tags: #{boldwhite}#{tags.sort.map(&:add_at).join(', ')}" if type == 'remove'
            tag = Prompt.read_line(prompt: "Tags to #{type}", completions: tags)

            # print "#{yellow("Tag to #{type}: ")}#{reset}"
            # tag = $stdin.gets
            next if tag =~ /^ *$/

            opt[:tag] = tag.strip.sub(/^@/, '')
            opt[:remove] = true if type == 'remove'
          when /output formatted/
            plugins = Plugins.available_plugins(type: :export).sort
            output_format = Prompt.choose_from(plugins,
                                               prompt: 'Which output format? > ',
                                               fzf_args: [
                                                 "--height=#{plugins.count + 3}",
                                                 '--tac',
                                                 '--no-sort',
                                                 '--info=hidden'
                                               ])
            next if output_format =~ /^ *$/

            raise UserCancelled unless output_format

            opt[:output] = output_format.strip
            res = opt[:force] ? false : Prompt.yn('Save to file?', default_response: 'n')
            if res
              # print "#{yellow('File path/name: ')}#{reset}"
              # filename = $stdin.gets.strip
              filename = Prompt.read_line(prompt: 'File path/name')
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
        raise InvalidArgument, 'resume and restart can only be used on a single entry' if items.count > 1

        item = items[0]
        if opt[:resume] && !opt[:reset]
          repeat_item(item, { editor: opt[:editor] }) # hooked
        elsif opt[:reset]
          res = Prompt.enter_text('Start date (blank for current time)', default_response: '')
          if res =~ /^ *$/
            date = Time.now
          else
            date = res.chronify(guess: :begin)
          end

          res = if item.tags?('done', :and) && !opt[:resume]
                  opt[:force] ? true : Prompt.yn('Remove @done tag?', default_response: 'y')
                else
                  opt[:resume]
                end
          new_entry = reset_item(item, date: date, resume: res)
          @content.update_item(item, new_entry)
          Hooks.trigger :post_entry_updated, self, new_entry
        end
        write(@doing_file)

        return
      end

      if opt[:delete]
        delete_items(items, force: opt[:force]) # hooked
        return
      end

      if opt[:flag]
        tag = @config['marker_tag'] || 'flagged'
        items.map! do |i|
          i.tag(tag, date: false, remove: opt[:remove], single: single)
          Hooks.trigger :post_entry_updated, self, i
        end
      end

      if opt[:finish] || opt[:cancel]
        tag = 'done'
        items.map! do |i|
          if i.should_finish?
            should_date = !opt[:cancel] && i.should_time?
            i.tag(tag, date: should_date, remove: opt[:remove], single: single)
            Hooks.trigger :post_entry_updated, self, i
          end
        end
      end

      if opt[:autotag]
        items.map! do |i|
          new_title = autotag(i.title)
          if new_title == i.title
            logger.count(:skipped, level: :debug, message: '%count unchaged %items')
            # logger.debug('Autotag:', 'No changes')
          else
            logger.count(:added_tags)
            logger.write(items.count == 1 ? :info : :debug, 'Tagged:', new_title)
            i.title = new_title
            Hooks.trigger :post_entry_updated, self, i
          end
        end
      end

      if opt[:tag]
        tag = opt[:tag]
        items.map! do |i|
          i.tag(tag, date: false, remove: opt[:remove], single: single)
          i.expand_date_tags(@config['date_tags'])
          Hooks.trigger :post_entry_updated, self, i
        end
      end

      if opt[:archive] || opt[:move]
        section = opt[:archive] ? 'Archive' : guess_section(opt[:move])
        items.map! do |i|
          i.move_to(section, label: true)
          Hooks.trigger :post_entry_updated, self, i
        end
      end

      write(@doing_file)

      if opt[:editor]
        edit_items(items) # hooked

        write(@doing_file)
      end

      return unless opt[:output]

      items.each { |i| i.title = "#{i.title} @section(#{i.section})" }

      export_items = Items.new
      export_items.concat(items)
      export_items.add_section(Section.new('Export'), log: false)
      options = { section: 'All' }

      if opt[:output] =~ /doing/
        options[:output] = 'template'
        options[:template] = '- %date | %title%note'
      else
        options[:output] = opt[:output]
        options[:template] = opt[:template] || nil
      end

      output = list_section(options, items: export_items) # hooked

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

    def verify_duration(date, finish_date, title: nil)
      max_elapsed = @config.dig('interaction', 'confirm_longer_than') || 0
      max_elapsed = max_elapsed.chronify_qty if max_elapsed.is_a?(String)
      date = date.chronify(guess: :end, context: :today) if finish_date.is_a?(String)

      elapsed = finish_date - date

      if max_elapsed.positive? && (elapsed > max_elapsed)
        puts boldwhite(title) if title
        human = elapsed.time_string(format: :natural)
        res = Prompt.yn(yellow("Did this entry actually take #{human}"), default_response: true)
        unless res
          new_elapsed = Prompt.enter_text('How long did it take?').chronify_qty
          raise InvalidTimeExpression, 'Unrecognized time span entry' unless new_elapsed.positive?

          finish_date = date + new_elapsed if new_elapsed
        end
      end

      finish_date
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
    def tag_last(opt) # hooked
      opt ||= {}
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

      items = filter_items(Items.new, opt: opt)

      if opt[:interactive]
        items = Prompt.choose_from_items(items, include_section: opt[:section] =~ /^all$/i, menu: true,
                                    header: '',
                                    prompt: 'Select entries to tag > ',
                                    multiple: true,
                                    sort: true,
                                    show_if_single: true)

        raise NoResults, 'no items selected' if items.empty?

      end

      raise NoResults, 'no items matched your search' if items.empty?

      if opt[:tags].empty? && !opt[:autotag]
        completions = opt[:remove] ? all_tags(items) : all_tags(@content)
        if opt[:remove]
          puts "#{yellow}Available tags: #{boldwhite}#{completions.map(&:add_at).join(', ')}"
        else
          puts "#{yellow}Use tab to complete known tags"
        end
        opt[:tags] = Doing::Prompt.read_line(prompt: "Enter tag(s) to #{opt[:remove] ? 'remove' : 'add'}",
                                             completions: completions,
                                             default_response: '').to_tags
        raise UserCancelled, 'No tags provided' if opt[:tags].empty?
      end

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
          else
            done_date = item.calculate_end_date(opt)
          end

          opt[:tags].each do |tag|
            if tag == 'done' && !item.should_finish?

              Doing.logger.debug('Skipped:', "Item in never_finish: #{item.title}")
              logger.count(:skipped, level: :debug)
              next
            end


            tag = tag.strip

            if tag =~ /^done$/
              max_elapsed = @config.dig('interaction', 'confirm_longer_than') || 0
              max_elapsed = max_elapsed.chronify_qty if max_elapsed.is_a?(String)
              elapsed = done_date - item.date

              if max_elapsed.positive? && (elapsed > max_elapsed) && !opt[:took]
                puts boldwhite(item.title)
                human = elapsed.time_string(format: :natural)
                res = Prompt.yn(yellow("Did this actually take #{human}"), default_response: true)
                unless res
                  new_elapsed = Prompt.enter_text('How long did it take?').chronify_qty
                  raise InvalidTimeExpression, 'Unrecognized time span entry' unless new_elapsed > 0

                  opt[:took] = new_elapsed
                  done_date = item.calculate_end_date(opt) if opt[:took]
                end
              end
            end

            if opt[:remove] || opt[:rename] || opt[:value]
              rename_to = nil
              if opt[:value]
                rename_to = tag
              elsif opt[:rename]
                rename_to = tag
                tag = opt[:rename]
              end
              old_title = item.title.dup
              force = opt[:value].nil? ? false : true
              item.title.tag!(tag, remove: opt[:remove], rename_to: rename_to, regex: opt[:regex], value: opt[:value], force: force)
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

        logger.log_change(tags_added: added, tags_removed: removed, item: item, single: items.count == 1)

        item.note.add(opt[:note]) if opt[:note]

        if opt[:archive] && opt[:section] != 'Archive' && (opt[:count]).positive?
          item.move_to('Archive', label: true)
        elsif opt[:archive] && opt[:count].zero?
          logger.warn('Skipped:', 'Archiving is skipped when operating on all entries')
        end

        item.expand_date_tags(@config['date_tags'])
        Hooks.trigger :post_entry_updated, self, item
      end

      write(@doing_file)
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
      options ||= {}
      items = filter_items(Items.new, opt: options)

      idx = items.index(item)

      idx.positive? ? items[idx - 1] : nil
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

      content = ["#{item.date.strftime('%F %R')} | #{item.title.dup}"]
      content << item.note.strip_lines.join("\n") unless item.note.empty?
      new_item = fork_editor(content.join("\n"))
      date, title, note = format_input(new_item)
      date ||= item.date

      if title.nil? || title.empty?
        logger.debug('Skipped:', 'No content provided')
      elsif title == item.title && note.equal?(item.note) && date.equal?(item.date)
        logger.debug('Skipped:', 'No change in content')
      else
        item.date = date unless date.nil?
        item.title = title
        item.note.add(note, replace: true)
        logger.info('Edited:', item.title)
        Hooks.trigger :post_entry_updated, self, item.dup

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
    ## @option opt :section [String] target section
    ## @option opt :archive [Boolean] archive old item
    ## @option opt :back [Date] backdate new item
    ## @option opt :new_item [String] content to use for new item
    ## @option opt :note [Array] note content for new item
    def stop_start(target_tag, opt)
      opt ||= {}
      tag = target_tag.dup
      opt[:section] ||= @config['current_section']
      opt[:archive] ||= false
      opt[:back] ||= Time.now
      opt[:new_item] ||= false
      opt[:note] ||= false

      opt[:section] = guess_section(opt[:section])

      tag.sub!(/^@/, '')

      found_items = 0

      @content.each_with_index do |item, i|
        next unless item.section == opt[:section] || opt[:section] =~ /all/i

        next unless item.title =~ /@#{tag}/

        item.title.add_tags!([tag, 'done'], remove: true)
        item.tag('done', value: opt[:back].strftime('%F %R'))

        found_items += 1

        if opt[:archive] && opt[:section] != 'Archive'
          item.title = item.title.sub(/(?:@from\(.*?\))?(.*)$/, "\\1 @from(#{item.section})")
          item.move_to('Archive', label: false, log: false)
          logger.count(:completed_archived)
          logger.info('Completed/archived:', item.title)
        else
          logger.count(:completed)
          logger.info('Completed:', item.title)
        end
        Hooks.trigger :post_entry_updated, self, item
      end


      logger.debug('Skipped:', "No active @#{tag} tasks found.") if found_items.zero?

      if opt[:new_item]
        date, title, note = format_input(opt[:new_item])
        opt[:back] = date unless date.nil?
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
    ## Rename doing file with date and start fresh one
    ##
    def rotate(opt)
      opt ||= {}
      keep = opt[:keep] || 0
      tags = []
      tags.concat(opt[:tag].split(/ *, */).map { |t| t.sub(/^@/, '').strip }) if opt[:tag]
      bool  = opt[:bool] || :and
      sect = opt[:section] !~ /^all$/i ? guess_section(opt[:section]) : 'all'

      section = guess_section(sect)

      section_items = @content.in_section(section)
      max = section_items.count - keep.to_i

      counter = 0
      new_content = Items.new

      section_items.each do |item|
        break if counter >= max
        if opt[:before]
          time_string = opt[:before]
          cutoff = time_string.chronify(guess: :begin)
        end

        unless ((!tags.empty? && !item.tags?(tags, bool)) || (opt[:search] && !item.search(opt[:search].to_s)) || (opt[:before] && item.date >= cutoff))
          new_item = @content.delete(item)
          Hooks.trigger :post_entry_removed, self, item.dup
          raise DoingRuntimeError, "Error deleting item: #{item}" if new_item.nil?

          new_content.add_section(new_item.section, log: false)
          new_content.push(new_item)
          counter += 1
        end
      end

      if counter.positive?
        logger.count(:rotated,
                     level: :info,
                     count: counter,
                     message: "Rotated %count %items")
      else
        logger.info('Skipped:', 'No items were rotated')
      end

      write(@doing_file)

      file = @doing_file.sub(/(\.\w+)$/, "_#{Time.now.strftime('%Y-%m-%d')}\\1")
      if File.exist?(file)
        init_doing_file(file)
        @content.concat(new_content).uniq!
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
    def choose_section(include_all: false)
      options = @content.section_titles.sort
      options.unshift('All') if include_all
      choice = Prompt.choose_from(options, prompt: 'Choose a section > ', fzf_args: ['--height=60%'])
      choice ? choice.strip : choice
    end

    ##
    ## Generate a menu of tags and allow user selection
    ##
    ## @return     [String] The selected tag name
    ##
    def choose_tag(section = 'All', items: nil, include_all: false)
      items ||= @content.in_section(section)
      tags = all_tags(items, counts: true).map { |t, c| "@#{t} (#{c})" }
      tags.unshift('No tag filter') if include_all
      choice = Prompt.choose_from(tags, sorted: false, multiple: true, prompt: 'Choose tag(s) > ', fzf_args: ['--height=60%'])
      choice ? choice.split(/\n/).map { |t| t.strip.sub(/ \(.*?\)$/, '')}.join(' ') : choice
    end

    ##
    ## Generate a menu of sections and tags and allow user selection
    ##
    ## @return     [String] The selected section or tag name
    ##
    def choose_section_tag
      options = @content.section_titles.sort
      options.concat(@content.all_tags.sort.map { |t| "@#{t}" })
      choice = Prompt.choose_from(options, prompt: 'Choose a section or tag > ', fzf_args: ['--height=60%'])
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
      choice = Prompt.choose_from(views.sort, prompt: 'Choose a view > ', fzf_args: ['--height=60%'])
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
    def list_section(opt, items: Items.new)
      opt[:config_template] ||= 'default'

      tpl_cfg = @config.dig('templates', opt[:config_template])

      cfg = if opt[:view_template]
              @config.dig('views', opt[:view_template]).deep_merge(tpl_cfg, { extend_existing_arrays: true, sort_merged_arrays: true })
            else
              tpl_cfg
            end

      cfg.deep_merge({
                       'wrap_width' => @config['wrap_width'] || 0,
                       'date_format' => @config['default_date_format'],
                       'order' => @config['order'] || 'asc',
                       'tags_color' => @config['tags_color'],
                       'duration' => @config['duration'],
                       'interval_format' => @config['interval_format']
                     }, { extend_existing_arrays: true, sort_merged_arrays: true })

      opt[:duration] ||= cfg['duration'] || false
      opt[:interval_format] ||= cfg['interval_format'] || 'text'
      opt[:count] ||= 0
      opt[:age] ||= :newest
      opt[:age] = opt[:age].normalize_age
      opt[:format] ||= cfg['date_format']
      opt[:order] ||= cfg['order'] || 'asc'
      opt[:tag_order] ||= 'asc'
      opt[:tags_color] = cfg['tags_color'] || false if opt[:tags_color].nil?
      opt[:template] ||= cfg['template']

      # opt[:highlight] ||= true
      title = ''
      is_single = true
      if opt[:section].nil?
        opt[:section] = choose_section
        title = opt[:section]
      elsif opt[:section].instance_of?(String)
        title = if opt[:section] =~ /^all$/i
                  if opt[:page_title]
                    opt[:page_title]
                  elsif opt[:tag_filter] && opt[:tag_filter]['bool'].normalize_bool != :not
                    opt[:tag_filter]['tags'].map { |tag| "@#{tag}" }.join(' + ')
                  else
                    'doing'
                  end
                else
                  guess_section(opt[:section])
                end
      end

      items = filter_items(items, opt: opt)

      items.reverse! unless opt[:order] =~ /^d/i

      if opt[:delete]
        delete_items(items, force: opt[:force])
        return
      elsif opt[:editor]
        edit_items(items)
        return
      elsif opt[:interactive]
        opt[:menu] = !opt[:force]
        opt[:query] = '' # opt[:search]
        opt[:multiple] = true
        selected = Prompt.choose_from_items(items.reverse, include_section: opt[:section] =~ /^all$/i, **opt)

        raise NoResults, 'no items selected' if selected.nil? || selected.empty?

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
    def archive(section = @config['current_section'], options)
      options ||= {}
      count       = options[:keep] || 0
      destination = options[:destination] || 'Archive'
      tags        = options[:tags] || []
      bool        = options[:bool] || :and

      section = choose_section if section.nil? || section =~ /choose/i
      archive_all = section =~ /^all$/i # && !(tags.nil? || tags.empty?)
      section = guess_section(section) unless archive_all

      @content.add_section(destination, log: true)
      # add_section(Section.new('Archive')) if destination =~ /^archive$/i && !@content.section?('Archive')

      destination = guess_section(destination)

      if @content.section?(destination) && (@content.section?(section) || archive_all)
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
    def today(times = true, output = nil, opt)
      opt ||= {}
      opt[:totals] ||= false
      opt[:sort_tags] ||= false

      cfg = @config['templates']['today'].deep_merge(@config['templates']['default'], { extend_existing_arrays: true, sort_merged_arrays: true }).deep_merge({
        'wrap_width' => @config['wrap_width'] || 0,
        'date_format' => @config['default_date_format'],
        'order' => @config['order'] || 'asc',
        'tags_color' => @config['tags_color'],
        'duration' => @config['duration'],
        'interval_format' => @config['interval_format']
      }, { extend_existing_arrays: true, sort_merged_arrays: true })

      opt[:duration] ||= cfg['duration'] || false
      opt[:interval_format] ||= cfg['interval_format'] || 'text'

      options = {
        after: opt[:after],
        before: opt[:before],
        count: 0,
        duration: opt[:duration],
        from: opt[:from],
        format: cfg['date_format'],
        interval_format: opt[:interval_format],
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
        config_template: opt[:config_template]
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
    def list_date(dates, section, times = nil, output = nil, opt)
      opt ||= {}
      opt[:totals] ||= false
      opt[:sort_tags] ||= false
      section = guess_section(section)
      # :date_filter expects an array with start and end date
      dates = dates.split_date_range if dates.instance_of?(String)

      list_section({
                     section: section,
                     count: 0,
                     order: 'asc',
                     date_filter: dates,
                     times: times,
                     output: output,
                     totals: opt[:totals],
                     duration: opt[:duration],
                     sort_tags: opt[:sort_tags],
                     config_template: opt[:config_template]
                   })
    end

    ##
    ## Show entries from the previous day
    ##
    ## @param      section  [String] The section
    ## @param      times    (Bool) Show times
    ## @param      output   [String] Output format
    ## @param      opt      [Hash] Additional Options
    ##
    def yesterday(section, times = nil, output = nil, opt)
      opt ||= {}
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
        duration: opt[:duration],
        from: opt[:from],
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
    def recent(count = 10, section = nil, opt)
      opt ||= {}
      times = opt[:t] || true
      opt[:totals] ||= false
      opt[:sort_tags] ||= false

      cfg = @config['templates'][opt[:config_template]].deep_merge(@config['templates']['default'], { extend_existing_arrays: true, sort_merged_arrays: true }).deep_merge({
        'wrap_width' => @config['wrap_width'] || 0,
        'date_format' => @config['default_date_format'],
        'order' => @config['order'] || 'asc',
        'tags_color' => @config['tags_color'],
        'duration' => @config['duration'],
        'interval_format' => @config['interval_format']
      }, { extend_existing_arrays: true, sort_merged_arrays: true })
      opt[:duration] ||= cfg['duration'] || false
      opt[:interval_format] ||= cfg['interval_format'] || 'text'

      section ||= @config['current_section']
      section = guess_section(section)

      opt[:section] = section
      opt[:wrap_width] = cfg['wrap_width']
      opt[:count] = count
      opt[:format] = cfg['date_format']
      opt[:template] = cfg['template']
      opt[:order] = 'asc'
      opt[:times] = times

      list_section(opt)
    end

    ##
    ## Show the last entry
    ##
    ## @param      times    (Bool) Show times
    ## @param      section  [String] Section to pull from, default Currently
    ##
    def last(times: true, section: nil, options: {})
      section = section.nil? || section =~ /all/i ? 'All' : guess_section(section)
      cfg = @config['templates']['last'].deep_merge(@config['templates']['default'], { extend_existing_arrays: true, sort_merged_arrays: true }).deep_merge({
        'wrap_width' => @config['wrap_width'] || 0,
        'date_format' => @config['default_date_format'],
        'order' => @config['order'] || 'asc',
        'tags_color' => @config['tags_color'],
        'duration' => @config['duration'],
        'interval_format' => @config['interval_format']
      }, { extend_existing_arrays: true, sort_merged_arrays: true })
      options[:duration] ||= cfg['duration'] || false
      options[:interval_format] ||= cfg['interval_format'] || 'text'

      opts = {
        section: section,
        wrap_width: cfg['wrap_width'],
        count: 1,
        format: cfg['date_format'],
        template: cfg['template'],
        times: times,
        duration: options[:duration],
        interval_format: options[:interval_format],
        case: options[:case],
        not: options[:negate],
        config_template: 'last',
        delete: options[:delete],
        val: options[:val]
      }

      if options[:tag]
        opts[:tag_filter] = {
          'tags' => options[:tag],
          'bool' => options[:tag_bool]
        }
      end

      opts[:search] = options[:search] if options[:search]

      list_section(opts)
    end

    ##
    ## Uses 'autotag' configuration to turn keywords into tags for time tracking.
    ## Does not repeat tags in a title, and only converts the first instance of an
    ## untagged keyword
    ##
    ## @param      string  [String] The text to tag
    ##
    def autotag(string)
      return unless string
      return string unless @auto_tag

      original = string.dup
      text = string.dup

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
          word = word.wildcard_to_rx
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

          if tag =~ /::/
            rx, r = tag.split(/::/)
          else
            rx, r = tag.split(/:/)
          end

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
        logger.debug('Autotag:', "no change to \"#{text.strip}\"")
      else
        new_tags = tagged[:whitelisted].concat(tail_tags).concat(tagged[:replaced])
        logger.debug('Autotag:', "added #{new_tags.log_tags} to \"#{text.strip}\"")
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
            output += "<tr><td style='text-align:left;'>#{k}</td><td style='text-align:left;'>#{v.time_string(format: :clock)}</td></tr>\n"
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
          <td style="text-align:left;">#{total.time_string(format: :clock)}</td>
        </tr>
        </tfoot>
        </table>
EOS
        output + tail
      when :markdown
        pad = sorted_tags_data.map {|k, v| k }.group_by(&:size).max.last[0].length
        pad = 7 if pad < 7
        output = <<~EOS
  | #{' ' * (pad - 7) }project | time     |
  | #{'-' * (pad - 1)}: | :------- |
        EOS
        sorted_tags_data.reverse.each do |k, v|
          if v > 0
            output += "| #{' ' * (pad - k.length)}#{k} | #{v.time_string(format: :clock)} |\n"
          end
        end
        tail = "[Tag Totals]"
        output + tail
      when :json
        output = []
        sorted_tags_data.reverse.each do |k, v|
          output << {
            'tag' => k,
            'seconds' => v,
            'formatted' => v.time_string(format: :clock)
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
          output.push("┃ #{spacer}#{k}:#{v.time_string(format: :hm)} ┃")
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
        output += "\n#{divider}"
        spacer = ''
        (max - 6).times do
          spacer += ' '
        end
        total_time = total.time_string(format: :hm)
        total = "┃ #{spacer}total: "
        total += total_time
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
          output.push("#{k}:#{spacer}#{v.time_string(format: :clock)}")
        end

        output = output.empty? ? '' : "\n--- Tag Totals ---\n#{output.join("\n")}"
        output += "\n\nTotal tracked: #{total.time_string(format: :clock)}\n"
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

        return seconds.positive? ? seconds.time_string(format: :clock) : false
      end

      false
    end

    ##
    ## Load configuration files and updated the @config
    ## attribute with a Doing::Configuration object
    ##
    ## @param      filename  [String] (optional) path to
    ##                       alternative config file
    ##
    def configure(filename = nil)
      if filename
        Doing.config_with(filename, { ignore_local: true })
      elsif ENV['DOING_CONFIG']
        Doing.config_with(ENV['DOING_CONFIG'], { ignore_local: true })
      end

      Doing.logger.benchmark(:configure, :start)
      config = Doing.config
      Doing.logger.benchmark(:configure, :finish)

      config.settings['backup_dir'] = ENV['DOING_BACKUP_DIR'] if ENV['DOING_BACKUP_DIR']
      @config = config.settings
    end

    def get_diff(filename = nil)
      configure if @config.nil?

      filename ||= @config['doing_file']
      init_doing_file(filename)
      current_content = @content.dup
      backup_file = Util::Backup.last_backup(filename, count: 1)
      raise DoingRuntimeError, 'No undo history to diff' if backup_file.nil?

      backup = WWID.new
      backup.config = @config
      backup.init_doing_file(backup_file)
      current_content.diff(backup.content)
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
      was_color = Color.coloring?
      Color.coloring = false
      output += @content.to_s
      output += @other_content_bottom.join("\n") unless @other_content_bottom.nil?
      # Just strip all ANSI colors from the content before writing to doing file
      Color.coloring = was_color

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
    def output(items, title, is_single, opt)
      opt ||= {}
      out = nil

      raise InvalidArgument, 'Unknown output format' unless opt[:output] =~ Plugins.plugin_regex(type: :export)

      export_options = { page_title: title, is_single: is_single, options: opt }

      Hooks.trigger :pre_export, self, opt[:output], items

      Plugins.plugins[:export].each do |_, options|
        next unless opt[:output] =~ /^(#{options[:trigger].normalize_trigger})$/i

        out = options[:class].render(self, items, variables: export_options)
        break
      end

      logger.debug('Output:', "#{items.count} #{items.count == 1 ? 'item' : 'items'} shown")

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
    ## @param      section      [String] The source section
    ## @param      destination  [String] The destination
    ##                          section
    ## @param      opt          [Hash] Additional Options
    ##
    def do_archive(section, destination, opt)
      opt ||= {}
      count = opt[:count] || 0
      tags  = opt[:tags] || []
      bool  = opt[:bool] || :and
      label = opt[:label] || true

      section = guess_section(section)
      destination = guess_section(destination)

      section_items = @content.in_section(section)
      max = section_items.count - count.to_i

      counter = 0

      @content.map do |item|
        break if counter >= max
        if opt[:before]
          time_string = opt[:before]
          cutoff = time_string.chronify(guess: :begin)
        end

        if (item.section.downcase != section.downcase && section != /^all$/i) || item.section.downcase == destination.downcase
          item
        elsif ((!tags.empty? && !item.tags?(tags, bool)) || (opt[:search] && !item.search(opt[:search].to_s)) || (opt[:before] && item.date >= cutoff))
          item
        else
          counter += 1
          item.move_to(destination, label: label, log: false)
          Hooks.trigger :post_entry_updated, self, item.dup
          item
        end
      end

      if counter.positive?
        logger.count(destination == 'Archive' ? :archived : :moved,
                     level: :info,
                     count: counter,
                     message: "%count %items from #{section} to #{destination}")
      else
        logger.info('Skipped:', 'No items were moved')
      end
    end

    def run_after
      return unless @config.key?('run_after')

      _, stderr, status = Open3.capture3(@config['run_after'])
      return unless status.exitstatus.positive?

      logger.log_now(:error, 'Script error:', "Error running #{@config['run_after']}")
      logger.log_now(:error, 'STDERR output:', stderr)
    end
  end
end
