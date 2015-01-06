#!/usr/bin/ruby

require 'deep_merge'

class String
  def cap_first
    self.sub(/^\w/) do |m|
      m.upcase
    end
  end

end

class WWID
  attr_accessor :content, :sections, :current_section, :doing_file, :config, :results


  def initialize
    @content = {}
    @timers = {}
    @config = read_config
    @results = []

    @config['autotag'] ||= {}
    @config['autotag']['whitelist'] ||= []
    @config['autotag']['synonyms'] ||= {}
    @config['doing_file'] ||= "~/what_was_i_doing.md"
    @config['current_section'] ||= 'Currently'
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
      'template' => '%shortdate: %title',
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

    File.open(home_config, 'w') { |yf| YAML::dump(config, yf) }
  end

  def init_doing_file(input=nil)
    @doing_file = File.expand_path(config['doing_file'])

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
        @content[section]['items'].push({'title' => title, 'date' => date})
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
              @content[section]['items'][current - 1]['note'].push(line)
            end
          end
        # end
      end
    }
  end

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

  def home_config
    if Dir.respond_to?('home')
      File.join(Dir.home, DOING_CONFIG_NAME)
    else
      File.join(File.expand_path("~"), DOING_CONFIG_NAME)
    end
  end

  def read_config
    config = {}
    dir = Dir.pwd
    while (dir != '/' && (dir =~ /[A-Z]:\//) == nil)
      if File.exists? File.join(dir, DOING_CONFIG_NAME)
        config = YAML.load_file(File.join(dir, DOING_CONFIG_NAME)).deep_merge!(config)
      end
      dir = File.dirname(dir)
    end
    if config.empty? && File.exists?(home_config)
      config = YAML.load_file(home_config)
    end
    config
  end

  def fork_editor(input="")
    tmpfile = Tempfile.new('doing')

    File.open(tmpfile.path,'w+') do |f|
      f.puts input
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

  # This takes a multi-line string and formats it as an entry
  # Params:
  # +input+:: String
  # Returns:
  # [title(String), note(Array)]
  def format_input(input)
    raise "No content in entry" if input.nil? || input.strip.length == 0
    input_lines = input.split(/[\n\r]+/)
    title = input_lines[0].strip
    note = input_lines.length > 1 ? input_lines[1..-1] : []
    note.map! { |line|
      line.strip
    }.delete_if { |line|
      line =~ /^\s*$/
    }

    [title, note]
  end

  # Converts simple strings into seconds that can be added to a Time object
  # Params:
  # +qty+:: HH:MM or XX[dhm][[XXhm][XXm]] (1d2h30m, 45m, 1.5d, 1h20m, etc.)
  # Returns:
  # seconds(Integer)
  def chronify(input)

    had_to_try = Time.parse(input) rescue false

    if had_to_try.class == FalseClass
      if input =~ /^(\d+)([mhd])?$/i
        amt = $1
        type = $2.nil? ? "m" : $2
        input = case type.downcase
        when 'm'
          amt + " minutes ago"
        when 'h'
          amt + " hours ago"
        when 'd'
          amt + " days ago"
        else
          input
        end
      end

      Chronic.parse(input, {:context => :past, :ambiguous_time_range => 8})
    else
      had_to_try
    end
  end


  # Converts simple strings into seconds that can be added to a Time object
  # Params:
  # +qty+:: HH:MM or XX[dhm][[XXhm][XXm]] (1d2h30m, 45m, 1.5d, 1h20m, etc.)
  # Returns seconds (Integer)
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

  def sections
    @content.keys
  end

  def add_section(title)
    @content[title.cap_first] = {'original' => "#{title}:", 'items' => []}
  end

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
        print "Create a new section called #{frag.cap_first} (y/N)?"
        input = STDIN.gets
        if input =~ /^y/i
          add_section(frag.cap_first)
          write(doing_file)
          return frag.cap_first
        end
        raise "Unknown section: #{frag}"
      end
    end
    section ? section.cap_first : section
  end

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

  def add_item(title,section=nil,opt={})
    section ||= @current_section
    add_section(section) unless @content.has_key?(section)
    opt[:date] ||= Time.now
    opt[:note] ||= []
    opt[:back] ||= Time.now
    opt[:timed] ||= false

    title = [title.strip.cap_first] + @config['default_tags'].map{|t| '@' + t.sub(/^ *@/,'').chomp}
    title = autotag(title.join(' '))
    entry = {'title' => title, 'date' => opt[:back]}
    unless opt[:note] =~ /^\s*$/s
      entry['note'] = opt[:note]
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

  def last_note(section=@current_section)
    section = guess_section(section)
    if @content.has_key?(section)
      last_item = @content[section]['items'].dup.sort_by{|item| item['date'] }.reverse[0]
      p last_item
      return last_item['note']
    else
      raise "Section #{section} not found"
    end
  end

  def tag_last(opt={})
    opt[:section] ||= @current_section
    opt[:count] ||= 1
    opt[:archive] ||= false
    opt[:tags] ||= ["done"]
    opt[:sequential] ||= false
    opt[:date] ||= false
    opt[:remove] ||= false
    opt[:autotag] ||= false
    opt[:back] ||= Time.now


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
            elsif opt[:back].instance_of? Fixnum
              done_date = item['date'] + opt[:back]
            else
              done_date = opt[:back]
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
          archived = @content[section]['items'][0..opt[:count]-1].concat(@content['Archive']['items'])
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

  # accepts one tag and the raw text of a new item
  # if the passed tag is on any item, it's replaced with @done
  # if new_item is not nil, it's tagged with the passed tag and inserted
  # This is for use where only one instance of a given tag should exist (@meanwhile)
  def stop_start(tag,opt={})
    opt[:section] ||= @current_section
    opt[:archive] ||= false
    opt[:back] ||= Time.now
    opt[:new_item] ||= false
    opt[:note] ||= false

    opt[:section] = guess_section(opt[:section])

    tag.sub!(/^@/,'')

    found_items = 0

    @content[opt[:section]]['items'].each_with_index {|item, i|
      if item['title'] =~ /@#{tag}/
        title = item['title'].gsub(/(^| )@(#{tag}|done)(\([^\)]*\))?/,'')
        title += " @done(#{opt[:back].strftime('%F %R')})"

        @content[opt[:section]]['items'][i]['title'] = title
        found_items += 1

        if opt[:archive] && opt[:section] != "Archive"
          @results.push(%Q{Completed and archived "#{@content[opt[:section]]['items'][i]['title']}"})
          @content['Archive']['items'].push(@content[opt[:section]]['items'][i])
          @content[opt[:section]]['items'].delete_at(i)
        else
          @results.push(%Q{Completed "#{@content[opt[:section]]['items'][i]['title']}"})
        end
      end
    }

    @results.push("No active @#{tag} tasks found.") if found_items == 0

    if opt[:new_item]
      title, note = format_input(opt[:new_item])
      note.push(opt[:note]) if opt[:note]
      title += " @#{tag}"
      add_item(title.cap_first, opt[:section], {:note => note, :back => opt[:back]})
    end

    write(@doing_file)
  end

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

  def restore_backup(file)
    if File.exists?(file+"~")
      puts file+"~"
      FileUtils.cp(file+"~",file)
      @results.push("Restored #{file}")
    end
  end


  def choose_section
    sections.each_with_index {|section, i|
      puts "% 3d: %s" % [i+1, section]
    }
    print "> "
    num = STDIN.gets
    return false if num =~ /^[a-z ]*$/i
    return sections[num.to_i - 1]
  end

  def views
    @config.has_key?('views') ? @config['views'].keys : []
  end

  def choose_view
    views.each_with_index {|view, i|
      puts "% 3d: %s" % [i+1, view]
    }
    print "> "
    num = STDIN.gets
    return false if num =~ /^[a-z ]*$/i
    return views[num.to_i - 1]
  end

  def get_view(title)
    if @config['views'].has_key?(title)
      return @config['views'][title]
    end
    false
  end

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
        section = opt[:tag_filter] ? opt[:tag_filter]['tags'].map {|tag| "@#{tag}"}.join(" + ") : "doing"
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
        pattern = opt[:search].split('').join('.{0,3}')
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
      output = [CSV.generate_line(['date','title','note','timer'])]
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
        output.push(CSV.generate_line([i['date'],i['title'],note,interval]))
      }
      out = output.join("")
    elsif opt[:output] == "json" || opt[:output] == "timeline"

      items_out = []
      max = items[-1]['date'].strftime('%F')
      min = items[0]['date'].strftime('%F')
      items.each_with_index {|i,index|
        if RUBY_VERSION.to_f > 1.8
          title = i['title'].force_encoding('utf-8')
          note = i['note'].map {|line| line.force_encoding('utf-8').strip } if i['note']
        else
          title = i['title']
          note = i['note'].map { |line| line.strip }
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
        if RUBY_VERSION.to_f > 1.8
          title = i['title'].force_encoding('utf-8')
          note = i['note'].map {|line| line.force_encoding('utf-8').strip } if i['note']
        else
          title = i['title']
          note = i['note'].map { |line| line.strip }
        end

        if i['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
          interval = get_interval(i)
        end
        interval ||= false

        items_out << {
          :date => i['date'].strftime('%a %-I:%M%p'),
          :title => title.gsub(/(@[^ \(]+(\(.*?\))?)/im,'<span class="tag">\1</span>').strip, #+ " #{note}"
          :note => note,
          :time => interval
        }
      }

      style = "body{background:#fff;color:#333;font-family:Helvetica,arial,freesans,clean,sans-serif;font-size:16px;line-height:120%;text-align:justify;padding:20px}h1{text-align:left;position:relative;left:220px;margin-bottom:1em}ul{list-style-position:outside;position:relative;left:170px;margin-right:170px;text-align:left}ul li{list-style-type:none;border-left:solid 1px #ccc;padding-left:10px;line-height:2;position:relative}ul li .date{font-size:14px;position:absolute;left:-122px;color:#7d9ca2;text-align:right;width:110px;line-height:2}ul li .tag{color:#999}ul li .note{display:block;color:#666;padding:0 0 0 22px;line-height:1.4;font-size:15px}ul li .note:before{content:'\\25BA';font-weight:300;position:absolute;left:40px;font-size:8px;color:#aaa;line-height:3}ul li:hover .note{display:block}span.time{color:#729953;float:left;position:relative;padding:0 5px;font-size:15px;border-bottom:dashed 1px #ccc;text-align:right;background:#f9fced;margin-right:4px}table td{border-bottom:solid 1px #ddd;height:24px}caption{text-align:left;border-bottom:solid 1px #aaa;margin:10px 0}table{width:400px;margin:50px 0 0 211px}th{padding-bottom:10px}th,td{padding-right:20px}table{max-width:400px;margin:50px 0 0 221px}"
      template =<<EOT
!!!
%html
%head
  %meta{"charset" => "utf-8"}/
  %meta{"content" => "IE=edge,chrome=1", "http-equiv" => "X-UA-Compatible"}/
  %title what are you doing?
  %style= @style
%body
  %header
    %h1= @page_title
  %article
    %ul
      - @items.each do |i|
        %li
          %span.date= i[:date]
          = i[:title]
          - if i[:time] && i[:time] != "00:00:00"
            %span.time= i[:time]
          - if i[:note]
            %span.note= i[:note].map{|n| n.strip }.join('<br>')
    = @totals
EOT
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
        if opt[:tags_color]
          output.gsub!(/\s(@\S+(?:\(.*?\))?)/," #{colors[opt[:tags_color]]}\\1")
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
    end
    out += tag_times if opt[:totals]
    return out
  end

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
          item['title'] += " @from(#{section})" unless section == "Currently" || item['title'] =~ /@from\(/
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
          item['title'] += " @from(#{section})" unless section == "Currently"
        end
      }
      @content[destination]['items'] += items[count..-1]
      @results.push("Archived #{items.length - count} items from #{section} to #{destination}")
    end
  end

  def colors
    color = {}
    color['black'] = "\033[30m"
    color['red'] = "\033[31m"
    color['green'] = "\033[32m"
    color['yellow'] = "\033[33m"
    color['blue'] = "\033[34m"
    color['magenta'] = "\033[35m"
    color['cyan'] = "\033[36m"
    color['white'] = "\033[37m"
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
    color['boldgreen'] = "\033[1;32m"
    color['boldyellow'] = "\033[1;33m"
    color['boldblue'] = "\033[1;34m"
    color['boldmagenta'] = "\033[1;35m"
    color['boldcyan'] = "\033[1;36m"
    color['boldwhite'] = "\033[1;37m"
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
    color['default']="\033[0;39m"
    color
  end


  def all(order="")
    order = "asc" if order == ""
    cfg = @config['templates']['default_template']
    list_section({:section => @current_section, :wrap_width => cfg['wrap_width'], :count => 0, :format => cfg['date_format'], :template => cfg['template'], :order => order})
  end

  def today(times=true,output=nil,opt={})
    opt[:totals] ||= false
    cfg = @config['templates']['today']
    list_section({:section => @current_section, :wrap_width => cfg['wrap_width'], :count => 0, :format => cfg['date_format'], :template => cfg['template'], :order => "asc", :today => true, :times => times, :output => output, :totals => opt[:totals]})
  end

  def list_date(dates,section,times=nil,output=nil,opt={})
    opt[:totals] ||= false
    section = guess_section(section)
    # :date_filter expects an array with start and end date
    if dates.class == String
      dates = [dates, dates]
    end

    list_section({:section => section, :count => 0, :order => "asc", :date_filter => dates, :times => times, :output => output, :totals => opt[:totals] })
  end

  def yesterday(section,times=nil,output=nil,opt={})
    opt[:totals] ||= false
    section = guess_section(section)
    list_section({:section => section, :count => 0, :order => "asc", :yesterday => true, :times => times, :output => output, :totals => opt[:totals] })
  end

  def recent(count=10,section=nil,opt={})
    times = opt[:t] || true
    opt[:totals] ||= false
    cfg = @config['templates']['recent']
    section ||= @current_section
    section = guess_section(section)
    list_section({:section => section, :wrap_width => cfg['wrap_width'], :count => count, :format => cfg['date_format'], :template => cfg['template'], :order => "asc", :times => times, :totals => opt[:totals] })
  end

  def last(times=true)
    cfg = @config['templates']['last']
    list_section({:section => @current_section, :wrap_width => cfg['wrap_width'], :count => 1, :format => cfg['date_format'], :template => cfg['template'], :times => times})
  end

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

  # Uses autotag: configuration to turn keywords into tags for time tracking.
  # Does not repeat tags in a title, and only converts the first instance of
  # an untagged keyword
  def autotag(title)
    return unless title
    @config['autotag']['whitelist'].each {|tag|
      title.sub!(/(?<!@)(#{tag.strip})\b/i,'@\1') unless title =~ /@#{tag}\b/i
    }
    tail_tags = []
    @config['autotag']['synonyms'].each {|tag, v|
      v.each {|word|
        if title =~ /\b#{word}\b/i
          tail_tags.push(tag)
        end
      }
    }
    if tail_tags.length > 0
      title + ' ' + tail_tags.uniq.map {|t| '@'+t }.join(' ')
    else
      title
    end
  end

  def autotag_item(item)
    item['title'] = autotag(item['title'])
    item
  end

  private

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
      k = m[0] == "done" ? "All" : m[0]
      if @timers.has_key?(k)
        @timers[k] += seconds
      else
        @timers[k] = seconds
      end
    }

    return seconds unless formatted

    seconds > 0 ? "%02d:%02d:%02d" % fmt_time(seconds) : false
  end

  def fmt_time(seconds)
    minutes =  (seconds / 60).to_i
    hours = (minutes / 60).to_i
    days = (hours / 24).to_i
    hours = (hours % 60).to_i
    minutes = (minutes % 60).to_i
    [days, hours, minutes]
  end
end
