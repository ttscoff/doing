# frozen_string_literal: true

# Cribbed from <https://github.com/flori/term-ansicolor>
module Doing
  # Terminal output color functions.
  module Color
    ESCAPE_REGEX = /\e\[[0-9;]*m/.freeze
    # All available color names. Available as methods and string extensions.
    #
    # @example Use a color as a method. Color reset will be added to end of string.
    #   Color.yellow('This text is yellow') => "\e[33mThis text is yellow\e[0m"
    #
    # @example Use a color as a string extension. Color reset added automatically.
    #   'This text is green'.green => "\e[1;32mThis text is green\e[0m"
    #
    # @example Send a text string as a color
    #   Color.send('red') => "\e[31m"
    ATTRIBUTES = [
      [:clear,               0], # String#clear is already used to empty string in Ruby 1.9
      [:reset,               0], # synonym for :clear
      [:bold,                1],
      [:dark,                2],
      [:italic,              3], # not widely implemented
      [:underline,           4],
      [:underscore,          4], # synonym for :underline
      [:blink,               5],
      [:rapid_blink,         6], # not widely implemented
      [:negative,            7], # no reverse because of String#reverse
      [:concealed,           8],
      [:strikethrough,       9], # not widely implemented
      [:strike,              9], # not widely implemented
      [:black,              30],
      [:red,                31],
      [:green,              32],
      [:yellow,             33],
      [:blue,               34],
      [:magenta,            35],
      [:purple,             35],
      [:cyan,               36],
      [:white,              37],
      [:bgblack,            40],
      [:bgred,              41],
      [:bggreen,            42],
      [:bgyellow,           43],
      [:bgblue,             44],
      [:bgmagenta,          45],
      [:bgpurple,           45],
      [:bgcyan,             46],
      [:bgwhite,            47],
      [:boldblack,          90],
      [:boldred,            91],
      [:boldgreen,          92],
      [:boldyellow,         93],
      [:boldblue,           94],
      [:boldmagenta,        95],
      [:boldpurple,         95],
      [:boldcyan,           96],
      [:boldwhite,          97],
      [:boldbgblack,       100],
      [:boldbgred,         101],
      [:boldbggreen,       102],
      [:boldbgyellow,      103],
      [:boldbgblue,        104],
      [:boldbgmagenta,     105],
      [:boldbgpurple,      105],
      [:boldbgcyan,        106],
      [:boldbgwhite,       107],
      [:softpurple,  '0;35;40'],
      [:hotpants,    '7;34;40'],
      [:knightrider, '7;30;40'],
      [:flamingo,    '7;31;47'],
      [:yeller,      '1;37;43'],
      [:whiteboard,  '1;30;47'],
      [:chalkboard,  '1;37;40'],
      [:led,         '0;32;40'],
      [:redacted,    '0;30;40'],
      [:alert,       '1;31;43'],
      [:error,       '1;37;41'],
      [:default, '0;39']
    ].map(&:freeze).freeze

    ATTRIBUTE_NAMES = ATTRIBUTES.transpose.first

    # Returns true if Doing::Color supports the +feature+.
    #
    # The feature :clear, that is mixing the clear color attribute into String,
    # is only supported on ruby implementations, that do *not* already
    # implement the String#clear method. It's better to use the reset color
    # attribute instead.
    def support?(feature)
      case feature
      when :clear
        !String.instance_methods(false).map(&:to_sym).include?(:clear)
      end
    end

    # Template coloring
    class ::String
      ##
      ## Extract the longest valid %color name from a string.
      ##
      ## Allows %colors to bleed into other text and still
      ## be recognized, e.g. %greensomething still finds
      ## %green.
      ##
      ## @return     [String] a valid color name
      ##
      def validate_color
        valid_color = nil
        compiled = ''
        normalize_color.split('').each do |char|
          compiled += char
          if Color.attributes.include?(compiled.to_sym) || compiled =~ /^([fb]g?)?#([a-f0-9]{6})$/i
            valid_color = compiled
          end
        end

        valid_color
      end

      ##
      ## Normalize a color name, removing underscores,
      ## replacing "bright" with "bold", and converting
      ## bgbold to boldbg
      ##
      ## @return     [String] Normalized color name
      ##
      def normalize_color
        gsub(/_/, '').sub(/bright/i, 'bold').sub(/bgbold/, 'boldbg')
      end

      # Get the calculated ANSI color at the end of the
      # string
      #
      # @return     ANSI escape sequence to match color
      #
      def last_color_code
        m = scan(ESCAPE_REGEX)

        em = ['0']
        fg = nil
        bg = nil
        rgbf = nil
        rgbb = nil

        m.each do |c|
          case c
          when '0'
            em = ['0']
            fg, bg, rgbf, rgbb = nil
          when /^[34]8/
            case c
            when /^3/
              fg = nil
              rgbf = c
            when /^4/
              bg = nil
              rgbb = c
            end
          else
            c.split(/;/).each do |i|
              x = i.to_i
              if x <= 9
                em << x
              elsif x >= 30 && x <= 39
                rgbf = nil
                fg = x
              elsif x >= 40 && x <= 49
                rgbb = nil
                bg = x
              elsif x >= 90 && x <= 97
                rgbf = nil
                fg = x
              elsif x >= 100 && x <= 107
                rgbb = nil
                bg = x
              end
            end
          end
        end

        escape = "\e[#{em.join(';')}m"
        escape += "\e[#{rgbb}m" if rgbb
        escape += "\e[#{rgbf}m" if rgbf
        escape + "\e[#{[fg, bg].delete_if(&:nil?).join(';')}m"
      end

      # Define string extension methods for all color attributes
      ATTRIBUTES.each do |c, v|
        new_method = <<-EOSCRIPT
          def #{c}
            result = ''
            result << "\e[#{v}m" if Doing::Color.coloring?
            result << self
            result << "\e[0m" if Doing::Color.coloring?
            result
          end
        EOSCRIPT

        class_eval(new_method)

        next unless c =~ /bold/

        # Accept brightwhite in addition to boldwhite
        new_method = <<-EOSCRIPT
          def #{c.to_s.sub(/bold/, 'bright')}
            result = ''
            result << "\e[#{v}m" if Doing::Color.coloring?
            result << self
            result << "\e[0m" if Doing::Color.coloring?
            result
          end
        EOSCRIPT

        class_eval(new_method)
      end

      # Returns an uncolored version of the string, that is all
      # ANSI-sequences are stripped from the string.
      def uncolor
        gsub(ESCAPE_REGEX, '')
      end
    end

    class << self
      # Returns true if the coloring function of this module
      # is switched on, false otherwise.
      def coloring?
        @coloring.nil? ? true : @coloring
      end

      attr_writer :coloring

      ##
      ## Enables colored output
      ##
      ## @example Turn color on or off based on TTY
      ##   Doing::Color.coloring = STDOUT.isatty
      def coloring
        @coloring ||= true
      end

      ##
      ## Convert a template string to a colored string.
      ## Colors are specified with single letters inside
      ## curly braces. Uppercase changes background color.
      ##
      ## w: white, k: black, g: green, l: blue, y: yellow, c: cyan,
      ## m: magenta, r: red, b: bold, u: underline, i: italic,
      ## x: reset (remove background, color, emphasis)
      ##
      ## @example Convert a templated string
      ##   Color.template('{Rwb}Warning:{x} {w}you look a little {g}ill{x}')
      ##
      ## @param      input  [String, Array] The template
      ##                    string. If this is an array, the
      ##                    elements will be joined with a
      ##                    space.
      ##
      ## @return     [String] Colorized string
      ##
      def template(input)
        input = input.join(' ') if input.is_a? Array
        fmt = input.gsub(/%/, '%%')
        fmt = fmt.gsub(/(?<!\\u|\$)\{(\w+)\}/i) do
          Regexp.last_match(1).split('').map { |c| "%<#{c}>s" }.join('')
        end

        colors = { w: white, k: black, g: green, l: blue,
                   y: yellow, c: cyan, m: magenta, r: red,
                   W: bgwhite, K: bgblack, G: bggreen, L: bgblue,
                   Y: bgyellow, C: bgcyan, M: bgmagenta, R: bgred,
                   d: dark, b: bold, u: underline, i: italic, x: reset }

        fmt.empty? ? input : format(fmt, colors)
      end

      ATTRIBUTES.each do |c, v|
        new_method = <<-EOSCRIPT
          def #{c}(string = nil)
            result = ''
            result << "\e[#{v}m" if Doing::Color.coloring?
            if block_given?
              result << yield
            elsif string.respond_to?(:to_str)
              result << string.to_str
            elsif respond_to?(:to_str)
              result << to_str
            else
              return result #only switch on
            end
            result << "\e[0m" if Doing::Color.coloring?
            result
          end
        EOSCRIPT

        module_eval(new_method)

        next unless c =~ /bold/

        # Accept brightwhite in addition to boldwhite
        new_method = <<-EOSCRIPT
          def #{c.to_s.sub(/bold/, 'bright')}(string = nil)
            result = ''
            result << "\e[#{v}m" if Doing::Color.coloring?
            if block_given?
              result << yield
            elsif string.respond_to?(:to_str)
              result << string.to_str
            elsif respond_to?(:to_str)
              result << to_str
            else
              return result #only switch on
            end
            result << "\e[0m" if Doing::Color.coloring?
            result
          end
        EOSCRIPT

        module_eval(new_method)
      end

      # Returns an array of all Doing::Color attributes as symbols.
      def attributes
        ATTRIBUTE_NAMES
      end

      # Returns an uncolored version of the string, that is all
      # ANSI-sequences are stripped from the string.
      def uncolor(string)
        string.to_str.gsub(ESCAPE_REGEX, '')
      end
    end

    def rgb(hex)
      is_bg = hex.match(/^bg?#/) ? true : false
      hex_string = hex.sub(/^([fb]g?)?#/, '')

      parts = hex_string.match(/(?<r>..)(?<g>..)(?<b>..)/)
      t = []
      %w[r g b].each do |e|
        t << parts[e].hex
      end
      "\e[#{is_bg ? '48' : '38'};2;#{t.join(';')}m"
    end

    # Returns an uncolored version of the string, that is all
    # ANSI-sequences are stripped from the string.
    def uncolor(string = nil) # :yields:
      if block_given?
        yield.to_str.gsub(ESCAPE_REGEX, '')
      elsif string.respond_to?(:to_str)
        string.to_str.gsub(ESCAPE_REGEX, '')
      elsif respond_to?(:to_str)
        to_str.gsub(ESCAPE_REGEX, '')
      else
        ''
      end
    end
  end
end
