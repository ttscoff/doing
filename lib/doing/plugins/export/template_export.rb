# frozen_string_literal: true

# title: Template Export
# description: Default export option using configured template placeholders
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  # Console export
  class TemplateExport
    include Doing::Color
    include Doing::Util

    attr_accessor :config, :template

    VALID_ELEMENTS = %w[date title section duration note].freeze
    PLACEHOLDER_DEFAULTS = {
      date: {
        width: 'auto',
        truncate: 'end',
        align: 'left',
        template: '%content |',
        format: '%Y-%m-%d %_I:%M%P'
      },
      title: {
        width: 'stretch',
        truncate: 'end',
        align: 'left',
        template: '%content',
        wrap_indent: 0,
        wrap_indent_char: ' '
      },
      section: {
        width: 'auto',
        truncate: 'end',
        align: 'left',
        template: '[%content]'
      },
      interval: {
        width: 'auto',
        truncate: 'end',
        align: 'left',
        template: '%content',
        format: 'text'
      },
      note: {
        width: 'stretch',
        truncate: 'end',
        align: 'left',
        template: '%content',
        column: 'title',
        indent: 1,
        indent_char: 'tab',
        wrap_indent: 0,
        wrap_indent_char: ' '
      }
    }.deep_freeze

    def self.settings
      {
        trigger: 'template|doing'
      }
    end

    def self.elements
      @elements ||= elements_from_config
    end

    def self.placeholders
      @placeholders ||= placeholders_from_config
    end

    def self.placeholders_from_config
      ph = {}

      elements.each do |el|
        ph = config.dig('templates', template, 'placeholders', el.to_s)
        ph.deep_merge(config.dig('templates', 'default', 'placeholders', el.to_s))
        ph.deep_merge(PLACEHOLDER_DEFAULTS[el.to_sym])
        ph[el.to_sym] = ph.symbolize_keys
      end

      ph
    end

    def self.elements_from_config
      raise 'Template is undefined' if template.nil?

      template_elements = config.dig('templates', template, 'elements')
      template_elements ||= config.dig('templates', 'default', 'elements') if tpl != 'default'

      raise "Elements is undefined for template #{template}" unless template_elements

      template_elements.select { |el| VALID_ELEMENTS.include?(el) }.map(&:to_sym)
    end

    def self.fetch(element, setting, default = nil)
      return nil if element.nil?

      t = placeholders.fetch(element.to_sym, nil)
      return nil if t.nil?

      t.fetch(setting.to_sym, default)
    end

    def self.format_placeholder(item, content)
      return [content] if placeholders.nil?

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

      _template = fetch(item, :template, '%content')
      content = _template.sub(/%content/, content)

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



      content
    end

    def self.get_columns(element)
      return [-1, -1] if element.nil?

      return [-1, -1] unless elements.index(element.to_s)

      max = TTY::Screen.columns

      left = fetch(element, :column, -1).to_i
      width = fetch(element, :width, 0).to_i
      if width&.positive?
        right = left + width
        right = right < max ? right : max
      else
        right = if elements[elements.index(element.to_s) + 1] == 'note'
                  TTY::Screen.columns
                else
                  fetch(elements[elements.index(element.to_s) + 1], :column, 0).to_i - 1
                end
      end

      right = TTY::Screen.columns - 1 if right < 0
      [left, right]
    end

    def self.content_for(el, item)
      case el
      when :date
        item.date
      when :title
        item.title
      when :interval
        item.interval || item.duration
      when :section
        item.section
      when :note
        item.note
      else
        nil
      end
    end

    def self.max_widths(content)
      # calculate max widths for each element
      widths = {}

      content.each do |item|
        elements.each do |el|
          e = item.select { |i| i[el] }
          widths[el] ||= 0
          widths[el] = e[:width] if e[:width] > widths[el]
        end
      end
    end

    def self.measure(content, width, tpl)
      val = tpl.sub(/%content/, content.uncolor)
      val.sub!(/%pad/, '')
      val.gsub!(/%(\w+)/) { |m| Doing::Color.respond_to?(m[1]) ? '' : m[0] }
      val.length
    end

    def self.item_array(item)
      # gather content and widths for each element
      elements.each_with_object([]) do |el, item_arr|
        content = content_for(el, item)
        tpl = fetch(el, :template, '%content')
        item_arr << {
          el: el,
          template: tpl,
          content: content,
          width: measure(content, tpl),
          placeholders: placeholders.fetch(el.to_sym)
        }
      end
    end

    # TODO: This whole thing needs to be redone. It
    # shouldn't use "column", it should use width, and
    # elements should be stacked.
    #
    # <x-nvultra://open?notebook=/Users/ttscoff/Library/Mobile%20Documents/9CR7T2DMDG~com~ngocluu~onewriter/Documents/nvALT2.2&note=doing%20template%20version%202.md>

    def self.render2(wwid, items, opt)
      @config = wwid.config
      @template = opt.fetch(:config_template, 'default')

      # create an array of arrays
      # each item is an array of hashes, one for each element
      content = items.each_with_object([]) { |item, out| out << item_array(item) }

      widths = max_widths(content)

      max = TTY::Screen.columns

      available_width = max

      stretches = placeholders.select { |p, h| h[:width] =~ /^stretch/ }.map { |p, h| p }
      autos = placeholders.select { |p, h| h[:width] =~ /^auto/ }.map { |p, h| p }

      # calculate known widths
      elements.each do |el|
        known_width = 0
        placeholders.each do |ph|
          width = case ph[el][:width].to_s
                  when /^[0-9]+$/
                    ph[:width]
                  when /^(\d+)%$/
                    f = Regexp.last_match(1).to_f / 100
                    max * f
                  when /0?\.\d+/
                    max * width.to_f
                  else
                    0
                  end
          known_width += width
        end
        available_width -= known_width
      end

      # calculate autos and stretches

      auto_width = 0
      autos.each { |a| auto_width += max_widths[a] }
      content.map! do |item|
        item.map! do |element|
          item[:width] = case element[:placeholders][:width].to_s
          when /^auto$/i
            if stretches.count.positive?
              max_widths[element]
            else
              available_width / autos.count
            end
          when /^stretch$/i
            (available_width - auto_width) / stretches.count
          when /^[0-9]+$/
            Regexp.last_match(0).to_i
          when /^(\d+)%$/
            f = Regexp.last_match(1).to_f / 100
            max * f
          when /0?\.\d+/
            max * width.to_f
          end
        end
      end

      # At this point we have an array of items
      # each item is an array of elements
      # each element has a :width
      # create an array of arrays, one index for each of max lines, each line an array
      # now we render each element to an array based on :template and :width, wrapping to multiple array elements for lines
      # and padding to width based on :align and %pad in template. add each line to appropriate array.
      # calculate longest array (of lines) and pad all element arrays to that length, make sure all elements are padded to :width
      # one all content is rendered, just join the elements for each line

      left_col = 0
      content.map! do |item|
        item.map! do |element|
          element[:left_col] = left_col
          left_col += element[:width]
          element[:righ_col] = left_col
        end
      end

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

        lines = 1
        line_length = TTY::Screen.columns
        lines = elements.map do |e|
          el = instance_variable_get("@#{e}")
          el.nil? ? 0 : el.count
        end.max

        item_out = Array.new(lines)
        lines.times { |i| item_out[i] = ' ' * line_length }
        left = 0
        right = line_length - 1
        colors = []

        elements.each do |e|
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

      tpl_ver = wwid.config.fetch('template_version', 1).to_f
      return render2(wwid, items, opt) if tpl_ver >= 2.0

      out = ''

      items.each do |item|
        if opt[:highlight] && item.title =~ /@#{wwid.config['marker_tag']}\b/i
          flag = Doing::Color.send(wwid.config['marker_color'])
          reset = Doing::Color.reset + Doing::Color.default
        else
          flag = ''
          reset = ''
        end

        placeholders = {}

        if (!item.note.empty?) && wwid.config['include_notes']
          note = item.note.map(&:strip).delete_if(&:empty?)
          note.map! { |line| "#{line.sub(/^\t*/, '')}  " }

          if opt[:wrap_width]&.positive?
            width = opt[:wrap_width]
            note.map! do |line|
              line.simple_wrap(width)
              # line.chomp.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
            end
            note = note.delete_if(&:empty?)
          end
        else
          note = []
        end

        # output.sub!(/%(\d+)?date/) do
        #   pad = Regexp.last_match(1).to_i
        #   format("%#{pad}s", item.date.strftime(opt[:format]))
        # end
        placeholders['date'] = item.date.strftime(opt[:format])

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
        # output.sub!(/%interval/, interval)
        placeholders['interval'] = interval

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
        # output.sub!(/%duration/, duration)
        placeholders['duration'] = duration

        # output.sub!(/%(\d+)?shortdate/) do
        #   pad = Regexp.last_match(1) || 13
        #   format("%#{pad}s", item.date.relative_date)
        # end
        placeholders['shortdate'] = format("%13s", item.date.relative_date)
        # output.sub!(/%section/, item.section) if item.section
        placeholders['section'] = item.section || ''
        placeholders['title'] = item.title

        # title_rx = /(?mi)%(?<width>-?\d+)?(?:(?<ichar>[ _t])(?<icount>\d+))?(?<prefix>.[ _t]?)?title(?<after>.*?)$/
        # title_color = Doing::Color.reset + output.match(/(?mi)^(.*?)(%.*?title)/)[1].last_color

        # title_offset = Doing::Color.uncolor(output).match(title_rx).begin(0)

        # output.sub!(title_rx) do
        #   m = Regexp.last_match

        #   after = m['after']
        #   pad = m['width'].to_i
        #   indent = ''
        #   if m['ichar']
        #     char = m['ichar'] =~ /t/ ? "\t" : ' '
        #     indent = char * m['icount'].to_i
        #   end
        #   prefix = m['prefix']
        #   if opt[:wrap_width]&.positive? || pad.positive?
        #     width = pad.positive? ? pad : opt[:wrap_width]
        #     item.title.wrap(width, pad: pad, indent: indent, offset: title_offset, prefix: prefix, color: title_color, after: after, reset: reset)
        #     # flag + item.title.gsub(/(.{#{opt[:wrap_width]}})(?=\s+|\Z)/, "\\1\n ").sub(/\s*$/, '') + reset
        #   else
        #     format("%s%#{pad}s%s", prefix, item.title.sub(/\s*$/, ''), after)
        #   end
        # end



        placeholders['note'] = note
        placeholders['idnote'] = note.empty? ? '' : "\n#{note.map { |l| "\t\t#{l.strip}  " }.join("\n")}"
        placeholders['odnote'] = note.empty? ? '' : "\n#{note.map { |l| "#{l.strip}  " }.join("\n")}"
        placeholders['chompnote'] = note.empty? ? '' : note.map { |l| l.gsub(/\n+/, ' ').gsub(/(^\s*|\s*$)/, '').gsub(/\s+/, ' ') }.join(' ')

        # if note.empty?
        #   output.gsub!(/%(chomp|[io]d|(\^.)?(([ _t]|[^a-z0-9])?\d+)?(.[ _t]?)?)?note/, '')
        # else
        #   output.sub!(/%note/, "\n#{note.map { |l| "\t#{l.strip}  " }.join("\n")}")
        #   output.sub!(/%idnote/, "\n#{note.map { |l| "\t\t#{l.strip}  " }.join("\n")}")
        #   output.sub!(/%odnote/, "\n#{note.map { |l| "#{l.strip}  " }.join("\n")}")
        #   output.sub!(/(?mi)%(?:\^(?<mchar>.))?(?:(?<ichar>[ _t]|[^a-z0-9])?(?<icount>\d+))?(?<prefix>.[ _t]?)?note/) do
        #     m = Regexp.last_match
        #     mark = m['mchar'] || ''
        #     indent = if m['ichar']
        #                char = m['ichar'] =~ /t/ ? "\t" : ' '
        #                char * m['icount'].to_i
        #              else
        #                ''
        #              end
        #     prefix = m['prefix'] || ''
        #     "\n#{note.map { |l| "#{mark}#{indent}#{prefix}#{l.strip}  " }.join("\n")}"
        #   end

        #   output.sub!(/%chompnote/) do
        #     note.map { |l| l.gsub(/\n+/, ' ').gsub(/(^\s*|\s*$)/, '').gsub(/\s+/, ' ') }.join(' ')
        #   end
        # end

        template = opt[:template].dup
        template.sub!(/(?i-m)^([\s\S]*?)(%(?:[io]d|(?:\^[\s\S])?(?:(?:[ _t]|[^a-z0-9])?\d+)?(?:[\s\S][ _t]?)?)?note)([\s\S]*?)$/, '\1\3\2')
        output = Doing::TemplateString.new(template, placeholders: placeholders, wrap_width: opt[:wrap_width], color: flag, tags_color: opt[:tags_color], reset: reset).colored

        output.gsub!(/(?<!\\)%hr(_under)?/) do
          o = ''
          `tput cols`.to_i.times do
            o += Regexp.last_match(1).nil? ? '-' : '_'
          end
          o
        end
        output.gsub!(/(?<!\\)%n/, "\n")
        output.gsub!(/(?<!\\)%t/, "\t")

        output.gsub!(/\\%/, '%')

        out += "#{output}\n"
      end

      # Doing.logger.debug('Template Export:', "#{items.count} items output to template #{opt[:template]}")
      out += wwid.tag_times(format: wwid.config['timer_format'].to_sym, sort_by_name: opt[:sort_tags], sort_order: opt[:tag_order]) if opt[:totals]
      out
    end

    Doing::Plugins.register ['template', 'doing'], :export, self
  end
end
