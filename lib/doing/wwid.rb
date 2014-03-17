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
      'template' => '%date: %title%note',
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
      'sample' => {
        'date_format' => '%_I:%M%P',
        'template' => '%date | %title%note',
        'wrap_width' => 0,
        'section' => 'section_name',
        'count' => 5
      },
      'color' => {
          'date_format' => '%F %_I:%M%P',
          'template' => '%boldblack%date %boldgreen| %boldwhite%title%default%note',
          'wrap_width' => 0,
          'section' => 'Currently',
          'count' => 10,
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
      if line =~ /^(\w[\w ]+):\s*(@\S+\s*)*$/
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

    pid = Process.fork { system(ENV['EDITOR'], "#{tmpfile.path}") }

    trap("INT") {
      Process.kill(9, pid) rescue Errno::ESRCH
      tmpfile.unlink
      tmpfile.close!
      exit 0
    }

    Process.wait(pid)

    begin
      input = IO.read(tmpfile.path)
    ensure
      tmpfile.close
      tmpfile.unlink
    end

    input
  end

  # This takes a multi-line string and formats it as an entry
  # returns an array of [title(String), note(Array)]
  def format_input(input)
    return false unless input && input.length > 0
    input_lines = input.strip.split(/[\n\r]+/)
    title = input_lines[0].strip
    note = input_lines.length > 1 ? input_lines[1..-1] : []
    note.map! { |line|
      line.strip
    }.delete_if { |line|
      line =~ /^\s*$/
    }

    [title, note]
  end

  def sections
    @content.keys
  end

  def add_section(title)
    @content[title.cap_first] = {'original' => "#{title}:", 'items' => []}
  end

  def add_item(title,section=nil,opt={})
    section ||= @current_section
    add_section(section) unless @content.has_key?(section)
    opt[:date] ||= Time.now
    opt[:note] ||= []

    entry = {'title' => title.strip.cap_first, 'date' => opt[:date]}
    unless opt[:note] =~ /^\s*$/s
      entry['note'] = opt[:note]
    end
    @content[section]['items'].push(entry)
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
    opt[:order] ||= "desc"
    opt[:today] ||= false

    if opt[:section].nil?
      opt[:section] = @content[choose_section]
    elsif opt[:section].class == String
      if @content.has_key? opt[:section]
        opt[:section] = @content[opt[:section]]
      else
        $stderr.puts "Section '#{opt[:section]}' not found"
        return
      end
    end

    if opt[:section].class != Hash
      $stderr.puts "Invalid section object"
      return
    end

    items = opt[:section]['items'].sort_by{|item| item['date'] }

    if opt[:today]
      items.delete_if {|item|
        item['date'] < Date.today.to_time
      }.reverse!
    else
      items = items.reverse[0..count]
    end

    items.reverse! if opt[:order] =~ /^asc/i

    out = ""

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

    return out
  end

  def archive(section=nil,count=10)
    section = choose_section if section.nil? || section =~ /choose/i
    if sections.include?(section)
      items = @content[section]['items']
      return if items.length < 10
      @content[section]['items'] = items[0..5]
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

  def today
    cfg = @config['templates']['today']
    list_section({:section => @current_section, :wrap_width => cfg['wrap_width'], :count => 0, :format => cfg['date_format'], :template => cfg['template'], :order => "asc", :today => true})
  end

  def recent(count=10,section=nil)
    cfg = @config['templates']['recent']
    section ||= @current_section
    list_section({:section => section, :wrap_width => cfg['wrap_width'], :count => count, :format => cfg['date_format'], :template => cfg['template'], :order => "asc"})
  end

  def last
    cfg = @config['templates']['last']
    list_section({:section => @current_section, :wrap_width => cfg['wrap_width'], :count => 1, :format => cfg['date_format'], :template => cfg['template']})
  end

end

# infile = "~/Dropbox/nvALT2.2/?? What was I doing.md"

# wwid = WWID.new(infile)

# wwid.add_item("Getting freaky with wwid CLI","Currently",{:date => Time.now})
# wwid.write(infile)
