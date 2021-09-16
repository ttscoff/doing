#!/usr/bin/ruby

require 'deep_merge'
require 'open3'
require 'pp'
require 'shellwords'

##
## @brief      Main "What Was I Doing" methods
##
class WWID
  attr_accessor :content, :sections, :current_section, :doing_file, :config, :user_home, :default_config_file,
                :config_file, :results, :auto_tag

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
  end

  ##
  ## @brief      Finds a project-specific configuration file
  ##
  ## @return     (String) A file path
  ##
  def find_local_config
    config = {}
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

    @config['html_template'] ||= {}
    @config['html_template']['haml'] ||= nil
    @config['html_template']['css'] ||= nil

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
      'wrap_width' => 88
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

    File.open(@config_file, 'w') { |yf| YAML.dump(@config, yf) } unless File.exist?(@config_file)

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
  ## @brief      Return the contents of the HAML template for HTML output
  ##
  ## @return     (String) HAML template
  ##
  def haml_template
    IO.read(File.join(File.dirname(__FILE__), '../templates/doing.haml'))
  end

  ##
  ## @brief      Return the contents of the CSS template for HTML output
  ##
  ## @return     (String) CSS template
  ##
  def css_template
    IO.read(File.join(File.dirname(__FILE__), '../templates/doing.css'))
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
    return 'All' if frag =~ /all/i

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
    default = default_response ? 'y' : 'n'

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
    item_a['date'] == item_b['date'] ? get_interval(item_a, false) == get_interval(item_b, false) : false
  end

  def overlapping_time?(item_a, item_b)
    return true if same_time?(item_a, item_b)

    start_a = item_a['date']
    interval = get_interval(item_a, false)
    end_a = interval ? start_a + interval.to_i : start_a
    start_b = item_b['date']
    interval = get_interval(item_b, false)
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
  ## @brief      Imports a Timing report
  ##
  ## @param      path     (String) Path to JSON report file
  ## @param      section  (String) The section to add to
  ## @param      opt      (Hash) Additional Options
  ##
  def import_timing(path, opt = {})
    section = opt[:section] || @current_section
    opt[:no_overlap] ||= false

    add_section(section) unless @content.has_key?(section)

    add_tags = opt[:tag] ? opt[:tag].split(/[ ,]+/).map { |t| t.sub(/^@?/, '@') }.join(' ') : ''
    prefix = opt[:prefix] ? opt[:prefix] : '[Timing.app]'
    exit_now! "File not found" unless File.exist?(File.expand_path(path))

    data = JSON.parse(IO.read(File.expand_path(path)))
    new_items = []
    data.each do |entry|
      # Only process task entries
      next if entry.key?('activityType') && entry['activityType'] != 'Task'
      # Only process entries with a start and end date
      next unless entry.key?('startDate') && entry.key?('endDate')

      # Round down seconds and convert UTC to local time
      start_time = Time.parse(entry['startDate'].sub(/:\d\dZ$/, ':00Z')).getlocal
      end_time = Time.parse(entry['endDate'].sub(/:\d\dZ$/, ':00Z')).getlocal
      next unless start_time && end_time

      tags = entry['project'].split(/ ▸ /).map {|proj| proj.gsub(/[^a-z0-9]+/i, '').downcase }
      title = "#{prefix} "
      title += entry.key?('activityTitle') && entry['activityTitle'] != '(Untitled Task)' ? entry['activityTitle'] : 'Working on'
      tags.each do |tag|
        if title =~ /\b#{tag}\b/i
          title.sub!(/\b#{tag}\b/i, "@#{tag}")
        else
          title += " @#{tag}"
        end
      end
      title = autotag(title) if @auto_tag
      title += " @done(#{end_time.strftime('%Y-%m-%d %H:%M')})"
      title.gsub!(/ +/, ' ')
      title.strip!
      new_entry = { 'title' => title, 'date' => start_time, 'section' => section }
      new_entry['note'] = entry['notes'].split(/\n/).map(&:chomp) if entry.key?('notes')
      new_items.push(new_entry)
    end
    total = new_items.count
    new_items = dedup(new_items, opt[:no_overlap])
    dups = total - new_items.count
    @results.push(%(Skipped #{dups} items with overlapping times)) if dups > 0
    @content[section]['items'].concat(new_items)
    @results.push(%(Imported #{new_items.count} items to #{section}))
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

    if opt[:tag] && opt[:tag].length.positive?
      all_items.select! { |item| item.has_tags?(opt[:tag], opt[:tag_bool]) }
    elsif opt[:search]&.length
      all_items.select! { |item| item.matches_search?(opt[:search]) }
    end

    all_items.max_by { |item| item['date'] }
  end


  ##
  ## @brief      Display an interactive menu of entries
  ##
  ## @param      opt   (Hash) Additional options
  ##
  def interactive(opt = {})
    exit_now! "Select command requires that fzf be installed" unless exec_available('fzf')

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
        item['title'],
      ]
      if opt[:section] =~ /^all/i
        out.concat([
          ' (',
          item['section'],
          ') '
        ])
      end
      out.join('')
    end

    res = `echo #{Shellwords.escape(options.join("\n"))}|fzf -m --bind ctrl-a:select-all`
    selected = []
    res.split(/\n/).each do |item|
      idx = item.match(/^(\d+)\)/)[1].to_i
      selected.push(items[idx])
    end

    if selected.empty?
      @results.push("No selection")
      return
    end

    if opt[:delete]
      res = yn("Delete #{selected.size} items?", default_response: 'y')
      if res
        selected.each {|item| delete_item(item) }
        write(@doing_file)
      end
      return
    end

    if opt[:flag]
      tag = @config['marker_tag'] || 'flagged'
      selected.map! {|item| tag_item(item, tag, date: false) }
    end

    if opt[:finish] || opt[:cancel]
      tag = 'done'
      selected.map! {|item| tag_item(item, tag, date: !opt[:cancel])}
    end

    if opt[:tag]
      tag = opt[:tag]
      selected.map! {|item| tag_item(item, tag, date: false)}
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
        next_start = Time.now
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
                done_date = next_start - 1
                next_start = item['date']
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
                if opt[:remove]
                  if title =~ /@#{tag}\b/
                    title.gsub!(/(^| )@#{tag}(\([^)]*\))?/, '')
                    @results.push(%(Removed @#{tag}: "#{title}" in #{section}))
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
  ## @brief      Tag an item from the index
  ##
  ## @param      old_item  (Item) The item to tag
  ## @param      tag       (string) The tag to apply
  ## @param      date      (Boolean) Include timestamp?
  ##
  def tag_item(old_item, tag, date: false)
    title = old_item['title'].dup
    done_date = Time.now
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
  def write(file = nil)
    output = @other_content_top ? "#{@other_content_top.join("\n")}\n" : ''

    @content.each do |title, section|
      output += "#{section['original']}\n"
      output += list_section({ section: title, template: "\t- %date | %title%note", highlight: false })
    end
    output += @other_content_bottom.join("\n") unless @other_content_bottom.nil?
    if file.nil?
      $stdout.puts output
    else
      file = File.expand_path(file)
      if File.exist?(file)
        # Create a backup copy for the undo command
        FileUtils.cp(file, "#{file}~")

        File.open(file, 'w+') do |f|
          f.puts output
        end
      end

      if @config.key?('run_after')
        stdout, stderr, status = Open3.capture3(@config['run_after'])
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
  ## @brief      Generate a menu of sections and allow user selection
  ##
  ## @return     (String) The selected section name
  ##
  def choose_section
    sections.each_with_index do |section, i|
      puts format('% 3d: %s', i + 1, section)
    end
    print "#{colors['green']}> #{colors['default']}"
    num = STDIN.gets
    return false if num =~ /^[a-z ]*$/i

    sections[num.to_i - 1]
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
    views.each_with_index do |view, i|
      puts format('% 3d: %s', i + 1, view)
    end
    print '> '
    num = STDIN.gets
    return false if num =~ /^[a-z ]*$/i

    views[num.to_i - 1]
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
    opt[:section] ||= nil
    opt[:format] ||= @default_date_format
    opt[:template] ||= @default_template
    opt[:age] ||= 'newest'
    opt[:order] ||= 'desc'
    opt[:today] ||= false
    opt[:tag_filter] ||= false
    opt[:tags_color] ||= false
    opt[:times] ||= false
    opt[:totals] ||= false
    opt[:sort_tags] ||= false
    opt[:search] ||= false
    opt[:only_timed] ||= false
    opt[:date_filter] ||= []

    # opt[:highlight] ||= true
    section = ''
    if opt[:section].nil?
      section = choose_section
      opt[:section] = @content[section]
    elsif opt[:section].instance_of?(String)
      if opt[:section] =~ /^all$/i
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
        get_interval(item) == false
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

    out = ''

    exit_now! 'Unknown output format' if opt[:output] && (opt[:output] !~ /^(template|html|csv|json|timeline)$/i)

    case opt[:output]
    when /^csv$/i
      output = [CSV.generate_line(%w[date title note timer section])]
      items.each do |i|
        note = ''
        if i['note']
          arr = i['note'].map { |line| line.strip }.delete_if { |e| e =~ /^\s*$/ }
          note = arr.join("\n") unless arr.nil?
        end
        interval = get_interval(i, false) if i['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
        interval ||= 0
        output.push(CSV.generate_line([i['date'], i['title'], note, interval, i['section']]))
      end
      out = output.join('')
    when /^(json|timeline)/i
      items_out = []
      max = items[-1]['date'].strftime('%F')
      min = items[0]['date'].strftime('%F')
      items.each_with_index do |i, index|
        if String.method_defined? :force_encoding
          title = i['title'].force_encoding('utf-8')
          note = i['note'].map { |line| line.force_encoding('utf-8').strip } if i['note']
        else
          title = i['title']
          note = i['note'].map { |line| line.strip } if i['note']
        end
        if i['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
          end_date = Time.parse(Regexp.last_match(1))
          interval = get_interval(i, false)
        end
        end_date ||= ''
        interval ||= 0
        note ||= ''

        tags = []
        skip_tags = %w[meanwhile done cancelled flagged]
        i['title'].scan(/@([^(\s]+)(?:\((.*?)\))?/).each do |tag|
          tags.push(tag[0]) unless skip_tags.include?(tag[0])
        end
        if opt[:output] == 'json'

          items_out << {
            date: i['date'],
            end_date: end_date,
            title: title.strip, #+ " #{note}"
            note: note.instance_of?(Array) ? note.map(&:strip).join("\n") : note,
            time: '%02d:%02d:%02d' % fmt_time(interval),
            tags: tags
          }

        elsif opt[:output] == 'timeline'
          new_item = {
            'id' => index + 1,
            'content' => title.strip, #+ " #{note}"
            'title' => title.strip + " (#{'%02d:%02d:%02d' % fmt_time(interval)})",
            'start' => i['date'].strftime('%F %T'),
            'type' => 'point'
          }

          if interval && interval.to_i > 0
            new_item['end'] = end_date.strftime('%F %T')
            new_item['type'] = 'range' if interval.to_i > 3600 * 3
          end
          items_out.push(new_item)
        end
      end
      if opt[:output] == 'json'
        out = {
          'section' => section,
          'items' => items_out,
          'timers' => tag_times('json', opt[:sort_tags])
        }.to_json
      elsif opt[:output] == 'timeline'
        template = <<~EOTEMPLATE
                    <!doctype html>
                    <html>
                    <head>
                      <link href="https://unpkg.com/vis-timeline@7.4.9/dist/vis-timeline-graph2d.min.css" rel="stylesheet" type="text/css" />
                      <script src="https://unpkg.com/vis-timeline@7.4.9/dist/vis-timeline-graph2d.min.js"></script>
                    </head>
                    <body>
                      <div id="mytimeline"></div>
          #{'          '}
                      <script type="text/javascript">
                        // DOM element where the Timeline will be attached
                        var container = document.getElementById('mytimeline');
          #{'          '}
                        // Create a DataSet with data (enables two way data binding)
                        var data = new vis.DataSet(#{items_out.to_json});
          #{'          '}
                        // Configuration for the Timeline
                        var options = {
                          width: '100%',
                          height: '800px',
                          margin: {
                            item: 20
                          },
                          stack: true,
                          min: '#{min}',
                          max: '#{max}'
                        };
          #{'          '}
                        // Create a Timeline
                        var timeline = new vis.Timeline(container, data, options);
                      </script>
                    </body>
                    </html>
        EOTEMPLATE
        return template
      end
    when /^html$/i
      page_title = section
      items_out = []
      items.each do |i|
        # if i.has_key?('note')
        #   note = '<span class="note">' + i['note'].map{|n| n.strip }.join('<br>') + '</span>'
        # else
        #   note = ''
        # end
        if String.method_defined? :force_encoding
          title = i['title'].force_encoding('utf-8').link_urls
          note = i['note'].map { |line| line.force_encoding('utf-8').strip.link_urls } if i['note']
        else
          title = i['title'].link_urls
          note = i['note'].map { |line| line.strip.link_urls } if i['note']
        end

        interval = get_interval(i) if i['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
        interval ||= false

        items_out << {
          date: i['date'].strftime('%a %-I:%M%p'),
          title: title.gsub(/(@[^ (]+(\(.*?\))?)/im, '<span class="tag">\1</span>').strip, #+ " #{note}"
          note: note,
          time: interval,
          section: i['section']
        }
      end

      template = if @config['html_template']['haml'] && File.exist?(File.expand_path(@config['html_template']['haml']))
                   IO.read(File.expand_path(@config['html_template']['haml']))
                 else
                   haml_template
                 end

      style = if @config['html_template']['css'] && File.exist?(File.expand_path(@config['html_template']['css']))
                IO.read(File.expand_path(@config['html_template']['css']))
              else
                css_template
              end

      totals = opt[:totals] ? tag_times('html', opt[:sort_tags]) : ''
      engine = Haml::Engine.new(template)
      puts engine.render(Object.new,
                         { :@items => items_out, :@page_title => page_title, :@style => style, :@totals => totals })
    else
      items.each do |item|
        if opt[:highlight] && item['title'] =~ /@#{@config['marker_tag']}\b/i
          flag = colors[@config['marker_color']]
          reset = colors['default']
        else
          flag = ''
          reset = ''
        end

        if (item.has_key?('note') && !item['note'].empty?) && @config[:include_notes]
          note_lines = item['note'].delete_if do |line|
                         line =~ /^\s*$/
                       end.map { |line| "\t\t" + line.sub(/^\t*/, '').sub(/^-/, '—') + '  ' }
          if opt[:wrap_width] && opt[:wrap_width] > 0
            width = opt[:wrap_width]
            note_lines.map! do |line|
              line.strip.gsub(/(.{1,#{width}})(\s+|\Z)/, "\t\\1\n")
            end
          end
          note = "\n#{note_lines.join("\n").chomp}"
        else
          note = ''
        end
        output = opt[:template].dup

        output.gsub!(/%[a-z]+/) do |m|
          if colors.has_key?(m.sub(/^%/, ''))
            colors[m.sub(/^%/, '')]
          else
            m
          end
        end

        output.sub!(/%date/, item['date'].strftime(opt[:format]))

        interval = get_interval(item) if item['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
        interval ||= ''
        output.sub!(/%interval/, interval)

        output.sub!(/%shortdate/) do
          if item['date'] > Date.today.to_time
            item['date'].strftime('%_I:%M%P')
          elsif item['date'] > (Date.today - 7).to_time
            item['date'].strftime('%a %-I:%M%P')
          elsif item['date'].year == Date.today.year
            item['date'].strftime('%b %d, %-I:%M%P')
          else
            item['date'].strftime('%b %d %Y, %-I:%M%P')
          end
        end

        output.sub!(/%title/) do |_m|
          if opt[:wrap_width] && opt[:wrap_width] > 0
            flag + item['title'].gsub(/(.{1,#{opt[:wrap_width]}})(\s+|\Z)/, "\\1\n\t ").chomp + reset
          else
            flag + item['title'].chomp + reset
          end
        end

        output.sub!(/%section/, item['section']) if item['section']

        if opt[:tags_color]
          escapes = output.scan(/(\e\[[\d;]+m)[^\e]+@/)
          last_color = if escapes.length > 0
                         escapes[-1][0]
                       else
                         colors['default']
                       end
          output.gsub!(/(\s|m)(@[^ (]+)/, "\\1#{colors[opt[:tags_color]]}\\2#{last_color}")
        end
        output.sub!(/%note/, note)
        output.sub!(/%odnote/, note.gsub(/^\t*/, ''))
        output.sub!(/%chompnote/, note.gsub(/\n+/, ' ').gsub(/(^\s*|\s*$)/, '').gsub(/\s+/, ' '))
        output.gsub!(/%hr(_under)?/) do |_m|
          o = ''
          `tput cols`.to_i.times do
            o += Regexp.last_match(1).nil? ? '-' : '_'
          end
          o
        end
        output.gsub!(/%n/, "\n")
        output.gsub!(/%t/, "\t")

        out += "#{output}\n"
      end
      out += tag_times('text', opt[:sort_tags]) if opt[:totals]
    end
    out
  end

  ##
  ## @brief      Move entries from a section to Archive or other specified
  ##             section
  ##
  ## @param      section      (String) The source section
  ## @param      options      (Hash) Options
  ##
  def archive(section = 'Currently', options = {})
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
      do_archive(section, destination, { count: count, tags: tags, bool: bool, search: options[:search], label: options[:label] })
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
      if !tags.empty? || opt[:search]
        items.delete_if do |item|
          if (!tags.empty? && item.has_tags?(tags, bool) || (opt[:search] && item.matches_search?(opt[:search].to_s)))
            moved_items.push(item)
            counter += 1
            true
          else
            false
          end
        end
        moved_items.each do |item|
          if label && section != 'Currently'
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
          if label && section != 'Currently'
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
    list_section({ section: opt[:section], wrap_width: cfg['wrap_width'], count: 0,
                   format: cfg['date_format'], template: cfg['template'], order: 'asc', today: true, times: times, output: output, totals: opt[:totals], sort_tags: opt[:sort_tags] })
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
    list_section({ section: section, count: 0, order: 'asc', yesterday: true, times: times,
                   output: output, totals: opt[:totals], sort_tags: opt[:sort_tags] })
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
  ## @brief      Get total elapsed time for all tags in selection
  ##
  ## @param      format  (String) return format (html, json, or text)
  ##
  def tag_times(format = 'text', sort_by_name = false)
    return '' if @timers.empty?

    max = @timers.keys.sort_by { |k| k.length }.reverse[0].length + 1

    total = @timers.delete('All')

    tags_data = @timers.delete_if { |_k, v| v == 0 }
    sorted_tags_data = if sort_by_name
                         tags_data.sort_by { |k, _v| k }.reverse
                       else
                         tags_data.sort_by { |_k, v| v }
                       end

    if format == 'html'
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
    elsif format == 'json'
      output = []
      sorted_tags_data.reverse.each do |k, v|
        output << {
          'tag' => k,
          'seconds' => v,
          'formatted' => '%02d:%02d:%02d' % fmt_time(v)
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
        output.push("#{k}:#{spacer}#{'%02d:%02d:%02d' % fmt_time(v)}")
      end

      output = output.empty? ? '' : "\n--- Tag Totals ---\n" + output.join("\n")
      output += "\n\nTotal tracked: #{'%02d:%02d:%02d' % fmt_time(total)}\n"
      output
    end
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

  private

  ##
  ## @brief      Gets the interval between entry's start date and @done date
  ##
  ## @param      item       (Hash) The entry
  ## @param      formatted  (Bool) Return human readable time (default seconds)
  ##
  def get_interval(item, formatted = true)
    done = nil
    start = nil

    if @interval_cache.keys.include? item['title']
      seconds = @interval_cache[item['title']]
      return seconds > 0 ? '%02d:%02d:%02d' % fmt_time(seconds) : false
    end

    if item['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/
      done = Time.parse(Regexp.last_match(1))
    else
      return nil
    end

    start = if item['title'] =~ /@start\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/
              Time.parse(Regexp.last_match(1))
            else
              item['date']
            end

    seconds = (done - start).to_i

    item['title'].scan(/(?mi)@(\S+?)(\(.*\))?(?=\s|$)/).each do |m|
      k = m[0] == 'done' ? 'All' : m[0].downcase
      if @timers.has_key?(k)
        @timers[k] += seconds
      else
        @timers[k] = seconds
      end
    end

    @interval_cache[item['title']] = seconds

    return seconds unless formatted

    seconds > 0 ? '%02d:%02d:%02d' % fmt_time(seconds) : false
  end

  ##
  ## @brief      Format human readable time from seconds
  ##
  ## @param      seconds  The seconds
  ##
  def fmt_time(seconds)
    return [0, 0, 0] if seconds.nil?

    if seconds =~ /(\d+):(\d+):(\d+)/
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

  def exec_available(cli)
    if File.exists?(File.expand_path(cli))
      File.executable?(File.expand_path(cli))
    else
      system "which #{cli}", :out => File::NULL, :err => File::NULL
    end
  end
end
