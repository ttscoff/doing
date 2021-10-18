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
    attr_accessor :content, :current_section, :doing_file, :config, :user_home, :default_config_file,
                  :config_file, :results, :auto_tag, :timers, :interval_cache, :recorded_items

    include Doing::Util
    ##
    ## @brief      Initializes the object.
    ##
    def initialize
      @content = {}
      @doingrc_needs_update = false
      @default_config_file = '.doingrc'
      @interval_cache = {}
      @results = []
      @auto_tag = true
      @plugins = nil
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

      additional_configs = if opt[:ignore_local]
                             []
                           else
                             find_local_config
                           end

      begin
        @local_config = {}

        @config = YAML.load_file(@config_file) || {} if File.exist?(@config_file)
        additional_configs.each do |cfg|
          new_config = YAML.load_file(cfg) || {} if cfg
          @local_config = @local_config.deep_merge(new_config)
        end

        # @config.deep_merge(@local_config)
      rescue StandardError
        @config = {}
        @local_config = {}
        # exit_now! "error reading config"
      end
    end

    ##
    ## @brief      Read user configuration and merge with defaults
    ##
    ## @param      opt   (Hash) Additional Options
    ##
    def configure(opt = {})
      @timers = {}
      @recorded_items = []
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
      @config['plugin_path'] ||= nil

      # @config['html_template'] ||= {}
      # @config['html_template']['haml'] ||= nil
      # @config['html_template']['css'] ||= nil
      # @config['html_template']['markdown'] ||= nil

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
      @config['tag_sort'] ||= 'time'

      @current_section = config['current_section']
      @default_template = config['templates']['default']['template']
      @default_date_format = config['templates']['default']['date_format']

      @config[:include_notes] ||= true

      # if ENV['DOING_DEBUG'].to_i == 3
      #   if @config['default_tags'].length > 0
      #     exit_now! "DEFAULT CONFIG CHANGED"
      #   end
      # end
      @plugins = nil
      plugin_config = {}

      plugins.each do |type, plugins|
        plugins.each do |_, plugin|
          if plugin.key?(:config)
            plugin_config.deep_merge(plugin[:config])
          end
        end
      end

      @config = plugin_config.deep_merge(@config)

      if !File.exist?(@config_file) || opt[:rewrite]
        File.open(@config_file, 'w') { |yf| YAML.dump(@config, yf) }
      end

      @config = @local_config.deep_merge(@config)

      @current_section = @config['current_section']
      @default_template = @config['templates']['default']['template']
      @default_date_format = @config['templates']['default']['date_format']
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
          @content[section]['original'] = line
          @content[section]['items'] = []
          current = 0
        elsif line =~ /^\s*- (\d{4}-\d\d-\d\d \d\d:\d\d) \| (.*)/
          date = Time.parse(Regexp.last_match(1))
          title = Regexp.last_match(2)
          @content[section]['items'].push({ 'title' => title, 'date' => date, 'section' => section })
          current += 1
        elsif current.zero?
          # if content[section]['items'].length - 1 == current
          @other_content_top.push(line)
        elsif line =~ /^\S/
          @other_content_bottom.push(line)
        else
          @content[section]['items'][current - 1]['note'] = [] unless @content[section]['items'][current - 1].key? 'note'

          @content[section]['items'][current - 1]['note'].push(line.chomp)
          # end
        end
      end
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

      input.split(/\n/).delete_if {|line| line =~ /^#/ }.join("\n")
    end

    #
    # @brief      Takes a multi-line string and formats it as an entry
    #
    # @return     (Array) [(String)title, (Array)note]
    #
    # @param      input  (String) The string to parse
    #
    def format_input(input)
      exit_now! 'No content in entry' if input.nil? || input.strip.empty?

      input_lines = input.split(/[\n\r]+/).delete_if {|line| line =~ /^#/ || line =~ /^\s*$/ }
      title = input_lines[0]&.strip
      exit_now! 'No content in first line' if title.nil? || title.strip.empty?

      note = input_lines.length > 1 ? input_lines[1..-1] : []
      # If title line ends in a parenthetical, use that as the note
      if note.empty? && title =~ /\s+\(.*?\)$/
        title.sub!(/\s+\((.*?)\)$/) do
          m = Regexp.last_match
          note.push(m[1])
          ''
        end
      end

      note.map!(&:strip)
      note.delete_if { |line| line =~ /^\s*$/ || line =~ /^#/ }

      [title, note]
    end

    #
    # @brief      Converts input string into a Time object when input takes on the
    #             following formats:
    #             - interval format e.g. '1d2h30m', '45m' etc.
    #             - a semantic phrase e.g. 'yesterday 5:30pm'
    #             - a strftime e.g. '2016-03-15 15:32:04 PDT'
    #
    # @param      input  (String) String to chronify
    #
    # @return     (DateTime) result
    #
    def chronify(input)
      now = Time.now
      exit_now! "Invalid time expression #{input.inspect}" if input.to_s.strip == ''

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
        Chronic.parse(input, { context: :past, ambiguous_time_range: 8 })
      end
    end

    #
    # @brief      Converts simple strings into seconds that can be added to a Time
    #             object
    #
    # @param      qty   (String) HH:MM or XX[dhm][[XXhm][XXm]] (1d2h30m, 45m,
    #                   1.5d, 1h20m, etc.)
    #
    # @return     (Integer) seconds
    #
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
      @content[title.cap_first] = { 'original' => "#{title}:", 'items' => [] }
      @results.push(%(Added section "#{title.cap_first}"))
    end

    ##
    ## @brief      Attempt to match a string with an existing section
    ##
    ## @param      frag     (String) The user-provided string
    ## @param      guessed  (Boolean) already guessed and failed
    ##
    def guess_section(frag, guessed: false)
      return 'All' if frag =~ /^all$/i
      frag ||= @current_section
      sections.each { |section| return section.cap_first if frag.downcase == section.downcase }
      section = false
      re = frag.split('').join('.*?')
      sections.each do |sect|
        next unless sect =~ /#{re}/i

        warn "Assuming you meant #{sect}"
        section = sect
        break
      end
      unless section || guessed
        alt = guess_view(frag, true)
        exit_now! "Did you mean `doing view #{alt}`?" if alt

        res = yn("Section #{frag} not found, create it", default_response: false)

        if res
          add_section(frag.cap_first)
          write(@doing_file)
          return frag.cap_first
        end

        exit_now! "Unknown section: #{frag}"
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
      default = default_response ? default_response : 'n'

      # if this isn't an interactive shell, answer default
      return default.downcase == 'y' unless $stdout.isatty

      # clear the buffer
      if ARGV&.length
        ARGV.length.times do
          ARGV.shift
        end
      end
      system 'stty cbreak'

      cw = colors['white']
      cbw = colors['boldwhite']
      cbg = colors['boldgreen']
      cd = colors['default']

      options = if default
                  default =~ /y/i ? "#{cw}[#{cbg}Y#{cw}/#{cbw}n#{cw}]#{cd}" : "#{cw}[#{cbw}y#{cw}/#{cbg}N#{cw}]#{cd}"
                else
                  "#{cw}[#{cbw}y#{cw}/#{cbw}n#{cw}]#{cd}"
                end
      $stdout.syswrite "#{cbw}#{question.sub(/\?$/, '')} #{options}#{cbw}?#{cd} "
      res = $stdin.sysread 1
      puts
      system 'stty cooked'

      res.chomp!
      res.downcase!

      res = default.downcase if res == ''

      res =~ /y/i
    end

    ##
    ## @brief      Attempt to match a string with an existing view
    ##
    ## @param      frag     (String) The user-provided string
    ## @param      guessed  (Boolean) already guessed
    ##
    def guess_view(frag, guessed = false)
      views.each { |view| return view if frag.downcase == view.downcase }
      view = false
      re = frag.split('').join('.*?')
      views.each do |v|
        next unless v =~ /#{re}/i

        warn "Assuming you meant #{v}"
        view = v
        break
      end
      unless view || guessed
        alt = guess_section(frag, guessed: true)
        if alt
          exit_now! "Did you mean `doing show #{alt}`?"
        else
          exit_now! "Unknown view: #{frag}"
        end
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
      add_section(section) unless @content.has_key?(section)
      opt[:date] ||= Time.now
      opt[:note] ||= []
      opt[:back] ||= Time.now
      opt[:timed] ||= false

      opt[:note] = [opt[:note]] if opt[:note].instance_of?(String)

      title = [title.strip.cap_first]
      title = title.join(' ')

      if @auto_tag
        title = autotag(title)
        unless @config['default_tags'].empty?
          default_tags = @config['default_tags'].map do |t|
            next if t.nil?

            dt = t.sub(/^ *@/, '').chomp
            if title =~ /@#{dt}/
              ''
            else
              " @#{dt}"
            end
          end
          default_tags.delete_if { |t| t == '' }
          title += default_tags.join(' ')
        end
      end
      title.gsub!(/ +/, ' ')
      entry = { 'title' => title.strip, 'date' => opt[:back] }
      entry['note'] = opt[:note].map(&:chomp) unless opt[:note].join('').strip == ''
      items = @content[section]['items']
      if opt[:timed]
        items.reverse!
        items.each_with_index do |i, x|
          next if i['title'] =~ / @done/

          items[x]['title'] = "#{i['title']} @done(#{opt[:back].strftime('%F %R')})"
          break
        end
        items.reverse!
      end
      items.push(entry)
      @content[section]['items'] = items
      @results.push(%(Added "#{entry['title']}" to #{section}))
    end

    def same_time?(item_a, item_b)
      item_a['date'] == item_b['date'] ? get_interval(item_a, formatted: false, record: false) == get_interval(item_b,  formatted: false, record: false) : false
    end

    def overlapping_time?(item_a, item_b)
      return true if same_time?(item_a, item_b)

      start_a = item_a['date']
      interval = get_interval(item_a, formatted: false, record: false)
      end_a = interval ? start_a + interval.to_i : start_a
      start_b = item_b['date']
      interval = get_interval(item_b,  formatted: false, record: false)
      end_b = interval ? start_b + interval.to_i : start_b
      (start_a >= start_b && start_a <= end_b) || (end_a >= start_b && end_a <= end_b) || (start_a < start_b && end_a > end_b)
    end

    def dedup(items, no_overlap = false)

      combined = []
      @content.each do |_k, v|
        combined += v['items']
      end

      items.delete_if do |item|
        duped = false
        combined.each do |comp|
          duped = no_overlap ? overlapping_time?(item, comp) : same_time?(item, comp)
          break if duped
        end
        # warn "Skipping overlapping entry: #{item['title']}" if duped
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
      plugins[:import].each do |_, options|
        next unless opt[:type] =~ /^(#{options[:trigger]})$/i

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
        combined = { 'items' => [] }
        @content.each do |_k, v|
          combined['items'] += v['items']
        end
        section = combined['items'].dup.sort_by { |item| item['date'] }.reverse[0]['section']
      end

      exit_now! "Section #{section} not found" unless @content.key?(section)

      last_item = @content[section]['items'].dup.sort_by { |item| item['date'] }.reverse[0]
      warn "Editing note for #{last_item['title']}"
      note = ''
      note = last_item['note'].map(&:strip).join("\n") unless last_item['note'].nil?
      "#{last_item['title']}\n# EDIT BELOW THIS LINE ------------\n#{note}"
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
        @results.push(%(No previous entry found))
        return
      end
      unless last.has_tags?(['done'], 'ALL')
        new_item = last.dup
        new_item['title'] += " @done(#{Time.now.strftime('%F %R')})"
        update_item(last, new_item)
      end
      # Remove @done tag
      title = last['title'].sub(/\s*@done(\(.*?\))?/, '').chomp
      section = opt[:in].nil? ? last['section'] : guess_section(opt[:in])
      @auto_tag = false
      add_item(title, section, { note: opt[:note], back: opt[:date], timed: true })
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

      sec_arr = []

      if opt[:section].nil?
        sec_arr = [@current_section]
      elsif opt[:section].instance_of?(String)
        if opt[:section] =~ /^all$/i
          combined = { 'items' => [] }
          @content.each do |_k, v|
            combined['items'] += v['items']
          end
          items = combined['items'].dup.sort_by { |item| item['date'] }.reverse
          sec_arr.push(items[0]['section'])
        else
          sec_arr = [guess_section(opt[:section])]
        end
      end

      all_items = []
      sec_arr.each do |section|
        all_items.concat(@content[section]['items'].dup) if @content.key?(section)
      end

      if opt[:tag]&.length
        all_items.select! { |item| item.has_tags?(opt[:tag], opt[:tag_bool]) }
      elsif opt[:search]&.length
        all_items.select! { |item| item.matches_search?(opt[:search]) }
      end

      all_items.max_by { |item| item['date'] }
    end

    ##
    ## @brief      Generate a menu of options and allow user selection
    ##
    ## @return     (String) The selected option
    ##
    def choose_from(options, prompt: 'Make a selection: ', multiple: false, fzf_args: [])
      fzf = File.join(File.dirname(__FILE__), '../helpers/fuzzyfilefinder')
      fzf_args << '-1'
      fzf_args << %(--prompt "#{prompt}")
      fzf_args << '--multi' if multiple
      header = "esc: cancel,#{multiple ? ' tab: multi-select, ctrl-a: select all,' : ''} return: confirm"
      fzf_args << %(--header "#{header}")
      res = `echo #{Shellwords.escape(options.join("\n"))}|#{fzf} #{fzf_args.join(' ')}`
      return false if res.strip.size.zero?

      res
    end

    ##
    ## @brief      Display an interactive menu of entries
    ##
    ## @param      opt   (Hash) Additional options
    ##
    def interactive(opt = {})
      fzf = File.join(File.dirname(__FILE__), '../helpers/fuzzyfilefinder')

      section = opt[:section] ? guess_section(opt[:section]) : 'All'


      if section =~ /^all$/i
        combined = { 'items' => [] }
        @content.each do |_k, v|
          combined['items'] += v['items']
        end
        items = combined['items'].dup.sort_by { |item| item['date'] }.reverse
      else
        items = @content[section]['items']
      end


      options = items.map.with_index do |item, i|
        out = [
          i,
          ') ',
          item['date'],
          ' | ',
          item['title']
        ]
        if section =~ /^all/i
          out.concat([
            ' (',
            item['section'],
            ') '
          ])
        end
        out.join('')
      end
      fzf_args = [
        %(--header="Arrows: navigate, tab: mark for selection, ctrl-a: select all, enter: commit"),
        %(--prompt="Select entries to act on > "),
        '-1',
        '-m',
        '--bind ctrl-a:select-all',
        %(-q "#{opt[:query]}")
      ]
      if !opt[:menu]
        exit_now! "Can't skip menu when no query is provided" unless opt[:query]

        fzf_args.concat([%(--filter="#{opt[:query]}"), '--no-sort'])
      end

      res = `echo #{Shellwords.escape(options.join("\n"))}|#{fzf} #{fzf_args.join(' ')}`
      selected = []
      res.split(/\n/).each do |item|
        idx = item.match(/^(\d+)\)/)[1].to_i
        selected.push(items[idx])
      end

      if selected.empty?
        @results.push("No selection")
        return
      end

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
                             fzf_args: ['--height=60%', '--tac', '--no-sort'])
        return unless choice

        to_do = choice.strip.split(/\n/)
        to_do.each do |action|
          case action
          when /(add|remove) tag/
            type = action =~ /^add/ ? 'add' : 'remove'
            if opt[:tag]
              exit_now! "'add tag' and 'remove tag' can not be used together"
            end
            print "#{colors['yellow']}Tag to #{type}: #{colors['reset']}"
            tag = STDIN.gets
            return if tag =~ /^ *$/
            opt[:tag] = tag.strip.sub(/^@/, '')
            opt[:remove] = true if type == 'remove'
          when /output formatted/
            output_format = choose_from(%w[doing taskpaper json timeline html csv].sort, prompt: 'Which output format? > ', fzf_args: ['--height=60%', '--tac', '--no-sort'])
            return if tag =~ /^ *$/
            opt[:output] = output_format.strip
            res = opt[:force] ? false : yn('Save to file?', default_response: 'n')
            if res
              print "#{colors['yellow']}File path/name: #{colors['reset']}"
              filename = STDIN.gets.strip
              return if filename.empty?
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
        res = opt[:force] ? true : yn("Delete #{selected.size} items?", default_response: 'y')
        if res
          selected.each { |item| delete_item(item) }
          write(@doing_file)
        end
        return
      end

      if opt[:flag]
        tag = @config['marker_tag'] || 'flagged'
        selected.map! do |item|
          if opt[:remove]
            untag_item(item, tag)
          else
            tag_item(item, tag, date: false)
          end
        end
      end

      if opt[:finish] || opt[:cancel]
        tag = 'done'
        selected.map! do |item|
          if opt[:remove]
            untag_item(item, tag)
          else
            tag_item(item, tag, date: !opt[:cancel])
          end
        end
      end

      if opt[:tag]
        tag = opt[:tag]
        selected.map! do |item|
          if opt[:remove]
            untag_item(item, tag)
          else
            tag_item(item, tag, date: false)
          end
        end
      end

      if opt[:archive] || opt[:move]
        section = opt[:archive] ? 'Archive' : guess_section(opt[:move])
        selected.map! {|item| move_item(item, section) }
      end

      write(@doing_file)

      if opt[:editor]

        editable_items = []

        selected.each do |item|
          editable = "#{item['date']} | #{item['title']}"
          old_note = item['note'] ? item['note'].map(&:strip).join("\n") : nil
          editable += "\n#{old_note}" unless old_note.nil?
          editable_items << editable
        end
        divider = "\n-----------\n"
        input = editable_items.map(&:strip).join(divider) + "\n\n# You may delete entries, but leave all divider lines in place"

        new_items = fork_editor(input).split(/#{divider}/)

        new_items.each_with_index do |new_item, i|

          input_lines = new_item.split(/[\n\r]+/).delete_if {|line| line =~ /^#/ || line =~ /^\s*$/ }
          title = input_lines[0]&.strip

          if title.nil? || title =~ /^#{divider.strip}$/ || title.strip.empty?
            delete_item(selected[i])
          else
            note = input_lines.length > 1 ? input_lines[1..-1] : []

            note.map!(&:strip)
            note.delete_if { |line| line =~ /^\s*$/ || line =~ /^#/ }

            date = title.match(/^([\d\-: ]+) \| /)[1]
            title.sub!(/^([\d\-: ]+) \| /, '')

            item = selected[i].dup
            item['title'] = title
            item['note'] = note
            item['date'] = Time.parse(date) || selected[i]['date']
            update_item(selected[i], item)
          end
        end

        write(@doing_file)
      end

      if opt[:output]
        selected.map! do |item|
          item['title'] = "#{item['title']} @project(#{item['section']})"
          item
        end

        @content = { 'Export' => { 'original' => 'Export:', 'items' => selected } }
        options = { section: 'Export' }

        case opt[:output]
        when /doing/
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

          @results.push("Export saved to #{file}")
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
      opt[:section] ||= nil
      opt[:count] ||= 1
      opt[:archive] ||= false
      opt[:tags] ||= ['done']
      opt[:sequential] ||= false
      opt[:date] ||= false
      opt[:remove] ||= false
      opt[:autotag] ||= false
      opt[:back] ||= false
      opt[:took] ||= nil
      opt[:unfinished] ||= false

      sec_arr = []

      if opt[:section].nil?
        if opt[:search] || opt[:tag]
          sec_arr = sections
        else
          sec_arr = [@current_section]
        end
      elsif opt[:section].instance_of?(String)
        if opt[:section] =~ /^all$/i
          if opt[:count] == 1
            combined = { 'items' => [] }
            @content.each do |_k, v|
              combined['items'] += v['items']
            end
            items = combined['items'].dup.sort_by { |item| item['date'] }.reverse
            sec_arr.push(items[0]['section'])
          elsif opt[:count] > 1
            if opt[:search] || opt[:tag]
              sec_arr = sections
            else
              exit_now! 'A count greater than one requires a section to be specified'
            end
          else
            sec_arr = sections
          end
        else
          sec_arr = [guess_section(opt[:section])]
        end
      end

      sec_arr.each do |section|
        if @content.key?(section)

          items = @content[section]['items'].dup.sort_by { |item| item['date'] }.reverse
          idx = 0
          done_date = Time.now
          count = (opt[:count]).zero? ? items.length : opt[:count]
          items.map! do |item|
            break if idx == count
            finished = opt[:unfinished] && item.has_tags?('done', :and)
            tag_match = opt[:tag].nil? || opt[:tag].empty? ? true : item.has_tags?(opt[:tag], opt[:tag_bool])
            search_match = opt[:search].nil? || opt[:search].empty? ? true : item.matches_search?(opt[:search])

            if tag_match && search_match && !finished
              if opt[:autotag]
                new_title = autotag(item['title']) if @auto_tag
                if new_title == item['title']
                  @results.push(%(Autotag: No changes))
                else
                  @results.push("Tags updated: #{new_title}")
                  item['title'] = new_title
                end
              else
                if opt[:sequential]
                  next_entry = next_item(item)

                  if next_entry.nil?
                    done_date = Time.now
                  else
                    done_date = next_entry['date'] - 60
                  end
                elsif opt[:took]
                  if item['date'] + opt[:took] > Time.now
                    item['date'] = Time.now - opt[:took]
                    done_date = Time.now
                  else
                    done_date = item['date'] + opt[:took]
                  end
                elsif opt[:back]
                  if opt[:back].is_a? Integer
                    done_date = item['date'] + opt[:back]
                  else
                    done_date = item['date'] + (opt[:back] - item['date'])
                  end
                else
                  done_date = Time.now
                end

                title = item['title']
                opt[:tags].each do |tag|
                  tag = tag.strip
                  if opt[:remove] || opt[:rename]
                    case_sensitive = tag !~ /[A-Z]/
                    replacement = ''
                    if opt[:rename]
                      replacement = tag
                      tag = opt[:rename]
                    end

                    if opt[:regex]
                      rx_tag = tag.gsub(/\./, '\S')
                    else
                      rx_tag = tag.gsub(/\?/, '.').gsub(/\*/, '\S*?')
                    end

                    if title =~ / @#{rx_tag}\b/
                      rx = Regexp.new("(^| )@#{rx_tag}(\\([^)]*\\))?(?=\\b|$)", case_sensitive)
                      removed_tags = []
                      title.gsub!(rx) do |mtch|
                        removed_tags.push(mtch.strip.sub(/\(.*?\)$/, ''))
                        replacement
                      end

                      title.dedup_tags!

                      @results.push(%(Removed #{removed_tags.join(', ')}: "#{title}" in #{section}))
                    end
                  elsif title !~ /@#{tag}/
                    title.chomp!
                    title += if opt[:date]
                               " @#{tag}(#{done_date.strftime('%F %R')})"
                             else
                               " @#{tag}"
                             end
                    @results.push(%(Added @#{tag}: "#{title}" in #{section}))
                  end
                end
                item['title'] = title
              end

              idx += 1
            end

            item
          end

          @content[section]['items'] = items

          if opt[:archive] && section != 'Archive' && (opt[:count]).positive?
            # concat [count] items from [section] and archive section
            archived = @content[section]['items'][0..opt[:count] - 1].map do |i|
              i['title'].sub!(/(?:@from\(.*?\))?(.*)$/, "\\1 @from(#{i['section']})")
              i
            end.concat(@content['Archive']['items'])
            # slice [count] items off of [section] items
            @content[opt[:section]]['items'] = @content[opt[:section]]['items'][opt[:count]..-1]
            # overwrite archive section with concatenated array
            @content['Archive']['items'] = archived
            # log it
            result = opt[:count] == 1 ? '1 entry' : "#{opt[:count]} entries"
            @results.push("Archived #{result} from #{section}")
          elsif opt[:archive] && (opt[:count]).zero?
            @results.push('Archiving is skipped when operating on all entries') if (opt[:count]).zero?
          end
        else
          exit_now! "Section not found: #{section}"
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
    def move_item(item, section)
      old_section = item['section']
      new_item = item.dup
      new_item['section'] = section

      section_items = @content[old_section]['items']
      section_items.delete(item)
      @content[old_section]['items'] = section_items

      archive_items = @content[section]['items']
      archive_items.push(new_item)
      # archive_items = archive_items.sort_by { |item| item['date'] }
      @content[section]['items'] = archive_items

      @results.push("Entry moved to #{section}: #{new_item['title']}")
      return new_item
    end

    ##
    ## @brief      Get next item in the index
    ##
    ## @param      old_item
    ##
    def next_item(old_item)
      combined = { 'items' => [] }
      @content.each do |_k, v|
        combined['items'] += v['items']
      end
      items = combined['items'].dup.sort_by { |item| item['date'] }.reverse
      idx = items.index(old_item)

      if idx > 0
        items[idx - 1]
      else
        nil
      end
    end

    ##
    ## @brief      Delete an item from the index
    ##
    ## @param      old_item
    ##
    def delete_item(old_item)
      section = old_item['section']

      section_items = @content[section]['items']
      deleted = section_items.delete(old_item)
      @results.push("Entry deleted: #{deleted['title']}")
      @content[section]['items'] = section_items
    end

    ##
    ## @brief      Remove a tag on an item from the index
    ##
    ## @param      old_item  (Item) The item to tag
    ## @param      tag       (string) The tag to remove
    ##
    def untag_item(old_item, tags)
      title = old_item['title'].dup
      if tags.is_a? ::String
        tags = tags.split(/ *, */).map {|t| t.strip.gsub(/\*/,'[^ (]*') }
      end

      tags.each do |tag|
        if title =~ /@#{tag}/
          title.chomp!
          title.gsub!(/ +@#{tag}(\(.*?\))?/, '')
          new_item = old_item.dup
          new_item['title'] = title
          update_item(old_item, new_item)
          return new_item
        else
          @results.push(%(Item isn't tagged @#{tag}: "#{title}" in #{old_item['section']}))
          return old_item
        end
      end
    end

    ##
    ## @brief      Tag an item from the index
    ##
    ## @param      old_item  (Item) The item to tag
    ## @param      tag       (string) The tag to apply
    ## @param      date      (Boolean) Include timestamp?
    ##
    def tag_item(old_item, tags, remove: false, date: false)
      title = old_item['title'].dup
      if tags.is_a? ::String
        tags = tags.split(/ *, */).map(&:strip)
      end

      done_date = Time.now
      tags.each do |tag|
        if title !~ /@#{tag}/
          title.chomp!
          if date
            title += " @#{tag}(#{done_date.strftime('%F %R')})"
          else
            title += " @#{tag}"
          end
          new_item = old_item.dup
          new_item['title'] = title
          update_item(old_item, new_item)
          return new_item
        else
          @results.push(%(Item already @#{tag}: "#{title}" in #{old_item['section']}))
          return old_item
        end
      end
    end

    ##
    ## @brief      Update an item in the index with a modified item
    ##
    ## @param      old_item  The old item
    ## @param      new_item  The new item
    ##
    def update_item(old_item, new_item)
      section = old_item['section']

      section_items = @content[section]['items']
      s_idx = section_items.index(old_item)

      section_items[s_idx] = new_item
      @results.push("Entry updated: #{section_items[s_idx]['title']}")
      @content[section]['items'] = section_items
    end

    ##
    ## @brief      Edit the last entry
    ##
    ## @param      section  (String) The section, default "All"
    ##
    def edit_last(section: 'All', options: {})
      section = guess_section(section)

      if section =~ /^all$/i
        items = []
        @content.each do |_k, v|
          items.concat(v['items'])
        end
        # section = combined['items'].dup.sort_by { |item| item['date'] }.reverse[0]['section']
      else
        items = @content[section]['items']
      end

      items = items.sort_by { |item| item['date'] }.reverse

      idx = nil

      if options[:tag] && !options[:tag].empty?
        items.each_with_index do |item, i|
          if item.has_tags?(options[:tag], options[:tag_bool])
            idx = i
            break
          end
        end
      elsif options[:search]
        items.each_with_index do |item, i|
          if item.matches_search?(options[:search])
            idx = i
            break
          end
        end
      else
        idx = 0
      end

      if idx.nil?
        @results.push('No entries found')
        return
      end

      section = items[idx]['section']

      section_items = @content[section]['items']
      s_idx = section_items.index(items[idx])

      current_item = section_items[s_idx]['title']
      old_note = section_items[s_idx]['note'] ? section_items[s_idx]['note'].map(&:strip).join("\n") : nil
      current_item += "\n#{old_note}" unless old_note.nil?
      new_item = fork_editor(current_item)
      title, note = format_input(new_item)

      if title.nil? || title.empty?
        @results.push('No content provided')
      elsif title == section_items[s_idx]['title'] && note == old_note
        @results.push('No change in content')
      else
        section_items[s_idx]['title'] = title
        section_items[s_idx]['note'] = note
        @results.push("Entry edited: #{section_items[s_idx]['title']}")
        @content[section]['items'] = section_items
        write(@doing_file)
      end
    end

    ##
    ## @brief      Add a note to the last entry in a section
    ##
    ## @param      section  (String) The section, default "All"
    ## @param      note     (String) The note to add
    ## @param      replace  (Bool) Should replace existing note
    ##
    def note_last(section, note, replace: false)
      section = guess_section(section)

      if section =~ /^all$/i
        combined = { 'items' => [] }
        @content.each do |_k, v|
          combined['items'] += v['items']
        end
        section = combined['items'].dup.sort_by { |item| item['date'] }.reverse[0]['section']
      end

      exit_now! "Section #{section} not found" unless @content.key?(section)

      # sort_section(opt[:section])
      items = @content[section]['items'].dup.sort_by { |item| item['date'] }.reverse

      current_note = items[0]['note']
      current_note = [] if current_note.nil?
      title = items[0]['title']
      if replace
        items[0]['note'] = note
        if note.empty? && !current_note.empty?
          @results.push(%(Removed note from "#{title}"))
        elsif !current_note.empty? && !note.empty?
          @results.push(%(Replaced note from "#{title}"))
        elsif !note.empty?
          @results.push(%(Added note to "#{title}"))
        else
          @results.push(%(Entry "#{title}" has no note))
        end
      elsif current_note.instance_of?(Array)
        items[0]['note'] = current_note.concat(note)
        @results.push(%(Added note to "#{title}")) unless note.empty?
      else
        items[0]['note'] = note
        @results.push(%(Added note to "#{title}")) unless note.empty?
      end

      @content[section]['items'] = items

    end

    #
    # @brief      Accepts one tag and the raw text of a new item if the passed tag
    #             is on any item, it's replaced with @done. if new_item is not
    #             nil, it's tagged with the passed tag and inserted. This is for
    #             use where only one instance of a given tag should exist
    #             (@meanwhile)
    #
    # @param      tag   (String) Tag to replace
    # @param      opt   (Hash) Additional Options
    #
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
      @content[opt[:section]]['items'].each_with_index do |item, i|
        next unless item['title'] =~ /@#{tag}/

        title = item['title'].gsub(/(^| )@(#{tag}|done)(\([^)]*\))?/, '')
        title += " @done(#{opt[:back].strftime('%F %R')})"

        @content[opt[:section]]['items'][i]['title'] = title
        found_items += 1

        if opt[:archive] && opt[:section] != 'Archive'
          @results.push(%(Completed and archived "#{@content[opt[:section]]['items'][i]['title']}"))
          archive_item = @content[opt[:section]]['items'][i]
          archive_item['title'] = i['title'].sub(/(?:@from\(.*?\))?(.*)$/, "\\1 @from(#{i['section']})")
          @content['Archive']['items'].push(archive_item)
          @content[opt[:section]]['items'].delete_at(i)
        else
          @results.push(%(Completed "#{@content[opt[:section]]['items'][i]['title']}"))
        end
      end

      @results.push("No active @#{tag} tasks found.") if found_items == 0

      if opt[:new_item]
        title, note = format_input(opt[:new_item])
        note.push(opt[:note].map(&:chomp)) if opt[:note]
        title += " @#{tag}"
        add_item(title.cap_first, opt[:section], { note: note.join(' ').rstrip, back: opt[:back] })
      end

      write(@doing_file)
    end

    ##
    ## @brief      Write content to file or STDOUT
    ##
    ## @param      file  (String) The filepath to write to
    ##
    def write(file = nil, backup: true)
      output = @other_content_top ? "#{@other_content_top.join("\n")}\n" : ''

      @content.each do |title, section|
        output += "#{section['original']}\n"
        output += list_section({ section: title, template: "\t- %date | %title%idnote", highlight: false })
      end
      output += @other_content_bottom.join("\n") unless @other_content_bottom.nil?
      if file.nil?
        $stdout.puts output
      else
        file = File.expand_path(file)
        if File.exist?(file) && backup
          # Create a backup copy for the undo command
          FileUtils.cp(file, "#{file}~")
        end

        File.open(file, 'w+') do |f|
          f.puts output
        end

        if @config.key?('run_after')
          _, _, status = Open3.capture3(@config['run_after'])
          if status.exitstatus.positive?
            warn "Error running #{@config['run_after']}"
            warn stderr
          end
        end
      end
    end

    ##
    ## @brief      Restore a backed up version of a file
    ##
    ## @param      file  (String) The filepath to restore
    ##
    def restore_backup(file)
      if File.exist?(file + '~')
        puts file + '~'
        FileUtils.cp(file + '~', file)
        @results.push("Restored #{file}")
      end
    end

    ##
    ## @brief      Rename doing file with date and start fresh one
    ##
    def rotate(opt = {})
      count = opt[:keep] || 0
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
        items = @content[section]['items'].dup
        new_content[section] = {}
        new_content[section]['original'] = @content[section]['original']
        new_content[section]['items'] = []

        moved_items = []
        if !tags.empty? || opt[:search] || opt[:before]
          if opt[:before]
            time_string = opt[:before]
            time_string += ' 12am' if time_string !~ /(\d+:\d+|\d+[ap])/
            cutoff = chronify(time_string)
          end

          items.delete_if do |item|
            if ((!tags.empty? && item.has_tags?(tags, bool)) || (opt[:search] && item.matches_search?(opt[:search].to_s)) || (opt[:before] && item['date'] < cutoff))
              moved_items.push(item)
              counter += 1
              true
            else
              false
            end
          end
          @content[section]['items'] = items
          new_content[section]['items'] = moved_items
          @results.push("Rotated #{moved_items.length} items from #{section}")
        else
          new_content[section]['items'] = []
          moved_items = []

          count = items.length if items.length < count

          if items.count > count
            moved_items.concat(items[count..-1])
          else
            moved_items.concat(items)
          end

          @content[section]['items'] = if count.zero?
                                         []
                                       else
                                         items[0..count - 1]
                                       end
          new_content[section]['items'] = moved_items

          @results.push("Rotated #{items.length - count} items from #{section}")
        end
      end

      write(@doing_file)

      file = @doing_file.sub(/(\.\w+)$/, "_#{Time.now.strftime('%Y-%m-%d')}\\1")
      if File.exist?(file)
        init_doing_file(file)
        @content.deep_merge(new_content)
      else
        @content = new_content
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
      count = opt[:count] - 1
      opt[:age] ||= 'newest'
      opt[:date_filter] ||= []
      opt[:format] ||= @default_date_format
      opt[:only_timed] ||= false
      opt[:order] ||= 'desc'
      opt[:search] ||= false
      opt[:section] ||= nil
      opt[:sort_tags] ||= false
      opt[:tag_filter] ||= false
      opt[:tag_order] ||= 'asc'
      opt[:tags_color] ||= false
      opt[:template] ||= @default_template
      opt[:times] ||= false
      opt[:today] ||= false
      opt[:totals] ||= false

      # opt[:highlight] ||= true
      section = ''
      is_single = true
      if opt[:section].nil?
        section = choose_section
        opt[:section] = @content[section]
      elsif opt[:section].instance_of?(String)
        if opt[:section] =~ /^all$/i
          is_single = false
          combined = { 'items' => [] }
          @content.each do |_k, v|
            combined['items'] += v['items']
          end
          section = if opt[:tag_filter] && opt[:tag_filter]['bool'].normalize_bool != :not
                      opt[:tag_filter]['tags'].map do |tag|
                        "@#{tag}"
                      end.join(' + ')
                    else
                      'doing'
                    end
          opt[:section] = combined
        else
          section = guess_section(opt[:section])
          opt[:section] = @content[section]
        end
      end

      exit_now! 'Invalid section object' unless opt[:section].instance_of? Hash

      items = opt[:section]['items'].sort_by { |item| item['date'] }

      if opt[:date_filter].length == 2
        start_date = opt[:date_filter][0]
        end_date = opt[:date_filter][1]
        items.keep_if do |item|
          if end_date
            item['date'] >= start_date && item['date'] <= end_date
          else
            item['date'].strftime('%F') == start_date.strftime('%F')
          end
        end
      end

      if opt[:tag_filter] && !opt[:tag_filter]['tags'].empty?
        items.select! { |item| item.has_tags?(opt[:tag_filter]['tags'], opt[:tag_filter]['bool']) }
      end

      if opt[:search]
        items.keep_if {|item| item.matches_search?(opt[:search]) }
      end

      if opt[:only_timed]
        items.delete_if do |item|
          get_interval(item, record: false) == false
        end
      end

      if opt[:before]
        time_string = opt[:before]
        time_string += ' 12am' if time_string !~ /(\d+:\d+|\d+[ap])/
        cutoff = chronify(time_string)
        if cutoff
          items.delete_if { |item| item['date'] >= cutoff }
        end
      end

      if opt[:after]
        time_string = opt[:after]
        time_string += ' 11:59pm' if time_string !~ /(\d+:\d+|\d+[ap])/
        cutoff = chronify(time_string)
        if cutoff
          items.delete_if { |item| item['date'] <= cutoff }
        end
      end

      if opt[:today]
        items.delete_if do |item|
          item['date'] < Date.today.to_time
        end.reverse!
        section = Time.now.strftime('%A, %B %d')
      elsif opt[:yesterday]
        items.delete_if do |item|
          item['date'] <= Date.today.prev_day.to_time or
            item['date'] >= Date.today.to_time
        end.reverse!
      elsif opt[:age] =~ /oldest/i
        items = items[0..count]
      else
        items = items.reverse[0..count]
      end

      items.reverse! if opt[:order] =~ /^a/i

      out = nil

      opt[:output] = 'template' unless opt[:output]

      exit_now! 'Unknown output format' unless opt[:output] =~ plugin_regex(type: :export)

      # exporter = WWIDExport.new(section, items, is_single, opt, self)
      export_options = { page_title: section, is_single: is_single, options: opt }

      plugins[:export].each do |_, options|
        next unless opt[:output] =~ /^(#{options[:trigger]})$/i

        out = options[:class].render(self, items, variables: export_options)
        break
      end

      out
    end

    def plugins
      @plugins ||= load_plugins
    end

    def load_plugins
      add_dir = @config.key?('plugin_path') ? @config['plugin_path'] : nil

      Doing::Plugins.load_plugins(add_dir)
    end

    def plugin_names(type: :export)
      plugins[type].keys.sort.join('|')
    end

    def plugin_regex(type: :export)
      pattern = []
      plugins[type].each do |_, options|
        pattern << options[:trigger]
      end
      Regexp.new("^(?:#{pattern.join('|')})$", true)
    end

    def plugin_templates(type: :export)
      templates = []
      plugs = plugins[type].clone
      plugs.delete_if { |t, o| o[:templates].nil? }.each do |_, options|
        options[:templates].each do |t|
          templates << t[:name]
        end
      end

      templates
    end

    def template_regex(type: :export)
      pattern = []
      plugs = plugins[type].clone
      plugs.delete_if { |t, o| o[:templates].nil? }.each do |_, options|
        options[:templates].each do |t|
          pattern << t[:trigger]
        end
      end
      Regexp.new("^(?:#{pattern.join('|')})$", true)
    end

    def template_for_trigger(trigger, type: :export)
      plugs = plugins[type].clone
      plugs.delete_if { |t, o| o[:templates].nil? }.each do |_, options|
        options[:templates].each do |t|
          if trigger =~ /^(?:#{t[:trigger]})$/
            puts options
            return options[:class].template(trigger)
          end
        end
      end
      exit_now! "No template type matched \"#{trigger}\""
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
        exit_now! 'Either source or destination does not exist'
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
        items = @content[section]['items'].dup

        moved_items = []
        if !tags.empty? || opt[:search] || opt[:before]
          if opt[:before]
            time_string = opt[:before]
            time_string += ' 12am' if time_string !~ /(\d+:\d+|\d+[ap])/
            cutoff = chronify(time_string)
          end

          items.delete_if do |item|
            if ((!tags.empty? && item.has_tags?(tags, bool)) || (opt[:search] && item.matches_search?(opt[:search].to_s)) || (opt[:before] && item['date'] < cutoff))
              moved_items.push(item)
              counter += 1
              true
            else
              false
            end
          end
          moved_items.each do |item|
            if label && section != @current_section
              item['title'] =
                item['title'].sub(/(?:@from\(.*?\))?(.*)$/, "\\1 @from(#{section})")
            end
          end

          @content[section]['items'] = items
          @content[destination]['items'].concat(moved_items)
          @results.push("Archived #{moved_items.length} items from #{section} to #{destination}")
        else
          count = items.length if items.length < count

          items.map! do |item|
            if label && section != @current_section
              item['title'] =
                item['title'].sub(/(?:@from\(.*?\))?(.*)$/, "\\1 @from(#{section})")
            end
            item
          end

          if items.count > count
            @content[destination]['items'].concat(items[count..-1])
          else
            @content[destination]['items'].concat(items)
          end

          @content[section]['items'] = if count.zero?
                                         []
                                       else
                                         items[0..count - 1]
                                       end

          @results.push("Archived #{items.length - count} items from #{section} to #{destination}")
        end
      end
    end

    ##
    ## @brief      A dictionary of colors
    ##
    ## @return     (String) ANSI escape sequence
    ##
    def colors
      color = {}
      color['black'] = "\033[0;0;30m"
      color['red'] = "\033[0;0;31m"
      color['green'] = "\033[0;0;32m"
      color['yellow'] = "\033[0;0;33m"
      color['blue'] = "\033[0;0;34m"
      color['magenta'] = "\033[0;0;35m"
      color['cyan'] = "\033[0;0;36m"
      color['white'] = "\033[0;0;37m"
      color['bgblack'] = "\033[40m"
      color['bgred'] = "\033[41m"
      color['bggreen'] = "\033[42m"
      color['bgyellow'] = "\033[43m"
      color['bgblue'] = "\033[44m"
      color['bgmagenta'] = "\033[45m"
      color['bgcyan'] = "\033[46m"
      color['bgwhite'] = "\033[47m"
      color['boldblack'] = "\033[1;30m"
      color['boldred'] = "\033[1;31m"
      color['boldgreen'] = "\033[0;1;32m"
      color['boldyellow'] = "\033[0;1;33m"
      color['boldblue'] = "\033[0;1;34m"
      color['boldmagenta'] = "\033[0;1;35m"
      color['boldcyan'] = "\033[0;1;36m"
      color['boldwhite'] = "\033[0;1;37m"
      color['boldbgblack'] = "\033[1;40m"
      color['boldbgred'] = "\033[1;41m"
      color['boldbggreen'] = "\033[1;42m"
      color['boldbgyellow'] = "\033[1;43m"
      color['boldbgblue'] = "\033[1;44m"
      color['boldbgmagenta'] = "\033[1;45m"
      color['boldbgcyan'] = "\033[1;46m"
      color['boldbgwhite'] = "\033[1;47m"
      color['softpurple'] = "\033[0;35;40m"
      color['hotpants'] = "\033[7;34;40m"
      color['knightrider'] = "\033[7;30;40m"
      color['flamingo'] = "\033[7;31;47m"
      color['yeller'] = "\033[1;37;43m"
      color['whiteboard'] = "\033[1;30;47m"
      color['default'] = "\033[0;39m"
      color
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

    # @brief Uses 'autotag' configuration to turn keywords into tags for time tracking.
    # Does not repeat tags in a title, and only converts the first instance of an
    # untagged keyword
    #
    # @param      text  (String) The text to tag
    #
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
                new_tag = new_tag.gsub('\\' + index.to_s, v)
                index += 1
              end
            end
            tail_tags.push(new_tag)
          end
        end
      end
      @results.push("Whitelisted tags: #{whitelisted.join(', ')}") if whitelisted.length > 0
      if tail_tags.length > 0
        tags = tail_tags.uniq.map { |t| '@' + t }.join(' ')
        @results.push("Synonym tags: #{tags}")
        text + ' ' + tags
      else
        text
      end
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
    ## @brief      Gets the entry finish date from the @done
    ##             tag
    ##
    ## @param      item  (Hash) The entry
    ##
    ## @return     (Date) finish date or nil if empty
    ##
    def get_end_date(item)
      return Time.parse(Regexp.last_match(1)) if item['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/

      nil
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
      done = nil
      start = nil

      if @interval_cache.keys.include? item['title']
        seconds = @interval_cache[item['title']]
        record_tag_times(item, seconds) if record
        return seconds > 0 ? '%02d:%02d:%02d' % fmt_time(seconds) : false
      end

      done = get_end_date(item)
      return false if done.nil?

      start = if item['title'] =~ /@start\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/
                Time.parse(Regexp.last_match(1))
              else
                item['date']
              end

      seconds = (done - start).to_i

      if record
        record_tag_times(item, seconds)
      end

      @interval_cache[item['title']] = seconds

      return seconds > 0 ? seconds : false unless formatted

      seconds > 0 ? '%02d:%02d:%02d' % fmt_time(seconds) : false
    end

    ##
    ## @brief      Record times for item tags
    ##
    ## @param      item  The item
    ##
    def record_tag_times(item, seconds)
      return if @recorded_items.include?(item)

      item['title'].scan(/(?mi)@(\S+?)(\(.*\))?(?=\s|$)/).each do |m|
        k = m[0] == 'done' ? 'All' : m[0].downcase
        if @timers.key?(k)
          @timers[k] += seconds
        else
          @timers[k] = seconds
        end
        @recorded_items.push(item)
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
    ## @param      cli   The cli
    ##
    def exec_available(cli)
      if File.exist?(File.expand_path(cli))
        File.executable?(File.expand_path(cli))
      else
        system "which #{cli}", out: File::NULL, err: File::NULL
      end
    end
  end
end
