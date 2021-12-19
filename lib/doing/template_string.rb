# frozen_string_literal: true

module Doing
  ##
  ## Template string formatting
  ##
  class TemplateString < String
    class ::String
      ##
      ## Extract the longest valid color from a string.
      ##
      ## Allows %colors to bleed into other text and still
      ## be recognized, e.g. %greensomething still finds
      ## %green.
      ##
      ## @return     [String] a valid color name
      ## @api private
      def validate_color
        valid_color = nil
        compiled = ''
        split('').each do |char|
          compiled += char
          valid_color = compiled if Color.attributes.include?(compiled.to_sym)
        end

        valid_color
      end
    end

    attr_reader :original

    include Color
    def initialize(string, placeholders: {}, force_color: false, wrap_width: 0)
      Color.coloring = true if force_color
      @colors = nil
      @original = string
      super(string)

      placeholders.each { |k, v| fill(k, v, wrap_width: wrap_width) }
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

      scan(/(?<!\\)(%([a-z]+))/).each do |color|
        valid_color = color[1].validate_color
        next unless valid_color

        idx = working.match(/(?<!\\)%#{valid_color}/).begin(0)
        color_array.push({ name: valid_color, color: Color.send(valid_color), index: idx })
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

    def fill(placeholder, value, wrap_width: 0)
      reparse
      # /(?mi)%(?:\^(?<mchar>.))?(?:(?<ichar>[ _t]|[^a-z0-9])?(?<icount>\d+))?(?<prefix>.[ _t]?)?note/
      rx = /(?mi)%(?<width>-?\d+)?(?:\^(?<mchar>.))?(?:(?<ichar>[ _t]|[^a-z0-9])(?<icount>\d+))?(?<prefix>.[ _t]?)?#{placeholder.sub(/^%/, '')}(?<after>.*?)$/
      ph = raw.match(rx)

      return unless ph

      placeholder_offset = ph.begin(0)
      # last_color = parsed_colors[:colors].select { |v| v[:index] <= placeholder_offset }.last[:name]
      sub!(rx) do
        m = Regexp.last_match

        after = m['after']

        if value.nil? || value.empty?
          after
        else
          pad = m['width'].to_i
          mark = m['mchar'] || ''
          if placeholder == 'shortdate' && m['width'].nil?
            pad = 13
          end
          indent = nil
          if m['ichar']
            char = m['ichar'] =~ /t/ ? "\t" : ' '
            indent = char * m['icount'].to_i
          end
          indent ||= "\t"
          prefix = m['prefix']
          if placeholder =~ /^title/
            if wrap_width.positive? || pad.positive?
              width = pad.positive? ? pad : wrap_width
              value.gsub(/%/, '\%').wrap(width, pad: pad, indent: indent, offset: placeholder_offset, prefix: prefix, color: '', after: after, reset: reset)
              # flag + item.title.gsub(/(.{#{opt[:wrap_width]}})(?=\s+|\Z)/, "\\1\n ").sub(/\s*$/, '') + reset
            else
              format("%s%#{pad}s%s", prefix, value.gsub(/%/, '\%').sub(/\s*$/, ''), after)
            end
          elsif placeholder =~ /^note/
            "\n#{value.map { |l| "#{mark}#{indent}#{prefix}#{l.strip}  " }.join("\n")}"
          else
            format("%s%#{pad}s%s", prefix, value.gsub(/%/, '\%').sub(/\s*$/, ''), after)
          end
        end
      end
      @parsed_colors = parse_colors
    end
  end
end
