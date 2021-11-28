# frozen_string_literal: true

# title: Template Export
# description: Default export option using configured template placeholders
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class TemplateExport
    include Doing::Color
    include Doing::Util

    def self.settings
      {
        trigger: 'template|doing'
      }
    end

    def self.fetch_placeholders(config, template)
      @placeholders ||= placeholders_from_config(config, template)
      @elements ||= elements_from_config(config, template)
    end

    def self.placeholders_from_config(config, template)
      placeholders = {
        date: {},
        duration: {},
        interval: {},
        note: {},
        section: {},
        title: {}
      }

      chain = ['default']
      chain << template unless template == 'default'

      chain.each do |tpl|
        template_placeholders = config.dig('templates', tpl, 'placeholders')

        placeholders.deep_merge(template_placeholders.symbolize_keys) if template_placeholders
      end

      placeholders
    end

    def self.elements_from_config(config, template)
      elements = %w[date title section interval duration note]

      chain = ['default']
      chain << template unless template == 'default'

      chain.each do |tpl|
        template_elements = config.dig('templates', tpl, 'elements')
        if template_elements
          elements = template_elements.select { |el| elements.include?(el) }
        end
      end

      elements
    end

    def self.fetch(item, setting, default = nil)
      return nil if item.nil?

      t = @placeholders.fetch(item.to_sym, nil)
      return nil if t.nil?

      t.fetch(setting.to_sym, default)
    end

    def self.format_placeholder(item, content)
      return [content] if @placeholders.nil?

      content = content.dup if content.frozen?
      content ||= ''

      if content.is_a?(Array)
        return content.each.each_with_object([]) { |l, out| out.concat(format_placeholder(item, l)) }
      end


      return [] if fetch(item, :collapse, true) && content.strip.empty?

      wrap = fetch(item, :wrap, false)
      # color = fetch(item, :color, 'default')


      pad_char = fetch(item, :pad_char, ' ')
      left, right = get_columns(item)
      width = right - left
      width = width.negative? ? 0 : width

      content = if fetch(item, :align, 'left') =~ /right/
                  content.rjust(width, pad_char)
                else
                  content.ljust(width, pad_char)
                end

      indent = fetch(item, :wrap_indent, '')
      content = if wrap
                  content.wrap2(width, indent: indent, color: nil)
                else
                  [content]
                end

      template = fetch(item, :template, '%content')

      # content.map! do |l|
      #   template.sub(/%content/, l).gsub(/%[a-z]+/) do |m|
      #     if Doing::Color.respond_to?(m.sub(/^%/, ''))
      #       Doing::Color.send(m.sub(/^%/, ''))
      #     else
      #       m
      #     end
      #   end
      # end

      content
    end

    def self.get_columns(element)
      return [-1, -1] if element.nil?

      return [-1, -1] unless @elements.index(element.to_s)

      max = TTY::Screen.columns

      left = fetch(element, :column, -1).to_i
      width = fetch(element, :width, 0).to_i
      if width&.positive?
        right = left + width
        right = right < max ? right : max
      else
        right = if @elements[@elements.index(element.to_s) + 1] == 'note'
                  TTY::Screen.columns
                else
                  fetch(@elements[@elements.index(element.to_s) + 1], :column, 0).to_i - 1
                end
      end

      right = TTY::Screen.columns - 1 if right < 0
      [left, right]
    end

    # TODO: Need to handle prefix and suffix

    # TODO: Would be nice if colors could be used in
    # template string, but not sure how to do that yet

    # TODO: Note colors need separate handling, need to
    # figure out what line the note starts on in the array
    # and insert colors there


    def self.render2(wwid, items, opt)
      lines = 1
      out = []

      items.each do |item|
        @title = format_placeholder(:title, item.title)
        note = item.note.compress.strip_lines
        @note = format_placeholder(:note, note)
        @note.unshift('')

        interval_t = wwid.get_interval(item, record: true, formatted: false) if opt[:times]
        duration_t = item.duration if opt[:duration]

        if interval_t
          case opt[:interval_format].to_sym
          when :human
            _d, h, m = wwid.format_time(interval_t, human: true)
            interval_t = format('%<h> 4dh %<m>02dm', h: h, m: m)
          else
            d, h, m = wwid.format_time(interval_t)
            interval_t = format('%<d>02d:%<h>02d:%<m>02d', d: d, h: h, m: m)
          end
        elsif duration_t
          case opt[:interval_format].to_sym
          when :human
            _d, h, m = wwid.format_time(duration_t, human: true)
            duration_t = format('%<h> 4dh %<m>02dm', h: h, m: m)
          else
            d, h, m = wwid.format_time(interval)
            duration_t = format('%<d>02d:%<h>02d:%<m>02d', d: d, h: h, m: m)
          end
        end

        @interval = format_placeholder(:interval, interval_t)
        @duration = format_placeholder(:duration, duration_t)

        @section = format_placeholder(:section, item.section)

        date = if opt[:format] =~ /%?shortdate/
                 item.date.relative_date
               else
                 item.date.strftime(opt[:format])
               end
        @date = format_placeholder(:date, date)
        p @date

        lines = 1
        line_length = TTY::Screen.columns
        lines = @elements.map do |e|
          el = instance_variable_get("@#{e}")
          el.nil? ? 0 : el.count
        end.max

        item_out = Array.new(lines)
        lines.times { |i| item_out[i] = ' ' * line_length }
        left = 0
        right = line_length - 1
        colors = []

        @elements.each do |e|
          content = instance_variable_get("@#{e}")
          el_width = content.map(&:length).max || 0
          l, r = get_columns(e)
          left = l.positive? ? l : left
          right = if r.positive?
                    r
                  else
                    if left + el_width > line_length - 1
                      line_length - 1
                    else
                      left + el_width
                    end
                  end
          colors << { color: fetch(e, :color, 'default'), column: left, end: right } unless e == 'note'

          content.each_with_index do |line, idx|
            next if line.nil? || line.empty?

            width = right - left
            item_out[idx] = item_out[idx].ljust(line_length)
            item_out[idx][left..right] = line.slice(0, width)
          end
          left += el_width if left + el_width < line_length
        end

        colors = colors.sort_by { |a| a[:column] }.reverse

        item_out.map! do |line|
          colors.each do |c|
            next if c[:color].nil? || c[:color].empty?
            cs = c[:color].is_a?(Array) ? c[:color].join(' ') : c[:color]
            ca = cs.gsub(/,/, ' ').gsub(/ +/,' ').split(/ /)
            ci = ca.map { |color| Doing::Color.respond_to?(color) ? Doing::Color.send(color) : '' }.join('')
            line.insert(c[:end], Doing::Color.reset) if line.length > c[:end]
            line.insert(c[:column], ci) if line.length > c[:column]
          end
          line
        end

        out << item_out.join("\n")
      end

      out.join("\n") + Doing::Color.reset
    end

    def self.render(wwid, items, variables: {})
      return if items.nil?

      opt = variables[:options]

      fetch_placeholders(wwid.config, opt.fetch(:config_template, 'default'))
      tpl_ver = wwid.config.fetch('template_version', 1).to_f
      return render2(wwid, items, opt) if tpl_ver >= 2.0

      out = ''

      items.each do |item|
        if opt[:highlight] && item.title =~ /@#{wwid.config['marker_tag']}\b/i
          # flag = Doing::Color.send(wwid.config['marker_color'])
          reset = Doing::Color.default
        else
          # flag = ''
          reset = ''
        end

        if (!item.note.empty?) && wwid.config['include_notes']
          note = item.note.map(&:strip).delete_if(&:empty?)
          note.map! { |line| "#{line.sub(/^\t*/, '')}  " }

          if opt[:wrap_width]&.positive?
            width = opt[:wrap_width]
            note.map! { |line| line.chomp.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n") }
            note = note.join("\n").split(/\n/).delete_if(&:empty?)
          end
        else
          note = []
        end

        output = opt[:template].dup
        output.gsub!(/%[a-z]+/) do |m|
          if Doing::Color.respond_to?(m.sub(/^%/, ''))
            Doing::Color.send(m.sub(/^%/, ''))
          else
            m
          end
        end

        output.sub!(/%(\d+)?date/) do
          pad = Regexp.last_match(1).to_i
          format("%#{pad}s", item.date.strftime(opt[:format]))
        end

        interval = wwid.get_interval(item, record: true, formatted: false) if opt[:times]
        if interval
          case opt[:interval_format].to_sym
          when :human
            _d, h, m = wwid.format_time(interval, human: true)
            interval = format('%<h> 4dh %<m>02dm', h: h, m: m)
          else
            d, h, m = wwid.format_time(interval)
            interval = format('%<d>02d:%<h>02d:%<m>02d', d: d, h: h, m: m)
          end
        end

        interval ||= ''

        output.sub!(/%interval/, interval)

        duration = item.duration if opt[:duration]
        if duration
          case opt[:interval_format].to_sym
          when :human
            _d, h, m = wwid.format_time(duration, human: true)
            duration = format('%<h> 4dh %<m>02dm', h: h, m: m)
          else
            d, h, m = wwid.format_time(duration)
            duration = format('%<d>02d:%<h>02d:%<m>02d', d: d, h: h, m: m)
          end
        end
        duration ||= ''
        output.sub!(/%duration/, duration)

        output.sub!(/%(\d+)?shortdate/) do
          pad = Regexp.last_match(1) || 13
          format("%#{pad}s", item.date.relative_date)
        end

        output.sub!(/%section/, item.section) if item.section

        title_rx = /(?mi)%(?<width>-?\d+)?(?:(?<ichar>[ _t])(?<icount>\d+))?(?<prefix>.[ _t]?)?title(?<after>.*?)$/
        title_color = Doing::Color.reset + output.match(/(?mi)^(.*?)(%.*?title)/)[1].last_color

        title_offset = Doing::Color.uncolor(output).match(title_rx).begin(0)

        output.sub!(title_rx) do
          m = Regexp.last_match

          after = m['after']
          pad = m['width'].to_i
          indent = ''
          if m['ichar']
            char = m['ichar'] =~ /t/ ? "\t" : ' '
            indent = char * m['icount'].to_i
          end
          prefix = m['prefix']
          if opt[:wrap_width]&.positive? || pad.positive?
            width = pad.positive? ? pad : opt[:wrap_width]
            item.title.wrap(width, pad: pad, indent: indent, offset: title_offset, prefix: prefix, color: title_color, after: after, reset: reset)
            # flag + item.title.gsub(/(.{#{opt[:wrap_width]}})(?=\s+|\Z)/, "\\1\n ").sub(/\s*$/, '') + reset
          else
            format("%s%#{pad}s%s", prefix, item.title.sub(/\s*$/, ''), after)
          end
        end

        # output.sub!(/(?i-m)^([\s\S]*?)(%(?:[io]d|(?:\^[\s\S])?(?:(?:[ _t]|[^a-z0-9])?\d+)?(?:[\s\S][ _t]?)?)?note)([\s\S]*?)$/, '\1\3\2')
        if opt[:tags_color]
          output.highlight_tags!(opt[:tags_color])
        end

        if note.empty?
          output.gsub!(/%(chomp|[io]d|(\^.)?(([ _t]|[^a-z0-9])?\d+)?(.[ _t]?)?)?note/, '')
        else
          output.sub!(/%note/, "\n#{note.map { |l| "\t#{l.strip}  " }.join("\n")}")
          output.sub!(/%idnote/, "\n#{note.map { |l| "\t\t#{l.strip}  " }.join("\n")}")
          output.sub!(/%odnote/, "\n#{note.map { |l| "#{l.strip}  " }.join("\n")}")
          output.sub!(/(?mi)%(?:\^(?<mchar>.))?(?:(?<ichar>[ _t]|[^a-z0-9])?(?<icount>\d+))?(?<prefix>.[ _t]?)?note/) do
            m = Regexp.last_match
            mark = m['mchar'] || ''
            indent = if m['ichar']
                       char = m['ichar'] =~ /t/ ? "\t" : ' '
                       char * m['icount'].to_i
                     else
                       ''
                     end
            prefix = m['prefix'] || ''
            "\n#{note.map { |l| "#{mark}#{indent}#{prefix}#{l.strip}  " }.join("\n")}"
          end

          output.sub!(/%chompnote/) do
            note.map { |l| l.gsub(/\n+/, ' ').gsub(/(^\s*|\s*$)/, '').gsub(/\s+/, ' ') }.join(' ')
          end
        end

        output.gsub!(/%hr(_under)?/) do
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

      # Doing.logger.debug('Template Export:', "#{items.count} items output to template #{opt[:template]}")
      out += wwid.tag_times(format: wwid.config['timer_format'].to_sym, sort_by_name: opt[:sort_tags], sort_order: opt[:tag_order]) if opt[:totals]
      out
    end

    Doing::Plugins.register ['template', 'doing'], :export, self
  end
end
