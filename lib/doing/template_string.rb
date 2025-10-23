# frozen_string_literal: true

module Doing
  ##
  ## Template string formatting
  ##
  class TemplateString < String
    attr_reader :original

    include Color
    def initialize(string, placeholders: {}, force_color: false, disable_color: false, wrap_width: 0, color: '', tags_color: '', reset: '')
      Color.coloring = true if force_color
      Color.coloring = false if disable_color
      @colors = nil
      @original = string
      super(Doing::Color.coloring? ? Color.reset + string : string)

      placeholders.each { |k, v| fill(k, v, wrap_width: wrap_width, color: color, tags_color: tags_color) }
    end

    ##
    ## Test if string contains any valid %colors
    ##
    ## @return     [Boolean] True if colors, False otherwise.
    ##
    def colors?
      scan(/%([a-z]+)/).each do
        return true if Regexp.last_match(1).validate_color
      end
      false
    end

    def reparse
      @parsed_colors = nil
    end

    ##
    ## Return string with %colors replaced with escape codes
    ##
    ## @return     [String] colorized string
    ##
    def colored
      reparse
      parsed_colors[:string].apply_colors(parsed_colors[:colors])
    end

    ##
    ## Remove all valid %colors from string
    ##
    ## @return     [String] cleaned string
    ##
    def raw
      parsed_colors[:string].uncolor
    end

    def parsed_colors
      @parsed_colors ||= parse_colors
    end

    ##
    ## Parse a template string for %colors and return a hash
    ## of colors and string locations
    ##
    ## @return     [Hash] Uncolored string and array of colors and locations
    def parse_colors
      working = dup
      color_array = []

      scan(/(?<!\\)(%((?:[fb]g?)?#[a-fA-F0-9]{6}|[a-z]+))/).each do |color|
        valid_color = color[1].validate_color
        next unless valid_color

        idx = working.match(/(?<!\\)%#{valid_color}/).begin(0)
        color = Color.attributes.include?(valid_color.to_sym) ? Color.send(valid_color) : Color.rgb(valid_color)
        color_array.push({ name: valid_color, color: color, index: idx })
        working.sub!(/(?<!\\)%#{valid_color}/, '')
      end

      { string: working, colors: color_array }
    end

    ##
    ## Apply a color array to a string
    ##
    ## @param      color_array  [Array] Array of hashes
    ##                          containing :name, :color,
    ##                          :index
    ##
    def apply_colors(color_array)
      str = dup
      color_array.reverse.each do |color|
        c = color[:color].empty? ? Color.send(color[:name]) : color[:color]
        str.insert(color[:index], c)
      end
      str
    end

    def fill(placeholder, value, wrap_width: 0, color: '', tags_color: '', reset: '')
      reparse
      rx = /(?mi)(?<!\\)%(?<width>-?\d+)?(?:\^(?<mchar>.))?(?:(?<ichar>[ _t]|[^a-z0-9])(?<icount>\d+))?(?<prefix>.[ _t]?)?#{placeholder.sub(
        /^%/, ''
      )}(?<after>.*?)$/
      ph = raw.match(rx)

      return unless ph

      placeholder_offset = ph.begin(0)
      last_colors = parsed_colors[:colors].select { |v| v[:index] <= placeholder_offset + 4 }

      last_color = last_colors.map { |v| v[:color] }.pop(3).join('')

      sub!(rx) do
        m = Regexp.last_match

        after = m['after']

        if !value.good?
          after
        else
          pad = m['width'].to_i
          mark = m['mchar'] || ''
          if placeholder == 'shortdate' && m['width'].nil?
            fmt_string = Doing.setting('shortdate_format.older', '%m/%d/%y %_I:%M%P', exact: true)
            pad = Date.today.strftime(fmt_string).length
          end
          indent = nil
          if m['ichar']
            char = m['ichar'] =~ /t/ ? "\t" : ' '
            indent = char * m['icount'].to_i
          end
          indent ||= placeholder =~ /^title/ ? '' : "\t"
          prefix = m['prefix']

          if placeholder =~ /^tags/
            prefix ||= ''
            value = value.map { |t| "#{prefix}#{t.sub(/^#{prefix}?/, '')}" }.join(' ')
            prefix = ''
          end

          if placeholder =~ /^title/
            color = last_color + color

            if wrap_width.positive? || pad.positive?
              width = pad.positive? ? pad : wrap_width

              out = value.gsub(/%/, '\%').strip.wrap(width,
                                                     pad: pad,
                                                     indent: indent,
                                                     offset: placeholder_offset,
                                                     prefix: prefix,
                                                     color: color,
                                                     after: after,
                                                     reset: reset,
                                                     pad_first: false)
            else
              out = format("%s%s%#{pad}s%s", prefix, color, value.gsub(/%/, '\%').sub(/\s*$/, ''), after)
            end
            out.highlight_tags!(tags_color, last_color: color) if tags_color && !tags_color.empty?
            out
          elsif placeholder =~ /^note/
            if wrap_width.positive? || pad.positive?
              width = pad.positive? ? pad : wrap_width
              outstring = value.map do |l|
                if l.empty?
                  '  '
                else
                  line = l.gsub(/%/, '\%').strip.wrap(width, pad: pad, indent: indent, offset: 0, prefix: prefix,
                                                             color: last_color, after: after, reset: reset, pad_first: true)
                  line.highlight_tags!(tags_color, last_color: last_color) unless !tags_color || !tags_color.good?
                  "#{line}  "
                end
              end.join("\n")
              "\n#{last_color}#{mark}#{outstring}  "
            else
              out = format("\n%s%s%s%#{pad}s%s", indent, prefix, last_color,
                           value.join("\n#{indent}#{prefix}").gsub(/%/, '\%').sub(/\s*$/, ''), after)
              out.highlight_tags!(tags_color, last_color: last_color) if tags_color && !tags_color.empty?
              out
            end
          else
            format("%s%#{pad}s%s", prefix, value.gsub(/%/, '\%').sub(/\s*$/, ''), after)
          end
        end
      end
      @parsed_colors = parse_colors
    end
  end
end
