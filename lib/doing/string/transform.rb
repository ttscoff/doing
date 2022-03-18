# frozen_string_literal: true

module Doing
  ##
  ## String helpers
  ##
  module StringTransform
    # Compress multiple spaces to single space
    def compress
      gsub(/ +/, ' ').strip
    end

    def compress!
      replace compress
    end

    def simple_wrap(width)
      str = gsub(/@\S+\(.*?\)/) { |tag| tag.gsub(/\s/, '%%%%') }
      words = str.split(/ /).map { |word| word.gsub(/%%%%/, ' ') }
      out = []
      line = []

      words.each do |word|
        if word.uncolor.length >= width
          chars = word.uncolor.split('')
          out << chars.slice!(0, width - 1).join('') while chars.count >= width
          line << chars.join('')
          next
        elsif line.join(' ').uncolor.length + word.uncolor.length + 1 > width
          out.push(line.join(' '))
          line.clear
        end

        line << word.uncolor
      end
      out.push(line.join(' '))
      out.join("\n")
    end

    ##
    ## Wrap string at word breaks, respecting tags
    ##
    ## @param      len     [Integer] The length
    ## @param      offset  [Integer] (Optional) The width to pad each subsequent line
    ## @param      prefix  [String] (Optional) A prefix to add to each line
    ##
    def wrap(len, pad: 0, indent: '  ', offset: 0, prefix: '', color: '', after: '', reset: '', pad_first: false)
      last_color = color.empty? ? '' : after.last_color
      note_rx = /(?mi)(?<!\\)%(?<width>-?\d+)?(?:\^(?<mchar>.))?(?:(?<ichar>[ _t]|[^a-z0-9])(?<icount>\d+))?(?<prefix>.[ _t]?)?note/
      note = ''
      after = after.dup if after.frozen?
      after.sub!(note_rx) do
        note = Regexp.last_match(0)
        ''
      end

      left_pad = ' ' * offset
      left_pad += indent

      # return "#{left_pad}#{prefix}#{color}#{self}#{last_color} #{note}" unless len.positive?

      # Don't break inside of tag values
      str = gsub(/@\S+\(.*?\)/) { |tag| tag.gsub(/\s/, '%%%%') }.gsub(/\n/, ' ')

      words = str.split(/ /).map { |word| word.gsub(/%%%%/, ' ') }
      out = []
      line = []

      words.each do |word|
        if word.uncolor.length >= len
          chars = word.uncolor.split('')
          out << chars.slice!(0, len - 1).join('') while chars.count >= len
          line << chars.join('')
          next
        elsif line.join(' ').uncolor.length + word.uncolor.length + 1 > len
          out.push(line.join(' '))
          line.clear
        end

        line << word.uncolor
      end
      out.push(line.join(' '))

      last_color = ''
      out[0] = format("%-#{pad}s%s%s", out[0], last_color, after)

      out.map.with_index { |l, idx|
        if !pad_first && idx == 0
          "#{color}#{prefix}#{l}#{last_color}"
        else
          "#{left_pad}#{color}#{prefix}#{l}#{last_color}"
        end
      }.join("\n") + " #{note}".chomp
      # res.join("\n").strip + last_color + " #{note}".chomp
    end

    ##
    ## Capitalize on the first character on string
    ##
    ## @return     Capitalized string
    ##
    def cap_first
      sub(/^\w/) do |m|
        m.upcase
      end
    end

    ##
    ## Pluralize a string based on quantity
    ##
    ## @param      number  [Integer] the quantity of the
    ##                     object the string represents
    ##
    def to_p(number)
      number == 1 ? self : "#{self}s"
    end

    ##
    ## Convert a string value to an appropriate type. If
    ## kind is not specified, '[one, two]' becomes an Array,
    ## '1' becomes Integer, '1.5' becomes Float, 'true' or
    ## 'yes' becomes TrueClass, 'false' or 'no' becomes
    ## FalseClass.
    ##
    ## @param      kind  [String] specify string, array,
    ##                   integer, float, symbol, or boolean
    ##                   (falls back to string if value is
    ##                   not recognized)
    ## @return Converted object type
    def set_type(kind = nil)
      if kind
        case kind.to_s
        when /^a/i
          gsub(/^\[ *| *\]$/, '').split(/ *, */)
        when /^i/i
          to_i
        when /^(fa|tr)/i
          to_bool
        when /^f/i
          to_f
        when /^sy/i
          sub(/^:/, '').to_sym
        when /^b/i
          self =~ /^(true|yes)$/ ? true : false
        else
          to_s
        end
      else
        case self
        when /(^\[.*?\]$| *, *)/
          gsub(/^\[ *| *\]$/, '').split(/ *, */)
        when /^[0-9]+$/
          to_i
        when /^[0-9]+\.[0-9]+$/
          to_f
        when /^:\w+/
          sub(/^:/, '').to_sym
        when /^(true|yes)$/i
          true
        when /^(false|no)$/i
          false
        else
          to_s
        end
      end
    end

    def titlecase
      tr('_', ' ').
      gsub(/\s+/, ' ').
      gsub(/\b\w/){ $`[-1,1] == "'" ? $& : $&.upcase }
    end
  end
end
