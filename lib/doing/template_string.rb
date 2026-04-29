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

      @stretch_widths = stretch_widths(placeholders)
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
      placeholder_name = placeholder.sub(/^%/, '')
      rx = /(?mi)(?<!\\)%(?<width>\*|-?\d+)?(?:\^(?<mchar>.))?(?:(?<ichar>[ _t]|[^a-z0-9])(?<icount>\d+))?(?<prefix>.[ _t]?)?#{placeholder_name}(?<after>.*?)$/
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
          pad = m['width'] == '*' ? next_stretch_width(placeholder_name) : m['width'].to_i
          mark = m['mchar'] || ''
          if placeholder_name == 'shortdate' && m['width'].nil?
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

    private

    def stretch_widths(placeholders)
      keys = placeholders.keys.map { |k| Regexp.escape(k.sub(/^%/, '')) }.sort_by(&:length).reverse
      return {} if keys.empty?

      token_rx = /(?<!\\)%(?<width>\*|-?\d+)?(?:\^(?<mchar>.))?(?:(?<ichar>[ _t]|[^a-z0-9])(?<icount>\d+))?(?<prefix>.[ _t]?)?(?<name>#{keys.join('|')})/
      queues = Hash.new { |h, k| h[k] = [] }
      terminal_width = detected_terminal_width
      raw.each_line do |line|
        tokens = line.to_enum(:scan, token_rx).map { Regexp.last_match.dup }
        next if tokens.empty?

        literal_width = visible_literal_width(line.gsub(token_rx, ''))
        reserved_width = literal_width
        stretch_tokens = []

        tokens.each do |token|
          width_token = token['width']
          name = token['name']
          value = placeholders[name] || placeholders["%#{name}"]
          natural = natural_placeholder_width(name, value)
          if width_token == '*'
            if block_placeholder?(name)
              queues[name] << block_placeholder_width(terminal_width, token)
            else
              stretch_tokens << token
            end
          else
            reserved_width += reserved_placeholder_width(width_token, natural)
          end
        end

        next if stretch_tokens.empty?

        remaining = terminal_width - reserved_width
        widths = split_stretch_widths(remaining, stretch_tokens.length)
        stretch_tokens.each_with_index do |token, idx|
          queues[token['name']] << widths[idx]
        end
      end

      queues
    end

    def split_stretch_widths(remaining, count)
      return [] if count.zero?
      return Array.new(count, 1) if remaining < count

      base = remaining / count
      extra = remaining % count
      Array.new(count) { |idx| base + (idx < extra ? 1 : 0) }
    end

    def natural_placeholder_width(name, value)
      # note placeholders are rendered on their own wrapped lines and should not
      # reserve horizontal width on the title line
      return 0 if block_placeholder?(name)
      return 0 unless value.good?

      normalized = if name =~ /^tags/ && value.respond_to?(:map)
                     value.map(&:to_s).join(' ')
                   elsif value.respond_to?(:join)
                     value.join("\n")
                   else
                     value.to_s
                   end

      normalized.split("\n").map { |line| visible_literal_width(line) }.max || 0
    end

    def reserved_placeholder_width(width_token, natural_width)
      return natural_width if width_token.nil? || width_token.empty?

      minimum = width_token.to_i.abs
      [natural_width, minimum].max
    end

    def block_placeholder?(name)
      %w[note idnote odnote].include?(name)
    end

    def block_placeholder_width(terminal_width, token)
      padding = block_placeholder_padding(token)
      [terminal_width - padding, 1].max
    end

    def block_placeholder_padding(token)
      indent = if token['ichar']
                 char = token['ichar'] =~ /t/ ? "\t" : ' '
                 char * token['icount'].to_i
               else
                 "\t"
               end

      visible_literal_width("#{indent}#{token['prefix']}")
    end

    def next_stretch_width(name)
      widths = @stretch_widths[name]
      return 1 if widths.nil? || widths.empty?

      [widths.shift.to_i, 1].max
    end

    def visible_literal_width(string)
      visible = strip_template_colors(string).gsub(/\\(%)/, '\1')
      visible.uncolor.length
    end

    def detected_terminal_width
      if $stdout.tty?
        begin
          require 'io/console'
          console = IO.console
          width = console.winsize[1].to_i if console
          return width if width&.positive?
        rescue StandardError
          # Fall through to tty-screen detection.
        end
      end

      tty_width = TTY::Screen.columns.to_i
      return tty_width if tty_width.positive?

      env_width = ENV['COLUMNS'].to_i
      return env_width if env_width.positive?

      80
    end

    def strip_template_colors(string)
      working = string.dup
      string.scan(/(?<!\\)(%((?:[fb]g?)?#[a-fA-F0-9]{6}|[a-z]+))/).each do |color|
        valid_color = color[1].validate_color
        next unless valid_color

        working.sub!(/(?<!\\)%#{valid_color}/, '')
      end
      working
    end
  end
end
