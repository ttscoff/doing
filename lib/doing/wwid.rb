#!/usr/bin/ruby
# frozen_string_literal: true

require 'deep_merge'
require 'open3'
require 'pp'
require 'shellwords'
require 'erb'

module Doing
  ##
  ## @brief      Main "What Was I Doing" methods
  ##
  class WWID
    attr_reader   :additional_configs, :current_section, :doing_file, :content

    attr_accessor :config, :user_home, :config_file, :auto_tag, :default_option

    # include Util

    ##
    ## @brief      Initializes the object.
    ##
    def initialize
      @timers = {}
      @recorded_items = []
      @content = {}
      @doingrc_needs_update = false
      @default_config_file = '.doingrc'
      @auto_tag = true
    end

    ##
    ## @brief      Logger
    ##
    ## Responds to :debug, :info, :warn, and :error
    ##
    ## Each method takes a topic, and a message or block
    ##
    ## Example: debug('Hooks', 'Hook 1 triggered')
    ##
    def logger
      @log ||= Doing.logger
    end

    ##
    ## @brief      Finds a project-specific configuration file
    ##
    ## @return     (String) A file path
    ##
    def find_local_config
      dir = Dir.pwd

      local_config_files = []

      while dir != '/' && (dir =~ %r{[A-Z]:/}).nil?
        local_config_files.push(File.join(dir, @default_config_file)) if File.exist? File.join(dir, @default_config_file)

        dir = File.dirname(dir)
      end

      local_config_files
    end

    ##
    ## @brief      Reads a configuration.
    ##
    def read_config(opt = {})
      @config_file ||= if Dir.respond_to?('home')
                         File.join(Dir.home, @default_config_file)
                       else
                         File.join(File.expand_path('~'), @default_config_file)
                       end

      @additional_configs = if opt[:ignore_local]
                             []
                           else
                             find_local_config
                           end

      begin
        @local_config = {}

        @config = YAML.load_file(@config_file) || {} if File.exist?(@config_file)
        @additional_configs.each do |cfg|
          new_config = YAML.load_file(cfg) || {} if cfg
          @local_config = @local_config.deep_merge(new_config)
        end

        # @config.deep_merge(@local_config)
      rescue StandardError
        @config = {}
        @local_config = {}
        # exit_now! "error reading config"
      end

      @additional_configs.delete(@config_file)

      if @additional_configs && @additional_configs.count.positive?
        logger.debug('Configuration:', "Local config files found: #{@additional_configs.map { |p| p.sub(/^#{@user_home}/, '~') }.join(', ')}")
      end
    end

    ##
    ## @brief      Read user configuration and merge with defaults
    ##
    ## @param      opt   (Hash) Additional Options
    ##
    def configure(opt = {})
      opt[:ignore_local] ||= false

      @config_file ||= File.join(@user_home, @default_config_file)

      read_config({ ignore_local: opt[:ignore_local] })

      @config = {} if @config.nil?

      @config['autotag'] ||= {}
      @config['autotag']['whitelist'] ||= []
      @config['autotag']['synonyms'] ||= {}
      @config['doing_file'] ||= '~/what_was_i_doing.md'
      @config['current_section'] ||= 'Currently'
      @config['config_editor_app'] ||= nil
      @config['editor_app'] ||= nil

      @config['templates'] ||= {}
      @config['templates']['default'] ||= {
        'date_format' => '%Y-%m-%d %H:%M',
        'template' => '%date | %title%note',
        'wrap_width' => 0
      }
      @config['templates']['today'] ||= {
        'date_format' => '%_I:%M%P',
        'template' => '%date: %title %interval%note',
        'wrap_width' => 0
      }
      @config['templates']['last'] ||= {
        'date_format' => '%-I:%M%P on %a',
        'template' => '%title (at %date)%odnote',
        'wrap_width' => 88
      }
      @config['templates']['recent'] ||= {
        'date_format' => '%_I:%M%P',
        'template' => '%shortdate: %title (%section)',
        'wrap_width' => 88,
        'count' => 10
      }

      @config['export_templates'] ||= {}

      if @config.key?('html_template')
        @config['export_templates'].deep_merge(@config['html_template'])
        @config.delete('html_template')
      else
        @config['export_templates'] ||= {}
      end

      @config['views'] ||= {
        'done' => {
          'date_format' => '%_I:%M%P',
          'template' => '%date | %title%note',
          'wrap_width' => 0,
          'section' => 'All',
          'count' => 0,
          'order' => 'desc',
          'tags' => 'done complete cancelled',
          'tags_bool' => 'OR'
        },
        'color' => {
          'date_format' => '%F %_I:%M%P',
          'template' => '%boldblack%date %boldgreen| %boldwhite%title%default%note',
          'wrap_width' => 0,
          'section' => 'Currently',
          'count' => 10,
          'order' => 'asc'
        }
      }
      @config['marker_tag'] ||= 'flagged'
      @config['marker_color'] ||= 'red'
      @config['default_tags'] ||= []
      @config['tag_sort'] ||= 'name'

      @current_section = config['current_section']
      @default_template = config['templates']['default']['template']
      @default_date_format = config['templates']['default']['date_format']

      @config[:include_notes] ||= true

      # if ENV['DOING_DEBUG'].to_i == 3
      #   if @config['default_tags'].length > 0
      #     exit_now! "DEFAULT CONFIG CHANGED"
      #   end
      # end

      plugin_config = { 'plugin_path' => nil }

      load_plugins

      Plugins.plugins.each do |_type, plugins|
        plugins.each do |title, plugin|
          plugin_config[title] = plugin[:config] if plugin.key?(:config) && !plugin[:config].empty?
          @config['export_templates'][title] ||= nil if plugin.key?(:templates)
        end
      end

      @config.deep_merge({ 'plugins' => plugin_config })

      write_config if !File.exist?(@config_file) || opt[:rewrite]

      Hooks.trigger :post_config, self

      @config.deep_merge(@local_config)

      Hooks.trigger :post_local_config, self

      @current_section = @config['current_section']
      @default_template = @config['templates']['default']['template']
      @default_date_format = @config['templates']['default']['date_format']

    end

    ##
    ## @brief      Write current configuration to file
    ##
    ## @param      file    The file
    ## @param      backup  The backup
    ##
    def write_config(file = nil, backup: false)
      file ||= @config_file
      write_to_file(file, YAML.dump(@config), backup: backup)
    end

    ##
    ## @brief      Initializes the doing file.
    ##
    ## @param      path  (String) Override path to a doing file, optional
    ##
    def init_doing_file(path = nil)
      @doing_file = File.expand_path(@config['doing_file'])

      input = path

      if input.nil?
        create(@doing_file) unless File.exist?(@doing_file)
        input = IO.read(@doing_file)
        input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
      elsif File.exist?(File.expand_path(input)) && File.file?(File.expand_path(input)) && File.stat(File.expand_path(input)).size.positive?
        @doing_file = File.expand_path(input)
        input = IO.read(File.expand_path(input))
        input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
      elsif input.length < 256
        @doing_file = File.expand_path(input)
        create(input)
        input = IO.read(File.expand_path(input))
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
    ## @brief      Create a new doing file
    ##
    def create(filename = nil)
      filename = @doing_file if filename.nil?
      return if File.exist?(filename) && File.stat(filename).size.positive?

      File.open(filename, 'w+') do |f|
        f.puts "#{@current_section}:"
      end
    end

    ##
    ## @brief      Create a process for an editor and wait for the file handle to return
    ##
    ## @param      input  (String) Text input for editor
    ##
    def fork_editor(input = '')
      tmpfile = Tempfile.new(['doing', '.md'])

      File.open(tmpfile.path, 'w+') do |f|
        f.puts input
        f.puts "\n# The first line is the entry title, any lines after that are added as a note"
      end

      pid = Process.fork { system("$EDITOR #{tmpfile.path}") }

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
    ## @brief      Takes a multi-line string and formats it as an entry
    ##
    ## @return     (Array) [(String)title, (Array)note]
    ##
    ## @param      input  (String) The string to parse
    ##
    ## @return     (Array) [(String)title, (Note)note]
    ##
    def format_input(input)
      raise Errors::EmptyInput, 'No content in entry' if input.nil? || input.strip.empty?

      input_lines = input.split(/[\n\r]+/).delete_if(&:ignore?)
      title = input_lines[0]&.strip
      raise Errors::EmptyInput, 'No content in first line' if title.nil? || title.strip.empty?

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
    ## @brief      Converts input string into a Time object when input takes on the
    ##             following formats:
    ##             - interval format e.g. '1d2h30m', '45m' etc.
    ##             - a semantic phrase e.g. 'yesterday 5:30pm'
    ##             - a strftime e.g. '2016-03-15 15:32:04 PDT'
    ##
    ## @param      input  (String) String to chronify
    ##
    ## @return     (DateTime) result
    ##
    def chronify(input, future: false, guess: :begin)
      now = Time.now
      raise Errors::InvalidTimeExpression, "Invalid time expression #{input.inspect}" if input.to_s.strip == ''

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
    ## @brief      Converts simple strings into seconds that can be added to a Time
    ##             object
    ##
    ## @param      qty   (String) HH:MM or XX[dhm][[XXhm][XXm]] (1d2h30m, 45m,
    ##                   1.5d, 1h20m, etc.)
    ##
    ## @return     (Integer) seconds
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
    ## @brief      List sections
    ##
    ## @return     (Array) section titles
    ##
    def sections
      @content.keys
    end

    ##
    ## @brief      Adds a section.
    ##
    ## @param      title  (String) The new section title
    ##
    def add_section(title)
      if @content.key?(title.cap_first)
        logger.debug('Skipped': 'Section already exists')
        return
      end

      @content[title.cap_first] = { :original => "#{title}:", :items => [] }
      logger.info('Added section:', %("#{title.cap_first}"))
    end

    ##
    ## @brief      Attempt to match a string with an existing section
    ##
    ## @param      frag     (String) The user-provided string
    ## @param      guessed  (Boolean) already guessed and failed
    ##
    def guess_section(frag, guessed: false, suggest: false)
      return 'All' if frag =~ /^all$/i
      frag ||= @current_section

      sections.each { |sect| return sect.cap_first if frag.downcase == sect.downcase }
      section = false
      re = frag.split('').join('.*?')
      sections.each do |sect|
        next unless sect =~ /#{re}/i

        logger.debug('Section match:', %(Assuming "#{sect}" from "#{frag}"))
        section = sect
        break
      end

      return section if suggest

      unless section || guessed
        alt = guess_view(frag, guessed: true, suggest: true)
        if alt
          meant_view = yn("Did you mean `doing view #{alt}`?", default_response: 'n')
          raise Errors::InvalidSection, "Run again with `doing view #{alt}`" if meant_view
        end

        res = yn("Section #{frag} not found, create it", default_response: 'n')

        if res
          add_section(frag.cap_first)
          write(@doing_file)
          return frag.cap_first
        end

        raise Errors::InvalidSection, "Unknown section: #{frag}"
      end
      section ? section.cap_first : guessed
    end

    ##
    ## @brief      Ask a yes or no question in the terminal
    ##
    ## @param      question     (String) The question to ask
    ## @param      default      (Bool)   default response if no input
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
    ## @brief      Attempt to match a string with an existing view
    ##
    ## @param      frag     (String) The user-provided string
    ## @param      guessed  (Boolean) already guessed
    ##
    def guess_view(frag, guessed: false, suggest: false)
      views.each { |view| return view if frag.downcase == view.downcase }
      view = false
      re = frag.split('').join('.*?')
      views.each do |v|
        next unless v =~ /#{re}/i

        logger.debug('View match:', %(Assuming "#{v}" from "#{frag}"))
        view = v
        break
      end
      unless view || guessed
        guess = guess_section(frag, guessed: true, suggest: true)
        exit_now! "Did you mean `doing show #{guess}`?" if guess

        raise Errors::InvalidView, "Unknown view: #{frag}"

      end
      view
    end

    ##
    ## @brief      Adds an entry
    ##
    ## @param      title    (String) The entry title
    ## @param      section  (String) The section to add to
    ## @param      opt      (Hash) Additional Options {:date, :note, :back, :timed}
    ##
    def add_item(title, section = nil, opt = {})
      section ||= @current_section
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

      logger.info('Entry added:', %("#{entry.title}" to #{section}))
    end

    def same_time?(item_a, item_b)
      item_a.date == item_b.date ? item_a.interval == item_b.interval : false
    end

    def overlapping_time?(item_a, item_b)
      return true if same_time?(item_a, item_b)

      start_a = item_a.date
      interval = item_a.interval
      end_a = interval ? start_a + interval.to_i : start_a
      start_b = item_b.date
      interval = item_b.interval
      end_b = interval ? start_b + interval.to_i : start_b
      (start_a >= start_b && start_a <= end_b) || (end_a >= start_b && end_a <= end_b) || (start_a < start_b && end_a > end_b)
    end

    ##
    ## @brief      Remove items from a list that already exist in @content
    ##
    ## @param      items       (Array) The items to deduplicate
    ## @param      no_overlap  (Boolean) Remove items with overlapping time spans
    ##
    def dedup(items, no_overlap = false)

      combined = []
      @content.each do |_k, v|
        combined += v[:items]
      end

      items.delete_if do |item|
        duped = false
        combined.each do |comp|
          duped = no_overlap ? overlapping_time?(item, comp) : same_time?(item, comp)
          break if duped
        end
        logger.log_now(:debug, 'Skipped:', "overlapping entry: #{item.title}") if duped
        duped
      end
    end

    ##
    ## @brief      Imports external entries
    ##
    ## @param      path     (String) Path to JSON report file
    ## @param      opt      (Hash) Additional Options
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
    ## @brief      Return the content of the last note for a given section
    ##
    ## @param      section  (String) The section to retrieve from, default
    ##                      All
    ##
    def last_note(section = 'All')
      section = guess_section(section)

      if section =~ /^all$/i
        combined = { :items => [] }
        @content.each do |_k, v|
          combined[:items] += v[:items]
        end
        section = combined[:items].dup.sort_by { |item| item.date }.reverse[0].section
      end

      raise Errors::InvalidSection, "Section #{section} not found" unless @content.key?(section)

      last_item = @content[section][:items].dup.sort_by(&:date).reverse[0]
      raise Errors::NoEntryError, 'No entry found' unless last_item

      logger.log_now(:info, 'Editing note:', last_item.title)
      note = ''
      note = last_item.note.to_s unless last_item.note.nil?
      "#{last_item.title}\n# EDIT BELOW THIS LINE ------------\n#{note}"
    end

    ##
    ## @brief      Restart the last entry
    ##
    ## @param      opt   (Hash) Additional Options
    ##
    def restart_last(opt = {})
      opt[:section] ||= 'all'
      opt[:note] ||= []
      opt[:tag] ||= []
      opt[:tag_bool] ||= :and

      last = last_entry(opt)
      if last.nil?
        logger.debug('Skipped:', 'No previous entry found')
        return
      end

      last.title.tag!('done', value: Time.now.strftime('%F %R'))

      # Remove @done tag
      title = last.title.sub(/\s*@done(\(.*?\))?/, '').chomp
      section = opt[:in].nil? ? last.section : guess_section(opt[:in])
      @auto_tag = false

      note = opt[:note]

      if opt[:editor]
        to_edit = title
        to_edit += "\n#{note.to_s}" unless note.empty?
        new_item = fork_editor(to_edit)
        title, note = format_input(new_item)

        if title.nil? || title.empty?
          logger.debug('Skipped:', 'No content provided')
          return
        end
      end

      add_item(title, section, { note: note, back: opt[:date], timed: true })
      write(@doing_file)
    end

    ##
    ## @brief      Get the last entry
    ##
    ## @param      opt   (Hash) Additional Options
    ##
    def last_entry(opt = {})
      opt[:tag_bool] ||= :and
      opt[:section] ||= @current_section

      all_items = filter_items([], opt: opt)

      logger.debug('Filtered:', "Parameters matched #{all_items.count} entries")

      all_items.max_by { |item| item.date }
    end

    ##
    ## @brief      Generate a menu of options and allow user selection
    ##
    ## @return     (String) The selected option
    ##
    def choose_from(options, prompt: 'Make a selection: ', multiple: false, sorted: true, fzf_args: [])
      fzf = File.join(File.dirname(__FILE__), '../helpers/fuzzyfilefinder')
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

    ##
    ## @brief      Filter items based on search criteria
    ##
    ## @param      items  (Array) The items to filter (if empty, filters all items)
    ## @param      opt    (Hash) The filter parameters
    ##
    ## Available filter options in opt object
    ##
    ## - +:section+ (String)
    ## - +:unfinished+ (Boolean)
    ## - +:tag+ (Array or comma-separated string)
    ## - +:tag_bool+ (:and, :or, :not)
    ## - +:search+ (string, optional regex with //)
    ## - +:date_filter+ (Array[(Time)start, (Time)end])
    ## - +:only_timed+ (Boolean)
    ## - +:before+ (Date/Time string, unparsed)
    ## - +:after+ (Date/Time string, unparsed)
    ## - +:today+ (Boolean)
    ## - +:yesterday+ (Boolean)
    ## - +:count+ (Number to return)
    ## - +:age+ (String, 'old' or 'new')
    ##
    def filter_items(items = [], opt: {})
      if items.empty?
        section = opt[:section] ? guess_section(opt[:section]) : 'All'

        if section =~ /^all$/i
          combined = { :items => [] }
          @content.each do |_k, v|
            combined[:items] += v[:items]
          end
          items = combined[:items].dup
        else
          items = @content[section][:items].dup
        end
      end

      items.sort_by! { |item| item.date }.reverse
      filtered_items = items.select do |item|
        keep = true
        finished = opt[:unfinished] && item.tags?('done', :and)
        keep = false if finished

        if keep && opt[:tag]
          tag_match = opt[:tag].nil? || opt[:tag].empty? ? true : item.tags?(opt[:tag], opt[:tag_bool])
          keep = false unless tag_match
        end

        if keep && opt[:search]
          search_match = opt[:search].nil? || opt[:search].empty? ? true : item.search(opt[:search])
          keep = false unless search_match
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
        end

        if keep && opt[:only_timed]
          keep = false unless item.interval
        end

        if keep && opt[:tag_filter] && !opt[:tag_filter]['tags'].empty?
          filter_match = item.tags?(opt[:tag_filter]['tags'], opt[:tag_filter]['bool'])
          keep = false unless filter_match
        end

        if keep && opt[:before]
          time_string = opt[:before]
          cutoff = chronify(time_string, guess: :begin)
          if cutoff
            keep = false if item.date >= cutoff
          end
        end

        if keep && opt[:after]
          time_string = opt[:after]
          cutoff = chronify(time_string, guess: :end)
          if cutoff
            keep = false if item.date <= cutoff
          end
        end

        if keep && opt[:today]
          keep = false if item.date < Date.today.to_time
        elsif keep && opt[:yesterday]
          keep = false if item.date <= Date.today.prev_day.to_time || item.date >= Date.today.to_time
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
    ## @brief      Display an interactive menu of entries
    ##
    ## @param      opt   (Hash) Additional options
    ##
    def interactive(opt = {})
      section = opt[:section] ? guess_section(opt[:section]) : 'All'
      opt[:query] = opt[:search] if opt[:search] && !opt[:query]

      if section =~ /^all$/i
        combined = { :items => [] }
        @content.each do |_k, v|
          combined[:items] += v[:items]
        end
        items = combined[:items].dup.sort_by { |item| item.date }.reverse
      else
        items = @content[section][:items]
      end

      selection = choose_from_items(items, opt, include_section: section =~ /^all$/i)

      if selection.empty?
        logger.debug('Skipped:', 'No selection')
        return
      end

      act_on(selection, opt)
    end

    def choose_from_items(items, opt = {}, include_section: false)
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

      fzf = File.join(File.dirname(__FILE__), '../helpers/fuzzyfilefinder')
      fzf_args = [
        %(--header="Arrows: navigate, tab: mark for selection, ctrl-a: select all, enter: commit"),
        %(--prompt="Select entries to act on > "),
        '-1',
        '-m',
        '--bind ctrl-a:select-all',
        %(-q "#{opt[:query]}")
      ]
      if !opt[:menu]
        raise Errors::InvalidArgument, "Can't skip menu when no query is provided" unless opt[:query]

        fzf_args.concat([%(--filter="#{opt[:query]}"), '--no-sort'])
      end

      res = `echo #{Shellwords.escape(options.join("\n"))}|#{fzf} #{fzf_args.join(' ')}`
      selected = []
      res.split(/\n/).each do |item|
        idx = item.match(/^ *(\d+)\)/)[1].to_i
        selected.push(items[idx])
      end

      selected
    end

    def act_on(items, opt = {})
      actions = %i[editor delete tag flag finish cancel tag archive output save_to]
      has_action = false
      actions.each do |a|
        if opt[a]
          has_action = true
          break
        end
      end

      unless has_action
        choice = choose_from([
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
                             ],
                             prompt: 'What do you want to do with the selected items? > ',
                             multiple: true,
                             sorted: false,
                             fzf_args: ['--height=60%', '--tac', '--no-sort'])
        return unless choice

        to_do = choice.strip.split(/\n/)
        to_do.each do |action|
          case action
          when /(add|remove) tag/
            type = action =~ /^add/ ? 'add' : 'remove'
            raise Errors::InvalidArgument, "'add tag' and 'remove tag' can not be used together" if opt[:tag]

            print "#{Color.yellow}Tag to #{type}: #{Color.reset}"
            tag = $stdin.gets
            next if tag =~ /^ *$/

            opt[:tag] = tag.strip.sub(/^@/, '')
            opt[:remove] = true if type == 'remove'
          when /output formatted/
            output_format = choose_from(available_plugins.sort,
                                        prompt: 'Which output format? > ',
                                        fzf_args: ['--height=60%', '--tac', '--no-sort'])
            next if tag =~ /^ *$/

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

      if opt[:delete]
        res = opt[:force] ? true : yn("Delete #{items.size} items?", default_response: 'y')
        if res
          items.each { |item| delete_item(item) }
          write(@doing_file)
        end
        return
      end

      if opt[:flag]
        tag = @config['marker_tag'] || 'flagged'
        items.map! do |item|
          tag_item(item, tag, date: false, remove: opt[:remove])
        end
      end

      if opt[:finish] || opt[:cancel]
        tag = 'done'
        items.map! do |item|
          tag_item(item, tag, date: !opt[:cancel], remove: opt[:remove])
        end
      end

      if opt[:tag]
        tag = opt[:tag]
        items.map! do |item|
          tag_item(item, tag, date: false, remove: opt[:remove])
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
            delete_item(items[i])
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

          logger.info('File written:', file)
        else
          puts output
        end
      end
    end

    ##
    ## @brief      Tag the last entry or X entries
    ##
    ## @param      opt   (Hash) Additional Options
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

      items.each do |item|
        if opt[:autotag]
          new_title = autotag(item.title) if @auto_tag
          if new_title == item.title
            logger.debug('Autotag:', 'No changes')
          else
            logger.info('Tags updated:', new_title)
            item.title = new_title
          end
        else
          if opt[:sequential]
            next_entry = next_item(item)

            if next_entry.nil?
              done_date = Time.now
            else
              done_date = next_entry.date - 60
            end
          elsif opt[:took]
            if item.date + opt[:took] > Time.now
              item.date = Time.now - opt[:took]
              done_date = Time.now
            else
              done_date = item.date + opt[:took]
            end
          elsif opt[:back]
            if opt[:back].is_a? Integer
              done_date = item.date + opt[:back]
            else
              done_date = item.date + (opt[:back] - item.date)
            end
          else
            done_date = Time.now
          end

          opt[:tags].each do |tag|
            tag = tag.strip
            if opt[:remove] || opt[:rename]
              rename_to = nil
              if opt[:rename]
                rename_to = tag
                tag = opt[:rename]
              end

              item.title.tag!(tag, remove: opt[:remove], rename_to: rename_to, regex: opt[:regex])
            else
              item.title.tag!(tag, value: opt[:date] ? done_date.strftime('%F %R') : nil)
            end
          end
        end

        if opt[:note]
          item.note.add(opt[:note])
        end

        if opt[:archive] && opt[:section] != 'Archive' && (opt[:count]).positive?
          move_item(item, 'Archive', label: true)
        else
          logger.warn('Archiving is skipped when operating on all entries') if opt[:archive] && opt[:count].zero?
        end
      end

      write(@doing_file)
    end

    ##
    ## @brief      Move item from current section to
    ##             destination section
    ##
    ## @param      item     The item
    ## @param      section  The destination section
    ##
    ## @return     Updated item
    ##
    def move_item(item, section, label: true)
      from = item.section
      new_item = @content[item.section][:items].delete(item)
      new_item.title.sub!(/(?:@from\(.*?\))?(.*)$/, "\\1 @from(#{from})") if label
      new_item.section = section

      @content[section][:items].concat([new_item])

      logger.info("Entry #{section == 'Archive' ? 'archived' : 'moved'}:", "#{new_item.title.truncate(60)} from #{from} to #{section}")
      new_item
    end

    ##
    ## @brief      Get next item in the index
    ##
    ## @param      item
    ##
    def next_item(item)
      combined = { :items => [] }
      @content.each do |_k, v|
        combined[:items] += v[:items]
      end
      items = combined[:items].dup.sort_by { |item| item.date }.reverse
      idx = items.index(item)

      if idx > 0
        items[idx - 1]
      else
        nil
      end
    end

    ##
    ## @brief      Delete an item from the index
    ##
    ## @param      item  The item
    ##
    def delete_item(item)
      section = item.section

      section_items = @content[section][:items]
      deleted = section_items.delete(item)
      logger.info('Entry deleted:', deleted.title)
    end

    ##
    ## @brief      Tag an item from the index
    ##
    ## @param      item    (Item) The item to tag
    ## @param      tags    (string) The tag to apply
    ## @param      remove  (Boolean) remove tags
    ## @param      date    (Boolean) Include timestamp?
    ##
    def tag_item(item, tags, remove: false, date: false)
      added = []
      removed = []

      tags = tags.to_tags if tags.is_a? ::String

      done_date = Time.now

      tags.each do |tag|
        bool = remove ? :and : :not
        if item.tags?(tag, bool)
          item.tag(tag, remove: remove, value: date ? done_date.strftime('%F %R') : nil)
          remove ? removed.push(tag) : added.push(tag)
        else
          logger.debug('Skipped:', %(Item #{remove ? 'not' : 'already' } @#{tag}: "#{title}" in #{item.section}))
        end
      end

      if added.empty?
        logger.debug('No tags added:', %("#{item.title}" in #{item.section}))
      else
        did_add = added.map { |t| "@#{tag}".cyan }.join(', ')
        logger.info('Added tags:', %(#{added} to "#{item.title}" in #{item.section}))
      end

      if removed.empty?
        logger.debug('No tags removed:', %("#{item.title}" in #{item.section}))
      else
        did_remove = removed.map { |t| "@#{tag}".cyan }.join(', ')
        logger.info('Removed tags:', %(#{added} from "#{item.title}" in #{item.section}))
      end

      item
    end

    ##
    ## @brief      Update an item in the index with a modified item
    ##
    ## @param      old_item  The old item
    ## @param      new_item  The new item
    ##
    def update_item(old_item, new_item)
      section = old_item.section

      section_items = @content[section][:items]
      s_idx = section_items.index {|item|
        item.equal?(old_item)
      }

      unless s_idx
        Doing.logger.error('Fail to update:', 'Could not find item in index')
        raise Errors::ItemNotFound, 'Unable to find item in index, did it mutate?'
      end

      return if section_items[s_idx].equal?(new_item)

      section_items[s_idx] = new_item
      logger.info('Entry updated:', section_items[s_idx].title.truncate(60))
      new_item
    end

    ##
    ## @brief      Edit the last entry
    ##
    ## @param      section  (String) The section, default "All"
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
        logger.info('Entry edited:', item.title)

        write(@doing_file)
      end
    end

    ##
    ## @brief      Accepts one tag and the raw text of a new item if the passed tag
    ##             is on any item, it's replaced with @done. if new_item is not
    ##             nil, it's tagged with the passed tag and inserted. This is for
    ##             use where only one instance of a given tag should exist
    ##             (@meanwhile)
    ##
    ## @param      tag   (String) Tag to replace
    ## @param      opt   (Hash) Additional Options
    ##
    def stop_start(target_tag, opt = {})
      tag = target_tag.dup
      opt[:section] ||= @current_section
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
          logger.info('Completed/archived:', item.title)
        else
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
    ## @brief      Write content to file or STDOUT
    ##
    ## @param      file  (String) The filepath to write to
    ##
    def write(file = nil, backup: true)
      output = wrapped_content

      if file.nil?
        $stdout.puts output
      else
        write_to_file(file, output, backup: backup)
        run_after if @config.key?('run_after')
      end
    end

    def wrapped_content
      output = @other_content_top ? "#{@other_content_top.join("\n")}\n" : ''

      @content.each do |title, section|
        output += "#{section[:original]}\n"
        output += list_section({ section: title, template: "\t- %date | %title%t2note", highlight: false, wrap_width: 0 })
      end

      output + @other_content_bottom.join("\n") unless @other_content_bottom.nil?
    end

    ##
    ## @brief      Write content to a file
    ##
    ## @param      file     (String) The path to the file to (over)write
    ## @param      content  (String) The content to write to the file
    ## @param      backup   (Boolean) create a ~ backup
    ##
    def write_to_file(file, content, backup: true)
      file = File.expand_path(file)

      if File.exist?(file) && backup
        # Create a backup copy for the undo command
        FileUtils.cp(file, "#{file}~")
      end

      File.open(file, 'w+') do |f|
        f.puts content
      end

      Hooks.trigger :post_write, file
    end

    ##
    ## @brief      Restore a backed up version of a file
    ##
    ## @param      file  (String) The filepath to restore
    ##
    def restore_backup(file)
      if File.exist?("#{file}~")
        FileUtils.cp("#{file}~", file)
        logger.warn('File update:', "Restored #{file}")
      else
        logger.error('Restore error:', 'No backup file found')
      end
    end

    ##
    ## @brief      Rename doing file with date and start fresh one
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
        logger.warn('File update:', "Added entries to existing file: #{file}")
      else
        @content = new_content
        logger.warn('File update:', "Created new file: #{file}")
      end

      write(file, backup: false)
    end

    ##
    ## @brief      Generate a menu of sections and allow user selection
    ##
    ## @return     (String) The selected section name
    ##
    def choose_section
      choice = choose_from(sections.sort, prompt: 'Choose a section > ', fzf_args: ['--height=60%'])
      choice ? choice.strip : choice
    end

    ##
    ## @brief      List available views
    ##
    ## @return     (Array) View names
    ##
    def views
      @config.has_key?('views') ? @config['views'].keys : []
    end

    ##
    ## @brief      Generate a menu of views and allow user selection
    ##
    ## @return     (String) The selected view name
    ##
    def choose_view
      choice = choose_from(views.sort, prompt: 'Choose a view > ', fzf_args: ['--height=60%'])
      choice ? choice.strip : choice
    end

    ##
    ## @brief      Gets a view from configuration
    ##
    ## @param      title  (String) The title of the view to retrieve
    ##
    def get_view(title)
      return @config['views'][title] if @config['views'].has_key?(title)

      false
    end

    ##
    ## @brief      Overachieving function for displaying contents of a section.
    ##             This is a fucking mess. I mean, Jesus Christ.
    ##
    ## @param      opt   (Hash) Additional Options
    ##
    def list_section(opt = {})
      opt[:count] ||= 0
      opt[:age] ||= 'newest'
      opt[:format] ||= @default_date_format
      opt[:order] ||= 'desc'
      opt[:tag_order] ||= 'asc'
      opt[:tags_color] ||= false
      opt[:template] ||= @default_template

      # opt[:highlight] ||= true
      section = ''
      is_single = true
      if opt[:section].nil?
        section = choose_section
        target_section = @content[section]
      elsif opt[:section].instance_of?(String)
        if opt[:section] =~ /^all$/i
          is_single = false
          combined = { :items => [] }
          @content.each do |_k, v|
            combined[:items] += v[:items]
          end
          section = if opt[:page_title]
                      opt[:page_title]
                    elsif opt[:tag_filter] && opt[:tag_filter]['bool'].normalize_bool != :not
                      opt[:tag_filter]['tags'].map { |tag| "@#{tag}" }.join(' + ')
                    else
                      'doing'
                    end
          target_section = combined
        else
          section = guess_section(opt[:section])
          target_section = @content[section]
        end
      end

      raise Errors::InvalidSection, 'Invalid section object' unless target_section.instance_of? Hash

      items = target_section[:items].sort_by { |item| item.date }

      items = filter_items(items, opt: opt).reverse

      items.reverse! if opt[:order] =~ /^d/i

      out = nil

      if opt[:interactive]
        opt[:menu] = !opt[:force]
        opt[:query] = '' # opt[:search]
        selected = choose_from_items(items, opt, include_section: opt[:section] =~ /^all$/i )

        if selected.empty?
          logger.debug('Skipped:', 'No selection')
          return
        end

        act_on(selected, opt)
        return
      end

      opt[:output] ||= 'template'

      opt[:wrap_width] ||= @config['templates']['default']['wrap_width']

      raise Errors::InvalidArgument, 'Unknown output format' unless opt[:output] =~ Plugins.plugin_regex(type: :export)

      # exporter = WWIDExport.new(section, items, is_single, opt, self)
      export_options = { page_title: section, is_single: is_single, options: opt }

      Plugins.plugins[:export].each do |_, options|
        next unless opt[:output] =~ /^(#{options[:trigger].normalize_trigger})$/i

        out = options[:class].render(self, items, variables: export_options)
        break
      end

      out
    end

    def load_plugins
      if @config.key?('plugins') && @config['plugins']['plugin_path']
        add_dir = @config['plugins']['plugin_path']
      else
        add_dir = File.join(@user_home, '.config', 'doing', 'plugins')
        FileUtils.mkdir_p(add_dir) if add_dir
      end

      Plugins.load_plugins(add_dir)
    end

    ##
    ## @brief      Move entries from a section to Archive or other specified
    ##             section
    ##
    ## @param      section      (String) The source section
    ## @param      options      (Hash) Options
    ##
    def archive(section = @current_section, options = {})
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
        raise Errors::InvalidArgument, 'Either source or destination does not exist'
      end
    end

    ##
    ## @brief      Helper function, performs the actual archiving
    ##
    ## @param      section      (String) The source section
    ## @param      destination  (String) The destination section
    ## @param      opt          (Hash) Additional Options
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
            if label && section != @current_section
              item.title =
                item.title.sub(/(?:@from\(.*?\))?(.*)$/, "\\1 @from(#{section})")
            end
          end

          @content[section][:items] = items
          @content[destination][:items].concat(moved_items)
          logger.info('Archived:', "#{moved_items.length} items from #{section} to #{destination}")
        else
          count = items.length if items.length < count

          items.map! do |item|
            if label && section != @current_section
              item.title =
                item.title.sub(/(?:@from\(.*?\))?(.*)$/, "\\1 @from(#{section})")
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

          logger.info('Archived:', "#{items.length - count} items from #{section} to #{destination}")
        end
      end
    end

    ##
    ## @brief      Show all entries from the current day
    ##
    ## @param      times   (Boolean) show times
    ## @param      output  (String) output format
    ## @param      opt     (Hash) Options
    ##
    def today(times = true, output = nil, opt = {})
      opt[:totals] ||= false
      opt[:sort_tags] ||= false

      cfg = @config['templates']['today']
      options = {
        after: opt[:after],
        before: opt[:before],
        count: 0,
        format: cfg['date_format'],
        order: 'asc',
        output: output,
        section: opt[:section],
        sort_tags: opt[:sort_tags],
        template: cfg['template'],
        times: times,
        today: true,
        totals: opt[:totals],
        wrap_width: cfg['wrap_width']
      }
      list_section(options)
    end

    ##
    ## @brief      Display entries within a date range
    ##
    ## @param      dates    (Array) [start, end]
    ## @param      section  (String) The section
    ## @param      times    (Bool) Show times
    ## @param      output   (String) Output format
    ## @param      opt      (Hash) Additional Options
    ##
    def list_date(dates, section, times = nil, output = nil, opt = {})
      opt[:totals] ||= false
      opt[:sort_tags] ||= false
      section = guess_section(section)
      # :date_filter expects an array with start and end date
      dates = [dates, dates] if dates.instance_of?(String)

      list_section({ section: section, count: 0, order: 'asc', date_filter: dates, times: times,
                     output: output, totals: opt[:totals], sort_tags: opt[:sort_tags] })
    end

    ##
    ## @brief      Show entries from the previous day
    ##
    ## @param      section  (String) The section
    ## @param      times    (Bool) Show times
    ## @param      output   (String) Output format
    ## @param      opt      (Hash) Additional Options
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
        order: 'asc',
        output: output,
        section: section,
        sort_tags: opt[:sort_tags],
        tag_order: opt[:tag_order],
        times: times,
        totals: opt[:totals],
        yesterday: true
      }

      list_section(options)
    end

    ##
    ## @brief      Show recent entries
    ##
    ## @param      count    (Integer) The number to show
    ## @param      section  (String) The section to show from, default Currently
    ## @param      opt      (Hash) Additional Options
    ##
    def recent(count = 10, section = nil, opt = {})
      times = opt[:t] || true
      opt[:totals] ||= false
      opt[:sort_tags] ||= false

      cfg = @config['templates']['recent']
      section ||= @current_section
      section = guess_section(section)

      list_section({ section: section, wrap_width: cfg['wrap_width'], count: count,
                     format: cfg['date_format'], template: cfg['template'],
                     order: 'asc', times: times, totals: opt[:totals],
                     sort_tags: opt[:sort_tags], tags_color: opt[:tags_color] })
    end

    ##
    ## @brief      Show the last entry
    ##
    ## @param      times    (Bool) Show times
    ## @param      section  (String) Section to pull from, default Currently
    ##
    def last(times: true, section: nil, options: {})
      section = section.nil? || section =~ /all/i ? 'All' : guess_section(section)
      cfg = @config['templates']['last']

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

      list_section(opts)
    end

    ##
    ## @brief Uses 'autotag' configuration to turn keywords into tags for time tracking.
    ## Does not repeat tags in a title, and only converts the first instance of an
    ## untagged keyword
    ##
    ## @param      text  (String) The text to tag
    ##
    def autotag(text)
      return unless text
      return text unless @auto_tag

      current_tags = text.scan(/@\w+/)
      whitelisted = []
      @config['autotag']['whitelist'].each do |tag|
        next if text =~ /@#{tag}\b/i

        text.sub!(/(?<!@)(#{tag.strip})\b/i) do |m|
          m.downcase! if tag =~ /[a-z]/
          whitelisted.push("@#{m}")
          "@#{m}"
        end
      end
      tail_tags = []
      @config['autotag']['synonyms'].each do |tag, v|
        v.each do |word|
          next unless text =~ /\b#{word}\b/i

          tail_tags.push(tag) unless current_tags.include?("@#{tag}") || whitelisted.include?("@#{tag}")
        end
      end
      if @config['autotag'].key? 'transform'
        @config['autotag']['transform'].each do |tag|
          next unless tag =~ /\S+:\S+/

          rx, r = tag.split(/:/)
          r.gsub!(/\$/, '\\')
          rx.sub!(/^@/, '')
          regex = Regexp.new('@' + rx + '\b')

          matches = text.scan(regex)
          next unless matches

          matches.each do |m|
            new_tag = r
            if m.is_a?(Array)
              index = 1
              m.each do |v|
                new_tag.gsub!('\\' + index.to_s, v)
                index += 1
              end
            end
            tail_tags.push(new_tag)
          end
        end
      end

      logger.debug('Autotag:', "Whitelisted tags: #{whitelisted.join(', ')}") unless whitelisted.empty?

      unless tail_tags.empty?
        tags = tail_tags.uniq.map { |t| "@#{t}".cyan }.join(' ')
        logger.debug('Autotag:', "Synonym tags: #{tags}")
        tags_a = tail_tags.map { |t| "@#{t}" }.join(' ')
        text.add_tags!(tags_a)
      end

      text
    end

    ##
    ## @brief      Get total elapsed time for all tags in
    ##             selection
    ##
    ## @param      format        (String) return format (html,
    ##                           json, or text)
    ## @param      sort_by_name  (Boolean) Sort by name if true, otherwise by time
    ## @param      sort_order    (String) The sort order (asc or desc)
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
            output += "<tr><td style='text-align:left;'>#{k}</td><td style='text-align:left;'>#{'%02d:%02d:%02d' % fmt_time(v)}</td></tr>\n"
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
          <td style="text-align:left;">#{'%02d:%02d:%02d' % fmt_time(total)}</td>
        </tr>
        </tfoot>
        </table>
EOS
        output + tail
      when :markdown
        pad = sorted_tags_data.map {|k, v| k }.group_by(&:size).max.last[0].length
        output = <<-EOS
  | #{' ' * (pad - 7) }project | time     |
  | #{'-' * (pad - 1)}: | :------- |
        EOS
        sorted_tags_data.reverse.each do |k, v|
          if v > 0
            output += "| #{' ' * (pad - k.length)}#{k} | #{'%02d:%02d:%02d' % fmt_time(v)} |\n"
          end
        end
        tail = "[Tag Totals]"
        output + tail
      when :json
        output = []
        sorted_tags_data.reverse.each do |k, v|
          d, h, m = fmt_time(v)
          output << {
            'tag' => k,
            'seconds' => v,
            'formatted' => format('%<d>02d:%<h>02d:%<m>02d', d: d, h: h, m: m)
          }
        end
        output
      else
        output = []
        sorted_tags_data.reverse.each do |k, v|
          spacer = ''
          (max - k.length).times do
            spacer += ' '
          end
          d, h, m = fmt_time(v)
          output.push("#{k}:#{spacer}#{format('%<d>02d:%<h>02d:%<m>02d', d: d, h: h, m: m)}")
        end

        output = output.empty? ? '' : "\n--- Tag Totals ---\n#{output.join("\n")}"
        d, h, m = fmt_time(total)
        output += "\n\nTotal tracked: #{format('%<d>02d:%<h>02d:%<m>02d', d: d, h: h, m: m)}\n"
        output
      end
    end

    ##
    ## @brief      Gets the interval between entry's start
    ##             date and @done date
    ##
    ## @param      item       (Hash) The entry
    ## @param      formatted  (Bool) Return human readable
    ##                        time (default seconds)
    ## @param      record     (Bool) Add the interval to the
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

        return seconds.positive? ? format('%02d:%02d:%02d', *fmt_time(seconds)) : false
      end

      false
    end

    ##
    ## @brief      Record times for item tags
    ##
    ## @param      item  The item
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
    ## @brief      Format human readable time from seconds
    ##
    ## @param      seconds  The seconds
    ##
    def fmt_time(seconds)
      return [0, 0, 0] if seconds.nil?

      if seconds.class == String && seconds =~ /(\d+):(\d+):(\d+)/
        h = Regexp.last_match(1)
        m = Regexp.last_match(2)
        s = Regexp.last_match(3)
        seconds = (h.to_i * 60 * 60) + (m.to_i * 60) + s.to_i
      end
      minutes = (seconds / 60).to_i
      hours = (minutes / 60).to_i
      days = (hours / 24).to_i
      hours = (hours % 24).to_i
      minutes = (minutes % 60).to_i
      [days, hours, minutes]
    end

    ##
    ## @brief      Test if command line tool is available
    ##
    ## @param      cli   (String) The name or path of the cli
    ##
    def exec_available(cli)
      if File.exist?(File.expand_path(cli))
        File.executable?(File.expand_path(cli))
      else
        system "which #{cli}", out: File::NULL, err: File::NULL
      end
    end

    private

    def run_after
      return unless @config.key?('run_after')

      _, stderr, status = Open3.capture3(@config['run_after'])
      return unless status.exitstatus.positive?

      logger.log_now(:error, 'Script error:', "Error running #{@config['run_after']}")
      logger.log_now(:error, 'STDERR output:', stderr)
    end
  end
end
