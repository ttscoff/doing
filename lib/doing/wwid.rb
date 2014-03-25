#!/usr/bin/ruby
class String
  def cap_first
    self.sub(/^\w/) do |m|
      m.upcase
    end
  end
end

class WWID
  attr_accessor :content, :sections, :current_section, :doing_file, :config


  def initialize(input=nil)
    @content = {}
    @timers = {}
    @config = read_config

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

    @doing_file = File.expand_path(config['doing_file'])
    @current_section = config['current_section']
    @default_template = config['templates']['default']['template']
    @default_date_format = config['templates']['default']['date_format']

    @config[:include_notes] ||= true

    File.open(File.expand_path(DOING_CONFIG), 'w') { |yf| YAML::dump(config, yf) }

    if input.nil?
      create(@doing_file) unless File.exists?(@doing_file)
      input = IO.read(@doing_file)
      input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
    elsif File.exists?(File.expand_path(input)) && File.file?(File.expand_path(input)) && File.stat(File.expand_path(input)).size > 0
      input = IO.read(File.expand_path(input))
      input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
      @doing_file = File.expand_path(input)
    elsif input.length < 256
      create(input)
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
    filename = @doing_file
    unless File.exists?(filename) && File.stat(filename).size > 0
      File.open(filename,'w+') do |f|
        f.puts @current_section + ":"
      end
    end
  end

  def read_config
    if File.exists? File.expand_path(DOING_CONFIG)
      return YAML.load_file(File.expand_path(DOING_CONFIG))
    else
      return {}
    end
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
  # returns an array of [title(String), note(Array)]
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

  def chronify(input)
    if input =~ /^(\d+)([mhd])?$/i
      amt = $1
      type = $2.nil? ? "m" : $2
      input = case type.downcase
      when "m"
        amt + " minutes ago"
      when "h"
        amt + " hours ago"
      when "d"
        amt + " days ago"
      else
        input
      end
    end

    Chronic.parse(input, {:context => :past, :ambiguous_time_range => 8})
  end

  def sections
    @content.keys
  end

  def add_section(title)
    @content[title.cap_first] = {'original' => "#{title}:", 'items' => []}
  end

  def guess_section(frag)
    sections.each {|section| return section if frag.downcase == section.downcase}
    section = false
    re = frag.split('').join(".*?")
    sections.each {|sect|
      if sect =~ /#{re}/i
        $stderr.puts "Assuming you meant #{sect}"
        section = sect
        break
      end
    }
    unless section
      alt = guess_view(frag)
      if alt
        raise "Did you mean `doing view #{alt}`?"
      else
        raise "Invalid section: #{frag}"
      end
    end
    section.cap_first
  end

  def guess_view(frag)
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
    unless view
      alt = guess_section(frag)
      if alt
        raise "Did you mean `doing show #{alt}`?"
      else
        raise "Invalid view: #{frag}"
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

    entry = {'title' => title.strip.cap_first, 'date' => opt[:back]}
    unless opt[:note] =~ /^\s*$/s
      entry['note'] = opt[:note]
    end
    @content[section]['items'].push(entry)
  end

  def tag_last(opt={})
    opt[:section] ||= @current_section
    opt[:count] ||= 1
    opt[:archive] ||= false
    opt[:tags] ||= ["done"]
    opt[:date] ||= false
    opt[:remove] ||= false

    opt[:section] = guess_section(opt[:section])

    if @content.has_key?(opt[:section])
      # sort_section(opt[:section])
      # items = @content[opt[:section]]['items'].sort_by{|item| item['date'] }.reverse

      @content[opt[:section]]['items'].each_with_index {|item, i|
        break if i == opt[:count]
        title = item['title']
        opt[:tags].each {|tag|
          if opt[:remove]
            title.gsub!(/ @#{tag}/,'')
          else
            unless title =~ /@#{tag}/
              if tag == "done" || opt[:date]
                title += " @#{tag}(#{Time.now.strftime('%F %R')})"
              else
                title += " @#{tag}"
              end
            end
          end
        }
        @content[opt[:section]]['items'][i]['title'] = title
      }

      if opt[:archive] && opt[:section] != "Archive"
        archived = @content[opt[:section]]['items'][0..opt[:count]-1]
        @content[opt[:section]]['items'] = @content[opt[:section]]['items'][opt[:count]..-1]
        @content['Archive']['items'] = archived + @content['Archive']['items']
      end

      write(@doing_file)
    else
      raise "Section not found"
    end
  end

  def write(file=nil)
    if @other_content_top.empty?
      output = ""
    else
      output = @other_content_top.join("\n") + "\n"
    end
    @content.each {|title, section|
      output += section['original'] + "\n"
      output += list_section({:section => title, :template => "\t- %date | %title%note"})
    }
    output += @other_content_bottom.join("\n")
    if file.nil?
      $stdout.puts output
    else
      if File.exists?(File.expand_path(file))
        File.open(File.expand_path(file),'w+') do |f|
          f.puts output
        end
      end
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

    if opt[:section].nil?
      opt[:section] = @content[choose_section]
    elsif opt[:section].class == String
      if opt[:section] =~ /^all$/i
        combined = {'items' => []}
        @content.each {|k,v|
          combined['items'] += v['items']
        }
        opt[:section] = combined
      else
        opt[:section] = @content[guess_section(opt[:section])]
      end
    end

    if opt[:section].class != Hash
      $stderr.puts "Invalid section object"
      return
    end

    items = opt[:section]['items'].sort_by{|item| item['date'] }

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

    if opt[:today]
      items.delete_if {|item|
        item['date'] < Date.today.to_time
      }.reverse!
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

    if opt[:csv]
      output = [['date','title','note'].to_csv]
      items.each {|i|
        note = ""
        if i['note']
          arr = i['note'].map{|line| line.strip}.delete_if{|e| e =~ /^\s*$/}
          note = arr.join("\n") unless arr.nil?
        end
        output.push([i['date'],i['title'],note].to_csv)
      }
      out = output.join()
    else

      items.each {|item|
        if (item.has_key?('note') && !item['note'].empty?) && @config[:include_notes]
          note_lines = item['note'].delete_if{|line| line =~ /^\s*$/ }.map{|line| "\t\t" + line.sub(/^\t\t/,'') }
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
            item['title'].gsub(/(.{1,#{opt[:wrap_width]}})(\s+|\Z)/, "\\1\n\t ").strip
          else
            item['title'].strip
          end
        }
        if opt[:tags_color]
          output.gsub!(/\s(@\S+(?:\(.*?\))?)/," #{colors[opt[:tags_color]]}\\1")
        end
        output.sub!(/%note/,note)
        output.sub!(/%odnote/,note.gsub(/\t\t/,"\t"))
        output.gsub!(/%hr(_under)?/) do |m|
          o = ""
          `tput cols`.to_i.times do
            o += $1.nil? ? "-" : "_"
          end
          o
        end


        out += output + "\n"
      }
    end

    return out
  end

  def archive(section=nil,count=10)
    section = choose_section if section.nil? || section =~ /choose/i
    section = guess_section(section)
    if sections.include?(section)
      items = @content[section]['items']
      return if items.length < count
      @content[section]['items'] = items[0..count-1]
      add_section('Archive') unless sections.include?('Archive')
      @content['Archive']['items'] += items[count..-1]
      write(@doing_file)
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
    color['default']="\033[0;39m"
    color
  end


  def all(order="")
    order = "asc" if order == ""
    cfg = @config['templates']['default_template']
    list_section({:section => @current_section, :wrap_width => cfg['wrap_width'], :count => 0, :format => cfg['date_format'], :template => cfg['template'], :order => order})
  end

  def today(times=false)
    cfg = @config['templates']['today']
    list_section({:section => @current_section, :wrap_width => cfg['wrap_width'], :count => 0, :format => cfg['date_format'], :template => cfg['template'], :order => "asc", :today => true, :times => times})
  end

  def yesterday
    list_section({:section => @current_section, :count => 0, :order => "asc", :yesterday => true})
  end

  def recent(count=10,section=nil)
    cfg = @config['templates']['recent']
    section ||= @current_section
    section = guess_section(section)
    list_section({:section => section, :wrap_width => cfg['wrap_width'], :count => count, :format => cfg['date_format'], :template => cfg['template'], :order => "asc"})
  end

  def last
    cfg = @config['templates']['last']
    list_section({:section => @current_section, :wrap_width => cfg['wrap_width'], :count => 1, :format => cfg['date_format'], :template => cfg['template']})
  end

  def tag_times
    output = []
    return "" if @timers.length == 0
    max = @timers.keys.sort_by {|k| k.length }.reverse[0].length + 1

    total = @timers.delete("All")

    @timers.sort_by{|k,v| v }.reverse.each {|k,v|
      spacer = ""
      (max - k.length).times do
        spacer += " "
      end
      output.push("#{k}:#{spacer}#{"%02d:%02d:%02d" % fmt_time(v)}")
    }
    output.empty? ? "" : "\n--- Tag Totals ---\n" + output.join("\n") + "\n\nTotal tracked: #{"%02d:%02d:%02d" % fmt_time(total)}\n"
  end

  private

  def get_interval(item)
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

    "%02d:%02d:%02d" % fmt_time(seconds)
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




# infile = "~/Dropbox/nvALT2.2/?? What was I doing.md"

# wwid = WWID.new(infile)

# wwid.add_item("Getting freaky with wwid CLI","Currently",{:date => Time.now})
# wwid.write(infile)
