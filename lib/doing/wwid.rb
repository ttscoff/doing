#!/usr/bin/ruby

require 'deep_merge'
require 'pp'

##
## @brief      String helpers
##
class String
  def cap_first
    self.sub(/^\w/) do |m|
      m.upcase
    end
  end

  ##
  ## @brief      Turn raw urls into HTML links
  ##
  ## @param      opt   (Hash) Additional Options
  ##
  def link_urls(opt={})
    opt[:format] ||= :html
    if opt[:format] == :html
      self.gsub(/(?mi)((http|https):\/\/)?([\w\-_]+(\.[\w\-_]+)+)([\w\-\.,\@?^=%&amp;:\/~\+#]*[\w\-\@^=%&amp;\/~\+#])?/) {|match|
        m = Regexp.last_match
        proto = m[1].nil? ? "http://" : ""
        %Q{<a href="#{proto}#{m[0]}" title="Link to #{m[0]}">[#{m[3]}]</a>}
      }.gsub(/\<(\w+:.*?)\>/) {|match|
        m = Regexp.last_match
        unless m[1] =~ /<a href/
          %Q{<a href="#{m[1]}" title="Link to #{m[1]}">[link]</a>}
        else
          match
        end
      }
    else
      self
    end
  end
end

##
## @brief      Main "What Was I Doing" methods
##
class WWID
  attr_accessor :content, :sections, :current_section, :doing_file, :config, :user_home, :default_config_file, :results

  ##
  ## @brief      Initializes the object.
  ##
  def initialize
    @content = {}
    @doingrc_needs_update = false
    @default_config_file = '.doingrc'
  end

  ##
  ## @brief      Read user configuration and merge with defaults
  ##
  ## @param      opt   (Hash) Additional Options
  ##
  def configure(opt={})
    @timers = {}
    @config_file == File.join(@user_home, @default_config_file)

    read_config

    user_config = @config.dup
    @results = []

    @config['autotag'] ||= {}
    @config['autotag']['whitelist'] ||= []
    @config['autotag']['synonyms'] ||= {}
    @config['doing_file'] ||= "~/what_was_i_doing.md"
    @config['current_section'] ||= 'Currently'
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
          'order' => "asc"
      }
    }
    @config['marker_tag'] ||= 'flagged'
    @config['marker_color'] ||= 'red'
    @config['default_tags'] ||= []

    @current_section = config['current_section']
    @default_template = config['templates']['default']['template']
    @default_date_format = config['templates']['default']['date_format']

    @config[:include_notes] ||= true

    File.open(@config_file, 'w') { |yf| YAML::dump(@config, yf) } unless @config == user_config

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
  def init_doing_file(path=nil)
    @doing_file = File.expand_path(@config['doing_file'])

    input = path

    if input.nil?
      create(@doing_file) unless File.exists?(@doing_file)
      input = IO.read(@doing_file)
      input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
    elsif File.exists?(File.expand_path(input)) && File.file?(File.expand_path(input)) && File.stat(File.expand_path(input)).size > 0
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

    section = "Uncategorized"
    lines = input.split(/[\n\r]/)
    current = 0

    lines.each {|line|
      next if line =~ /^\s*$/
      if line =~ /^(\S[\S ]+):\s*(@\S+\s*)*$/
        section = $1
        @content[section] = {}
        @content[section]['original'] = line
        @content[section]['items'] = []
        current = 0
      elsif line =~ /^\s*- (\d{4}-\d\d-\d\d \d\d:\d\d) \| (.*)/
        date = Time.parse($1)
        title = $2
        @content[section]['items'].push({'title' => title, 'date' => date, 'section' => section})
        current += 1
      else
        # if content[section]['items'].length - 1 == current
          if current == 0
            @other_content_top.push(line)
          else
            if line =~ /^\S/
              @other_content_bottom.push(line)
            else
              unless @content[section]['items'][current - 1].has_key? 'note'
                @content[section]['items'][current - 1]['note'] = []
              end
              @content[section]['items'][current - 1]['note'].push(line.gsub(/ *$/,''))
            end
          end
        # end
      end
    }
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
  def create(filename=nil)
    if filename.nil?
      filename = @doing_file
    end
    unless File.exists?(filename) && File.stat(filename).size > 0
      File.open(filename,'w+') do |f|
        f.puts @current_section + ":"
      end
    end
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

    while (dir != '/' && (dir =~ /[A-Z]:\//) == nil)
      if File.exists? File.join(dir, @default_config_file)
        local_config_files.push(File.join(dir, @default_config_file))
      end

      dir = File.dirname(dir)
    end

    local_config_files
  end

  ##
  ## @brief      Reads a configuration.
  ##
  def read_config
    if Dir.respond_to?('home')
      @config_file = File.join(Dir.home, @default_config_file)
    else
      @config_file = File.join(File.expand_path("~"), @default_config_file)
    end
    # @doingrc_needs_update = true if File.exists? @config_file
    additional_configs = find_local_config

    begin
      @local_config = {}

      @config = YAML.load_file(@config_file) || {} if File.exists?(@config_file)
      additional_configs.each { |cfg|
        new_config = YAML.load_file(cfg) || {} if cfg
        @local_config = @local_config.deep_merge(new_config)
      }

      # @config.deep_merge(@local_config)
    rescue
      @config = {}
      @local_config = {}
      # raise "error reading config"
    end
  end

  ##
  ## @brief      Create a process for an editor and wait for the file handle to return
  ##
  ## @param      input  (String) Text input for editor
  ##
  def fork_editor(input="")
    tmpfile = Tempfile.new(['doing','.md'])

    File.open(tmpfile.path,'w+') do |f|
      f.puts input
      f.puts "\n# The first line is the entry title, any lines after that are added as a note"
    end

    pid = Process.fork { system("$EDITOR #{tmpfile.path}") }

    trap("INT") {
      Process.kill(9, pid) rescue Errno::ESRCH
      tmpfile.unlink
      tmpfile.close!
      exit 0
    }

    Process.wait(pid)

    begin
      if $?.exitstatus == 0
        input = IO.read(tmpfile.path)
      else
        raise "Cancelled"
      end
    ensure
      tmpfile.close
      tmpfile.unlink
    end

    input
  end

  #
  # @brief      Takes a multi-line string and formats it as an entry
  #
  # @return     (Array) [(String)title, (Array)note]
  #
  # @param      input  (String) The string to parse
  #
  def format_input(input)
    raise "No content in entry" if input.nil? || input.strip.length == 0
    input_lines = input.split(/[\n\r]+/)
    title = input_lines[0].strip
    note = input_lines.length > 1 ? input_lines[1..-1] : []
    note.map! { |line|
      line.strip
    }.delete_if { |line|
      line =~ /^\s*$/ || line =~ /^#/
    }

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
    raise "Invalid time expression #{input.inspect}" if input.to_s.strip == ""
    secs_ago = if input.match /^(\d+)$/
      # plain number, assume minutes
      $1.to_i * 60
    elsif (m = input.match /^((?<day>\d+)d)?((?<hour>\d+)h)?((?<min>\d+)m)?$/i)
      # day/hour/minute format e.g. 1d2h30m
      [[m['day'], 24*3600],
       [m['hour'], 3600],
       [m['min'], 60]].map {|qty, secs| qty ? (qty.to_i * secs) : 0 }.reduce(0, :+)
    end

    if secs_ago
      now - secs_ago
    else
      Chronic.parse(input, {:context => :past, :ambiguous_time_range => 8})
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
    if qty.strip =~ /^(\d+):(\d\d)$/
      minutes += $1.to_i * 60
      minutes += $2.to_i
    elsif qty.strip =~ /^(\d+)([hmd])?$/
      amt = $1
      type = $2.nil? ? "m" : $2

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
    @content[title.cap_first] = {'original' => "#{title}:", 'items' => []}
    @results.push(%Q{Added section "#{title.cap_first}"})
  end

  ##
  ## @brief      Attempt to match a string with an existing section
  ##
  ## @param      frag     (String) The user-provided string
  ## @param      guessed  (Boolean) already guessed and failed
  ##
  def guess_section(frag,guessed=false)
    return "All" if frag =~ /all/i
    sections.each {|section| return section.cap_first if frag.downcase == section.downcase }
    section = false
    re = frag.split('').join(".*?")
    sections.each {|sect|
      if sect =~ /#{re}/i
        $stderr.puts "Assuming you meant #{sect}"
        section = sect
        break
      end
    }
    unless section || guessed
      alt = guess_view(frag,true)
      if alt
        raise "Did you mean `doing view #{alt}`?"
      else
        res = yn("Section #{frag} not found, create it",false)

        if res
          add_section(frag.cap_first)
          write(@doing_file)
          return frag.cap_first
        end
        raise "Unknown section: #{frag}"
      end
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
  def yn(question, default_response=false)
    if default_response
      default = 'y'
    else
      default = 'n'
    end
    # if this isn't an interactive shell, answer default
    unless $stdout.isatty
      if default.downcase == 'y'
        return true
      else
        return false
      end
    end
    # clear the buffer
    if ARGV.length
      ARGV.length.times do
        ARGV.shift
      end
    end
    system 'stty cbreak'
    if default
      if default =~ /y/i
        options = "#{colors['white']}[#{colors['boldgreen']}Y#{colors['white']}/#{colors['boldwhite']}n#{colors['white']}]#{colors['default']}"
      else
        options = "#{colors['white']}[#{colors['boldwhite']}y#{colors['white']}/#{colors['boldgreen']}N#{colors['white']}]#{colors['default']}"
      end
    else
      options = "#{colors['white']}[#{colors['boldwhite']}y#{colors['white']}/#{colors['boldwhite']}n#{colors['white']}]#{colors['default']}"
    end
    $stdout.syswrite "#{colors['boldwhite']}#{question.sub(/\?$/,'')} #{options}#{colors['boldwhite']}?#{colors['default']} "
    res = $stdin.sysread 1
    puts
    system 'stty cooked'

    res.chomp!
    res.downcase!

    res = default.downcase if res == ""

    return res =~ /y/i
  end

  ##
  ## @brief      Attempt to match a string with an existing view
  ##
  ## @param      frag     (String) The user-provided string
  ## @param      guessed  (Boolean) already guessed
  ##
  def guess_view(frag,guessed=false)
    views.each {|view| return view if frag.downcase == view.downcase}
    view = false
    re = frag.split('').join(".*?")
    views.each {|v|
      if v =~ /#{re}/i
        $stderr.puts "Assuming you meant #{v}"
        view = v
        break
      end
    }
    unless view || guessed
      alt = guess_section(frag,true)
      if alt
        raise "Did you mean `doing show #{alt}`?"
      else
        raise "Unknown view: #{frag}"
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
  def add_item(title,section=nil,opt={})
    section ||= @current_section
    add_section(section) unless @content.has_key?(section)
    opt[:date] ||= Time.now
    opt[:note] ||= []
    opt[:back] ||= Time.now
    opt[:timed] ||= false

    title = [title.strip.cap_first]
    title = autotag(title.join(' '))
    unless @config['default_tags'].empty?
      title += @config['default_tags'].map{|t|
        unless t.nil?
          dt = t.sub(/^ *@/,'').chomp
          if title =~ /@#{dt}/
            ""
          else
            ' @' + dt
          end
        end
      }.delete_if {|t| t == "" }.join(" ")
    end
    entry = {'title' => title.strip, 'date' => opt[:back]}
    unless opt[:note] =~ /^\s*$/s
      entry['note'] = opt[:note].map {|n| n.gsub(/ *$/,'')}
    end
    items = @content[section]['items']
    if opt[:timed]
      items.reverse!
      items.each_with_index {|i,x|
        if i['title'] =~ / @done/
          next
        else
          items[x]['title'] = "#{i['title']} @done(#{opt[:back].strftime('%F %R')})"
          break
        end
      }
      items.reverse!
    end
    items.push(entry)
    @content[section]['items'] = items
    @results.push(%Q{Added "#{entry['title']}" to #{section}})
  end

  ##
  ## @brief      Return the content of the last note for a given section
  ##
  ## @param      section  (String) The section to retrieve from, default
  ##                      Currently
  ##
  def last_note(section=@current_section)
    section = guess_section(section)
    if @content.has_key?(section)
      last_item = @content[section]['items'].dup.sort_by{|item| item['date'] }.reverse[0]
      $stderr.puts "Editing note for #{last_item['title']}"
      return "#{last_item['title']}\n# EDIT BELOW THIS LINE ------------\n#{last_item['note'].map{|line| line.strip }.join("\n")}"
    else
      raise "Section #{section} not found"
    end
  end

  ##
  ## @brief      Tag the last entry or X entries
  ##
  ## @param      opt   (Hash) Additional Options
  ##
  def tag_last(opt={})
    opt[:section] ||= @current_section
    opt[:count] ||= 1
    opt[:archive] ||= false
    opt[:tags] ||= ["done"]
    opt[:sequential] ||= false
    opt[:date] ||= false
    opt[:remove] ||= false
    opt[:autotag] ||= false
    opt[:back] ||= false


    sec_arr = []

    if opt[:section].nil?
      sec_arr = [@current_section]
    elsif opt[:section].class == String
      if opt[:section] =~ /^all$/i
        sec_arr = sections
      else
        sec_arr = [guess_section(opt[:section])]
      end
    end

    sec_arr.each {|section|
      if @content.has_key?(section)

        items = @content[section]['items'].dup.sort_by{|item| item['date'] }.reverse

        index = 0
        done_date = Time.now
        next_start = Time.now
        count = opt[:count] == 0 ? items.length : opt[:count]
        items.map! {|item|
          break if index == count

          unless opt[:autotag]
            if opt[:sequential]
              done_date = next_start - 1
              next_start = item['date']
            elsif opt[:back]
              done_date = item['date'] + (opt[:back] - item['date'])
            else
              done_date = Time.now
            end

            title = item['title']
            opt[:tags].each {|tag|
              tag.strip!
              if opt[:remove]
                if title =~ /@#{tag}/
                  title.gsub!(/(^| )@#{tag}(\([^\)]*\))?/,'')
                  @results.push("Removed @#{tag}: #{title}")
                end
              else
                unless title =~ /@#{tag}/
                  title.chomp!
                  if opt[:date]
                    title += " @#{tag}(#{done_date.strftime('%F %R')})"
                  else
                    title += " @#{tag}"
                  end
                  @results.push("Added @#{tag}: #{title}")
                end
              end
            }
            item['title'] = title
          else
            item['title'] = autotag(item['title'])
          end

          index += 1

          item
        }

        @content[section]['items'] = items

        if opt[:archive] && section != "Archive" && opt[:count] > 0
          # concat [count] items from [section] and archive section
          archived = @content[section]['items'][0..opt[:count]-1].map {|i|
            i['title'].sub(/(?:@from\(.*?\))?(.*)$/,"\\1 @from(#{i['section']})")
          }.concat(@content['Archive']['items'])
          # chop [count] items off of [section] items
          @content[opt[:section]]['items'] = @content[opt[:section]]['items'][opt[:count]..-1]
          # overwrite archive section with concatenated array
          @content['Archive']['items'] = archived
          # log it
          result = opt[:count] == 1 ? "1 entry" : "#{opt[:count]} entries"
          @results.push("Archived #{result}")
        elsif opt[:archive] && opt[:count] == 0
          @results.push("Archiving is skipped when operating on all entries") if opt[:count] == 0
        end
      else
        raise "Section not found: #{section}"
      end
    }

    write(@doing_file)
  end

  ##
  ## @brief      Add a note to the last entry in a section
  ##
  ## @param      section  (String) The section, default Currently
  ## @param      note     (String) The note to add
  ## @param      replace  (Bool) Should replace existing note
  ##
  def note_last(section, note, replace=false)
    section = guess_section(section)

    if @content.has_key?(section)
      # sort_section(opt[:section])
      items = @content[section]['items'].dup.sort_by{|item| item['date'] }.reverse

      current_note = items[0]['note']
      current_note = [] if current_note.nil?
      title = items[0]['title']
      if replace
        items[0]['note'] = note
        if note.empty? && !current_note.empty?
          @results.push(%Q{Removed note from "#{title}"})
        elsif current_note.length > 0 && note.length > 0
          @results.push(%Q{Replaced note from "#{title}"})
        elsif note.length > 0
          @results.push(%Q{Added note to #{title}})
        else
          @results.push(%Q{Entry "#{title}" has no note})
        end
      elsif current_note.class == Array
        items[0]['note'] = current_note.concat(note)
        @results.push(%Q{Added note to "#{title}"}) if note.length > 0
      else
        items[0]['note'] = note
        @results.push(%Q{Added note to "#{title}"}) if note.length > 0
      end

      @content[section]['items'] = items
    else
      raise "Section not found"
    end
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
  def stop_start(tag,opt={})
    opt[:section] ||= @current_section
    opt[:archive] ||= false
    opt[:back] ||= Time.now
    opt[:new_item] ||= false
    opt[:note] ||= false

    opt[:section] = guess_section(opt[:section])

    tag.sub!(/^@/,'')

    found_items = 0
    begin
    @content[opt[:section]]['items'].each_with_index {|item, i|
      if item['title'] =~ /@#{tag}/
        title = item['title'].gsub(/(^| )@(#{tag}|done)(\([^\)]*\))?/,'')
        title += " @done(#{opt[:back].strftime('%F %R')})"

        @content[opt[:section]]['items'][i]['title'] = title
        found_items += 1

        if opt[:archive] && opt[:section] != "Archive"
          @results.push(%Q{Completed and archived "#{@content[opt[:section]]['items'][i]['title']}"})
          archive_item = @content[opt[:section]]['items'][i]
          archive_item['title'] = i['title'].sub(/(?:@from\(.*?\))?(.*)$/,"\\1 @from(#{i['section']})")
          @content['Archive']['items'].push(archive_item)
          @content[opt[:section]]['items'].delete_at(i)
        else
          @results.push(%Q{Completed "#{@content[opt[:section]]['items'][i]['title']}"})
        end
      end
    }

    @results.push("No active @#{tag} tasks found.") if found_items == 0

    if opt[:new_item]
      title, note = format_input(opt[:new_item])
      note.push(opt[:note].gsub(/ *$/,'')) if opt[:note]
      title += " @#{tag}"
      add_item(title.cap_first, opt[:section], {:note => note.join(' ').rstrip, :back => opt[:back]})
    end

    rescue Exception=>e
      puts e
      puts e.backtrace
    end


    write(@doing_file)
  end

  ##
  ## @brief      Write content to file or STDOUT
  ##
  ## @param      file  (String) The filepath to write to
  ##
  def write(file=nil)
    unless @other_content_top
      output = ""
    else
      output = @other_content_top.join("\n") + "\n"
    end
    @content.each {|title, section|
      output += section['original'] + "\n"
      output += list_section({:section => title, :template => "\t- %date | %title%note", :highlight => false})
    }
    output += @other_content_bottom.join("\n") unless @other_content_bottom.nil?
    if file.nil?
      $stdout.puts output
    else
      if File.exists?(File.expand_path(file))
        # Create a backup copy for the undo command
        FileUtils.cp(file,file+"~")

        File.open(File.expand_path(file),'w+') do |f|
          f.puts output
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
    if File.exists?(file+"~")
      puts file+"~"
      FileUtils.cp(file+"~",file)
      @results.push("Restored #{file}")
    end
  end


  ##
  ## @brief      Generate a menu of sections and allow user selection
  ##
  ## @return     (String) The selected section name
  ##
  def choose_section
    sections.each_with_index {|section, i|
      puts "% 3d: %s" % [i+1, section]
    }
    print "> "
    num = STDIN.gets
    return false if num =~ /^[a-z ]*$/i
    return sections[num.to_i - 1]
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
    views.each_with_index {|view, i|
      puts "% 3d: %s" % [i+1, view]
    }
    print "> "
    num = STDIN.gets
    return false if num =~ /^[a-z ]*$/i
    return views[num.to_i - 1]
  end

  ##
  ## @brief      Gets a view from configuration
  ##
  ## @param      title  (String) The title of the view to retrieve
  ##
  def get_view(title)
    if @config['views'].has_key?(title)
      return @config['views'][title]
    end
    false
  end

  ##
  ## @brief      Overachieving function for displaying contents of a section.
  ##             This is a fucking mess. I mean, Jesus Christ.
  ##
  ## @param      opt   (Hash) Additional Options
  ##
  def list_section(opt={})
    opt[:count] ||= 0
    count = opt[:count] - 1
    opt[:section] ||= nil
    opt[:format] ||= @default_date_format
    opt[:template] ||= @default_template
    opt[:age] ||= "newest"
    opt[:order] ||= "desc"
    opt[:today] ||= false
    opt[:tag_filter] ||= false
    opt[:tags_color] ||= false
    opt[:times] ||= false
    opt[:totals] ||= false
    opt[:search] ||= false
    opt[:only_timed] ||= false
    opt[:date_filter] ||= []

    # opt[:highlight] ||= true
    section = ""
    if opt[:section].nil?
      section = choose_section
      opt[:section] = @content[section]
    elsif opt[:section].class == String
      if opt[:section] =~ /^all$/i
        combined = {'items' => []}
        @content.each {|k,v|
          combined['items'] += v['items']
        }
        section = opt[:tag_filter] && opt[:tag_filter]['bool'] != 'NONE' ? opt[:tag_filter]['tags'].map {|tag| "@#{tag}"}.join(" + ") : "doing"
        opt[:section] = combined
      else
        section = guess_section(opt[:section])
        opt[:section] = @content[section]
      end
    end

    if opt[:section].class != Hash
      $stderr.puts "Invalid section object"
      return
    end

    items = opt[:section]['items'].sort_by{|item| item['date'] }

    if opt[:date_filter].length == 2
      start_date = opt[:date_filter][0]
      end_date = opt[:date_filter][1]
      items.keep_if {|item|
        if end_date
          item['date'] >= start_date && item['date'] <= end_date
        else
          item['date'].strftime('%F') == start_date.strftime('%F')
        end
      }
    end

    if opt[:tag_filter] && !opt[:tag_filter]['tags'].empty?
      items.delete_if {|item|
        if opt[:tag_filter]['bool'] =~ /(AND|ALL)/
          score = 0
          opt[:tag_filter]['tags'].each {|tag|
            score += 1 if item['title'] =~ /@#{tag}/
          }
          score < opt[:tag_filter]['tags'].length
        elsif opt[:tag_filter]['bool'] =~ /NONE/
          del = false
          opt[:tag_filter]['tags'].each {|tag|
            del = true if item['title'] =~ /@#{tag}/
          }
          del
        elsif opt[:tag_filter]['bool'] =~ /(OR|ANY)/
          del = true
          opt[:tag_filter]['tags'].each {|tag|
            del = false if item['title'] =~ /@#{tag}/
          }
          del
        end
      }
    end

    if opt[:search]
      items.keep_if {|item|
        text = item['note'] ? item['title'] + item['note'].join(" ") : item['title']
        if opt[:search].strip =~ /^\/.*?\/$/
          pattern = opt[:search].sub(/\/(.*?)\//,'\1')
        else
          pattern = opt[:search].split('').join('.{0,3}')
        end
        text =~ /#{pattern}/i
      }
    end

    if opt[:only_timed]
      items.delete_if {|item|
        get_interval(item) == false
      }
    end

    if opt[:today]
      items.delete_if {|item|
        item['date'] < Date.today.to_time
      }.reverse!
      section = Time.now.strftime('%A, %B %d')
    elsif opt[:yesterday]
      items.delete_if {|item| item['date'] <= Date.today.prev_day.to_time or
                       item['date'] >= Date.today.to_time
                      }.reverse!
    else
      if opt[:age] =~ /oldest/i
        items = items[0..count]
      else
        items = items.reverse[0..count]
      end
    end

    if opt[:order] =~ /^a/i
      items.reverse!
    end

    out = ""

    if opt[:output]
      raise "Unknown output format" unless opt[:output] =~ /(template|html|csv|json|timeline)/
    end
    if opt[:output] == "csv"
      output = [CSV.generate_line(['date','title','note','timer','section'])]
      items.each {|i|
        note = ""
        if i['note']
          arr = i['note'].map{|line| line.strip}.delete_if{|e| e =~ /^\s*$/}
          note = arr.join("\n") unless arr.nil?
        end
        if i['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
          interval = get_interval(i, false)
        end
        interval ||= 0
        output.push(CSV.generate_line([i['date'],i['title'],note,interval,i['section']]))
      }
      out = output.join("")
    elsif opt[:output] == "json" || opt[:output] == "timeline"

      items_out = []
      max = items[-1]['date'].strftime('%F')
      min = items[0]['date'].strftime('%F')
      items.each_with_index {|i,index|
        if String.method_defined? :force_encoding
          title = i['title'].force_encoding('utf-8')
          note = i['note'].map {|line| line.force_encoding('utf-8').strip } if i['note']
        else
          title = i['title']
          note = i['note'].map { |line| line.strip } if i['note']
        end

        if i['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
          end_date = Time.parse($1)
          interval = get_interval(i,false)
        end
        end_date ||= ""
        interval ||= 0
        note ||= ""

        tags = []
        skip_tags = ['meanwhile', 'done', 'cancelled', 'flagged']
        i['title'].scan(/@([^\(\s]+)(?:\((.*?)\))?/).each {|tag|
          tags.push(tag[0]) unless skip_tags.include?(tag[0])
        }
        if opt[:output] == "json"
          items_out << {
            :date => i['date'],
            :end_date => end_date,
            :title => title.strip, #+ " #{note}"
            :note => note.class == Array ? note.join("\n") : note,
            :time => "%02d:%02d:%02d" % fmt_time(interval),
            :tags => tags
          }
        elsif opt[:output] == "timeline"
          new_item = {
            'id' => index + 1,
            'content' => title.strip, #+ " #{note}"
            'title' => title.strip + " (#{"%02d:%02d:%02d" % fmt_time(interval)})",
            'start' => i['date'].strftime('%F'),
            'type' => 'point'
          }

          if interval && interval > 0
            new_item['end'] = end_date.strftime('%F')
            if interval > 3600 * 3
              new_item['type'] = 'range'
            end
          end
          items_out.push(new_item)
        end
      }
      if opt[:output] == "json"
        out = {
          'section' => section,
          'items' => items_out,
          'timers' => tag_times("json")
        }.to_json
      elsif opt[:output] == "timeline"
                template =<<EOTEMPLATE
<!doctype html>
<html>
<head>
  <link href="http://visjs.org/dist/vis.css" rel="stylesheet" type="text/css" />
  <script src="http://visjs.org/dist/vis.js"></script>
</head>
<body>
  <div id="mytimeline"></div>

  <script type="text/javascript">
    // DOM element where the Timeline will be attached
    var container = document.getElementById('mytimeline');

    // Create a DataSet with data (enables two way data binding)
    var data = new vis.DataSet(#{items_out.to_json});

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

    // Create a Timeline
    var timeline = new vis.Timeline(container, data, options);
  </script>
</body>
</html>
EOTEMPLATE
        return template
      end
    elsif opt[:output] == "html"
      page_title = section
      items_out = []
      items.each {|i|
        # if i.has_key?('note')
        #   note = '<span class="note">' + i['note'].map{|n| n.strip }.join('<br>') + '</span>'
        # else
        #   note = ''
        # end
        if String.method_defined? :force_encoding
          title = i['title'].force_encoding('utf-8').link_urls
          note = i['note'].map {|line| line.force_encoding('utf-8').strip.link_urls } if i['note']
        else
          title = i['title'].link_urls
          note = i['note'].map { |line| line.strip.link_urls } if i['note']
        end

        if i['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
          interval = get_interval(i)
        end
        interval ||= false

        items_out << {
          :date => i['date'].strftime('%a %-I:%M%p'),
          :title => title.gsub(/(@[^ \(]+(\(.*?\))?)/im,'<span class="tag">\1</span>').strip, #+ " #{note}"
          :note => note,
          :time => interval,
          :section => i['section']
        }
      }

      if @config['html_template']['haml'] && File.exists?(File.expand_path(@config['html_template']['haml']))
        template = IO.read(File.expand_path(@config['html_template']['haml']))
      else
        template = haml_template
      end

      if @config['html_template']['css'] && File.exists?(File.expand_path(@config['html_template']['css']))
        style = IO.read(File.expand_path(@config['html_template']['css']))
      else
        style = css_template
      end

      totals = opt[:totals] ? tag_times("html") : ""
      engine = Haml::Engine.new(template)
      puts engine.render(Object.new, { :@items => items_out, :@page_title => page_title, :@style => style, :@totals => totals })
    else
      items.each {|item|

        if opt[:highlight] && item['title'] =~ /@#{@config['marker_tag']}\b/i
          flag = colors[@config['marker_color']]
          reset = colors['default']
        else
          flag = ""
          reset = ""
        end

        if (item.has_key?('note') && !item['note'].empty?) && @config[:include_notes]
          note_lines = item['note'].delete_if{|line| line =~ /^\s*$/ }.map{|line| "\t" + line.sub(/^\t*/,'') + "  " }
          if opt[:wrap_width] && opt[:wrap_width] > 0
            width = opt[:wrap_width]
            note_lines.map! {|line|
              line.strip.gsub(/(.{1,#{width}})(\s+|\Z)/, "\t\\1\n")
            }
          end
          note = "\n#{note_lines.join("\n").chomp}"
        else
          note = ""
        end
        output = opt[:template].dup

        output.gsub!(/%[a-z]+/) do |m|
          if colors.has_key?(m.sub(/^%/,''))
            colors[m.sub(/^%/,'')]
          else
            m
          end
        end

        output.sub!(/%date/,item['date'].strftime(opt[:format]))

        if item['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
          interval = get_interval(item)
        end
        interval ||= ""
        output.sub!(/%interval/,interval)

        output.sub!(/%shortdate/) {
          if item['date'] > Date.today.to_time
            item['date'].strftime('%_I:%M%P')
          elsif item['date'] > (Date.today - 7).to_time
            item['date'].strftime('%a %-I:%M%P')
          elsif item['date'].year == Date.today.year
            item['date'].strftime('%b %d, %-I:%M%P')
          else
            item['date'].strftime('%b %d %Y, %-I:%M%P')
          end
        }

        output.sub!(/%title/) {|m|
          if opt[:wrap_width] && opt[:wrap_width] > 0
            flag+item['title'].gsub(/(.{1,#{opt[:wrap_width]}})(\s+|\Z)/, "\\1\n\t ").chomp+reset
          else
            flag+item['title'].chomp+reset
          end
        }

        output.sub!(/%section/,item['section']) if item['section']

        if opt[:tags_color]
          escapes = output.scan(/(\e\[[\d;]+m)[^\e]+@/)
          if escapes.length > 0
            last_color = escapes[-1][0]
          else
            last_color = colors['default']
          end
          output.gsub!(/\s(@[^ \(]+)/," #{colors[opt[:tags_color]]}\\1#{last_color}")
        end
        output.sub!(/%note/,note)
        output.sub!(/%odnote/,note.gsub(/^\t*/,""))
        output.sub!(/%chompnote/,note.gsub(/\n+/,' ').gsub(/(^\s*|\s*$)/,'').gsub(/\s+/,' '))
        output.gsub!(/%hr(_under)?/) do |m|
          o = ""
          `tput cols`.to_i.times do
            o += $1.nil? ? "-" : "_"
          end
          o
        end
        output.gsub!(/%n/,"\n")
        output.gsub!(/%t/,"\t")

        out += output + "\n"
      }
      out += tag_times if opt[:totals]
    end
    return out
  end

  ##
  ## @brief      Move entries from a section to Archive or other specified
  ##             section
  ##
  ## @param      section      (String) The source section
  ## @param      count        (Integer) The count
  ## @param      destination  (String) The destination section
  ## @param      tags         (Array) Tags to archive
  ## @param      bool         (String) Tag boolean combinator
  ##
  def archive(section="Currently",count=5,destination=nil,tags=nil,bool=nil,export=nil)

    section = choose_section if section.nil? || section =~ /choose/i
    archive_all = section =~ /all/i # && !(tags.nil? || tags.empty?)
    section = guess_section(section) unless archive_all

    if destination =~ /archive/i && !sections.include?("Archive")
      add_section("Archive")
    end

    destination = guess_section(destination)

    if sections.include?(destination) && (sections.include?(section) || archive_all)
      if archive_all
        to_archive = sections.dup
        to_archive.delete(destination)
        to_archive.each {|source,v|
          do_archive(source, destination, { :count => count, :tags => tags, :bool => bool, :label => true })
        }
      else
        do_archive(section, destination, { :count => count, :tags => tags, :bool => bool, :label => true })
      end

      write(doing_file)
    else
      raise "Either source or destination does not exist"
    end
  end

  ##
  ## @brief      Helper function, performs the actual archiving
  ##
  ## @param      section      (String) The source section
  ## @param      destination  (String) The destination section
  ## @param      opt          (Hash) Additional Options
  ##
  def do_archive(section, destination, opt={})
    count = opt[:count] || 5
    tags = opt[:tags] || []
    bool = opt[:bool] || "AND"
    label = opt[:label] || false

    items = @content[section]['items']
    moved_items = []

    if tags && !tags.empty?
      items.delete_if {|item|
        if bool =~ /(AND|ALL)/
          score = 0
          tags.each {|tag|
            score += 1 if item['title'] =~ /@#{tag}/i
          }
          res = score < tags.length
          moved_items.push(item) if res
          res
        elsif bool =~ /NONE/
          del = false
          tags.each {|tag|
            del = true if item['title'] =~ /@#{tag}/i
          }
          moved_items.push(item) if del
          del
        elsif bool =~ /(OR|ANY)/
          del = true
          tags.each {|tag|
            del = false if item['title'] =~ /@#{tag}/i
          }
          moved_items.push(item) if del
          del
        end
      }
      moved_items.each {|item|
        if label
          item['title'] = item['title'].sub(/(?:@from\(.*?\))?(.*)$/,"\\1 @from(#{section})")  unless section == "Currently"
        end
      }
      @content[section]['items'] = moved_items
      @content[destination]['items'] += items
      @results.push("Archived #{items.length} items from #{section} to #{destination}")
    else

      return if items.length < count
      if count == 0
        @content[section]['items'] = []
      else
        @content[section]['items'] = items[0..count-1]
      end

      items.each{|item|
        if label
          item['title'] = item['title'].sub(/(?:@from\(.*?\))?(.*)$/,"\\1 @from(#{section})")  unless section == "Currently"
        end
      }

      @content[destination]['items'] += items[count..-1]
      @results.push("Archived #{items.length - count} items from #{section} to #{destination}")
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
  def today(times=true,output=nil,opt={})
    opt[:totals] ||= false
    cfg = @config['templates']['today']
    list_section({:section => opt[:section], :wrap_width => cfg['wrap_width'], :count => 0, :format => cfg['date_format'], :template => cfg['template'], :order => "asc", :today => true, :times => times, :output => output, :totals => opt[:totals]})
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
  def list_date(dates,section,times=nil,output=nil,opt={})
    opt[:totals] ||= false
    section = guess_section(section)
    # :date_filter expects an array with start and end date
    if dates.class == String
      dates = [dates, dates]
    end

    list_section({:section => section, :count => 0, :order => "asc", :date_filter => dates, :times => times, :output => output, :totals => opt[:totals] })
  end

  ##
  ## @brief      Show entries from the previous day
  ##
  ## @param      section  (String) The section
  ## @param      times    (Bool) Show times
  ## @param      output   (String) Output format
  ## @param      opt      (Hash) Additional Options
  ##
  def yesterday(section,times=nil,output=nil,opt={})
    opt[:totals] ||= false
    section = guess_section(section)
    list_section({:section => section, :count => 0, :order => "asc", :yesterday => true, :times => times, :output => output, :totals => opt[:totals] })
  end

  ##
  ## @brief      Show recent entries
  ##
  ## @param      count    (Integer) The number to show
  ## @param      section  (String) The section to show from, default Currently
  ## @param      opt      (Hash) Additional Options
  ##
  def recent(count=10,section=nil,opt={})
    times = opt[:t] || true
    opt[:totals] ||= false
    cfg = @config['templates']['recent']
    section ||= @current_section
    section = guess_section(section)
    list_section({:section => section, :wrap_width => cfg['wrap_width'], :count => count, :format => cfg['date_format'], :template => cfg['template'], :order => "asc", :times => times, :totals => opt[:totals] })
  end

  ##
  ## @brief      Show the last entry
  ##
  ## @param      times    (Bool) Show times
  ## @param      section  (String) Section to pull from, default Currently
  ##
  def last(times=true,section=nil)
    section ||= @current_section
    section = guess_section(section)
    cfg = @config['templates']['last']
    list_section({:section => section, :wrap_width => cfg['wrap_width'], :count => 1, :format => cfg['date_format'], :template => cfg['template'], :times => times})
  end

  ##
  ## @brief      Get total elapsed time for all tags in selection
  ##
  ## @param      format  (String) return format (html, json, or text)
  ##
  def tag_times(format="text")

    return "" if @timers.empty?

    max = @timers.keys.sort_by {|k| k.length }.reverse[0].length + 1

    total = @timers.delete("All")

    if format == "html"
      output =<<EOS
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
      @timers.sort_by {|k,v|
        v
      }.reverse.each {|k,v|
        output += "<tr><td style='text-align:left;'>#{k}</td><td style='text-align:left;'>#{"%02d:%02d:%02d" % fmt_time(v)}</td></tr>\n" if v > 0
      }
      tail =<<EOS
      <tr>
        <td style="text-align:left;" colspan="2"></td>
      </tr>
      </tbody>
      <tfoot>
      <tr>
        <td style="text-align:left;"><strong>Total</strong></td>
        <td style="text-align:left;">#{"%02d:%02d:%02d" % fmt_time(total)}</td>
      </tr>
      </tfoot>
      </table>
EOS
      output + tail
    elsif format == "json"
      output = []
      @timers.delete_if { |k,v| v == 0}.sort_by{|k,v| v }.reverse.each {|k,v|
        output << {
          'tag' => k,
          'seconds' => v,
          'formatted' => "%02d:%02d:%02d" % fmt_time(v)
        }
      }
      output
    else
      output = []
      @timers.delete_if { |k,v| v == 0}.sort_by{|k,v| v }.reverse.each {|k,v|
        spacer = ""
        (max - k.length).times do
          spacer += " "
        end
        output.push("#{k}:#{spacer}#{"%02d:%02d:%02d" % fmt_time(v)}")
      }

      output = output.empty? ? "" : "\n--- Tag Totals ---\n" + output.join("\n")
      output += "\n\nTotal tracked: #{"%02d:%02d:%02d" % fmt_time(total)}\n"
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
    @config['autotag']['whitelist'].each {|tag|
      text.sub!(/(?<!@)(#{tag.strip})\b/i) do |m|
        m.downcase! if tag =~ /[a-z]/
        "@#{m}"
      end unless text =~ /@#{tag}\b/i
    }
    tail_tags = []
    @config['autotag']['synonyms'].each {|tag, v|
      v.each {|word|
        if text =~ /\b#{word}\b/i
          tail_tags.push(tag)
        end
      }
    }
    if tail_tags.length > 0
    text + ' ' + tail_tags.uniq.map {|t| '@'+t }.join(' ')
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
  def get_interval(item, formatted=true)
    done = nil
    start = nil

    if item['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/
      done = Time.parse($1)
    else
      return nil
    end

    if item['title'] =~ /@start\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/
      start = Time.parse($1)
    else
      start = item['date']
    end

    seconds = (done - start).to_i

    item['title'].scan(/(?mi)@(\S+?)(\(.*\))?(?=\s|$)/).each {|m|
      k = m[0] == "done" ? "All" : m[0].downcase
      if @timers.has_key?(k)
        @timers[k] += seconds
      else
        @timers[k] = seconds
      end
    }

    return seconds unless formatted

    seconds > 0 ? "%02d:%02d:%02d" % fmt_time(seconds) : false
  end

  ##
  ## @brief      Format human readable time from seconds
  ##
  ## @param      seconds  The seconds
  ##
  def fmt_time(seconds)
    if seconds.nil?
      return [0, 0, 0]
    end
    minutes =  (seconds / 60).to_i
    hours = (minutes / 60).to_i
    days = (hours / 24).to_i
    hours = (hours % 24).to_i
    minutes = (minutes % 60).to_i
    [days, hours, minutes]
  end

end
