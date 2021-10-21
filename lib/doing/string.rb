# frozen_string_literal: true

module Doing
  ##
  ## @brief      String helpers
  ##
  class ::String
    ##
    ## @brief      Test if line should be ignored
    ##
    ## @return     [Boolean] line is empty or comment
    ##
    def ignore?
      line = self
      line =~ /^#/ || line =~ /^\s*$/
    end

    ##
    ## @brief      Truncate to nearest word
    ##
    ## @param      len   The length
    ##
    def truncate(len, ellipsis: '...')
      return self if length <= len

      total = 0
      res = []

      split(/ /).each do |word|
        break if total + 1 + word.length > len

        total += 1 + word.length
        res.push(word)
      end
      res.join(' ') + ellipsis
    end

    ##
    ## @brief      Remove color escape codes
    ##
    ## @return     clean string
    ##
    def uncolor
      gsub(/\e\[[\d;]+m/,'')
    end

    def uncolor!
      replace uncolor
    end

    ##
    ## @brief      Wrap string at word breaks, respecting tags
    ##
    ## @param      len     [Integer] The length
    ## @param      offset  [Integer] (Optional) The width to pad each subsequent line
    ## @param      prefix  [String] (Optional) A prefix to add to each line
    ##
    def wrap(len, pad: 0, indent: '  ', offset: 0, prefix: '', after: '', reset: '')
      note_rx = /(?i-m)(%(?:[io]d|(?:\^[\s\S])?(?:(?:[ _t]|[^a-z0-9])?\d+)?(?:[\s\S][ _t]?)?)?note)/
      str = gsub(/@\w+\(.*?\)/) { |tag| tag.gsub(/\s/, '%%%%') }
      words = str.split(/ /).map { |word| word.gsub(/%%%%/, ' ') }
      out = []
      line = []
      words.each do |word|
        if line.join(' ').length + word.length + 1 > len
          out.push(line.join(' '))
          line.clear
        end

        line << word
      end
      out.push(line.join(' '))
      note = ''
      after.sub!(note_rx) do
        note = Regexp.last_match(0)
        ''
      end

      out[0] = format("%-#{pad}s%s", out[0], after)
      left_pad = ' ' * (offset)
      left_pad += indent
      out.map { |l| "#{left_pad}#{prefix}#{l}" }.join("\n").strip + " #{note}".chomp
    end

    ##
    ## @brief      Capitalize on the first character on string
    ##
    ## @return     Capitalized string
    ##
    def cap_first
      sub(/^\w/) do |m|
        m.upcase
      end
    end

    ##
    ## @brief      Convert a sort order string to a qualified type
    ##
    ## @return     (String) 'asc' or 'desc'
    ##
    def normalize_order!
      replace normalize_order
    end

    def normalize_order(default = 'asc')
      case self
      when /^a/i
        'asc'
      when /^d/i
        'desc'
      else
        default
      end
    end

    ##
    ## @brief      Convert a boolean string to a symbol
    ##
    ## @return     Symbol :and, :or, or :not
    ##
    def normalize_bool!
      replace normalize_bool
    end

    def normalize_bool(default = :and)
      case self
      when /(and|all)/i
        :and
      when /(any|or)/i
        :or
      when /(not|none)/i
        :not
      else
        default.is_a?(Symbol) ? default : default.normalize_bool
      end
    end

    def normalize_trigger!
      replace normalize_trigger
    end

    def normalize_trigger
      gsub(/\((?!\?:)/, '(?:').downcase
    end

    ##
    ## @brief      Remove duplicate tags, leaving only first occurrence
    ##
    ## @return     Deduplicated string
    ##
    def dedup_tags!
      replace dedup_tags
    end

    def dedup_tags
      item = self.dup
      tags = item.scan(/(?<=^| )(\@(\S+?)(\([^)]+\))?)(?=\b|$)/).uniq
      tags.each do |tag|
        found = false
        item.gsub!(/( |^)#{tag[0]}\b/) do |m|
          if found
            ''
          else
            found = true
            m
          end
        end
      end
      item
    end

    ##
    ## @brief      Turn raw urls into HTML links
    ##
    ## @param      opt   (Hash) Additional Options
    ##
    def link_urls!(opt = {})
      replace link_urls(opt)
    end

    def link_urls(opt = {})
      opt[:format] ||= :html
      str = self.dup

      if :format == :markdown
        # Remove <self-linked> formatting
        str.gsub!(/<(.*?)>/) do |match|
          m = Regexp.last_match
          if m[1] =~ /^https?:/
            m[1]
          else
            match
          end
        end
      end

      # Replace qualified urls
      str.gsub!(%r{(?mi)(?<!["'\[(\\])((http|https)://)([\w\-_]+(\.[\w\-_]+)+)([\w\-.,@?^=%&amp;:/~+#]*[\w\-@^=%&amp;/~+#])?}) do |_match|
        m = Regexp.last_match
        proto = m[1].nil? ? 'http://' : ''
        case opt[:format]
        when :html
          %(<a href="#{proto}#{m[0]}" title="Link to #{m[0].sub(/^https?:\/\//, '')}">[#{m[3]}]</a>)
        when :markdown
          "[#{m[0]}](#{proto}#{m[0]})"
        else
          m[0]
        end
      end

      # Clean up unlinked <urls>
      str.gsub!(/<(\w+:.*?)>/) do |match|
        m = Regexp.last_match
        if m[1] =~ /<a href/
          match
        else
          %(<a href="#{m[1]}" title="Link to #{m[1]}">[link]</a>)
        end
      end

      str
    end
  end
end
