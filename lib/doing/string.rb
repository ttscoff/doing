# frozen_string_literal: true

module Doing
  ##
  ## @brief      String helpers
  ##
  class ::String
    include Doing::Color
    def to_rx(distance)
      gsub(/(.)/, "\\1.{0,#{distance}}")
    end

    def truthy?
      if self =~ /^(0|f(alse)?|n(o)?)$/i
        false
      else
        true
      end
    end

    def highlight_tags!(color = 'yellow')
      replace highlight_tags(color)
    end

    def highlight_tags(color = 'yellow')
      escapes = scan(/(\e\[[\d;]+m)[^\e]+@/)
      tag_color = Doing::Color.send(color)
      last_color = if !escapes.empty?
                     escapes[-1][0]
                   else
                     Doing::Color.default
                   end
      gsub(/(\s|m)(@[^ ("']+)/, "\\1#{tag_color}\\2#{last_color}")
    end

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

    def truncate!(len, ellipsis: '...')
      replace truncate(len, ellipsis: ellipsis)
    end

    ##
    ## @brief      Truncate string in the middle
    ##
    ## @param      len       The length
    ## @param      ellipsis  The ellipsis
    ##
    def truncmiddle(len, ellipsis: '...')
      return self if length <= len
      len -= (ellipsis.length / 2).to_i
      total = length
      half = total / 2
      cut = (total - len) / 2
      sub(/(.{#{half - cut}}).*?(.{#{half - cut}})$/, "\\1#{ellipsis}\\2")
    end

    def truncmiddle!(len, ellipsis: '...')
      replace truncmiddle(len, ellipsis: ellipsis)
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
    ## @brief      Convert a case sensitivity string to a symbol
    ##
    ## @return     Symbol :smart, :sensitive, :insensitive
    ##
    def normalize_case!
      replace normalize_case
    end

    def normalize_case(default = :smart)
      case self
      when /^c/i
        :sensitive
      when /^i/i
        :insensitive
      when /^s/i
        :smart
      else
        default.is_a?(Symbol) ? default : default.normalize_case
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

    def to_tags
      gsub(/ *, */, ' ').gsub(/ +/, ' ').split(/ /).sort.uniq.map { |t| t.strip.sub(/^@/, '') }
    end

    def add_tags!(tags, remove: false)
      replace add_tags(tags, remove: remove)
    end

    def add_tags(tags, remove: false)
      title = self.dup
      tags = tags.to_tags if tags.is_a?(String)
      tags.each { |tag| title.tag!(tag, remove: remove) }
      title
    end

    def tag!(tag, value: nil, remove: false, rename_to: nil, regex: false, single: false)
      replace tag(tag, value: value, remove: remove, rename_to: rename_to, regex: regex, single: single)
    end

    def tag(tag, value: nil, remove: false, rename_to: nil, regex: false, single: false)
      log_level = single ? :info : :debug
      title = dup
      title.chomp!
      tag = tag.sub(/^@?/, '')
      case_sensitive = tag !~ /[A-Z]/

      rx_tag = if regex
                 tag.gsub(/\./, '\S')
               else
                 tag.gsub(/\?/, '.').gsub(/\*/, '\S*?')
               end

      if remove || rename_to
        return title unless title =~ /#{rx_tag}(?=[ (]|$)/

        rx = Regexp.new("(^| )@#{rx_tag}(\\([^)]*\\))?(?= |$)", case_sensitive)
        if title =~ rx
          title.gsub!(rx) do
            m = Regexp.last_match
            rename_to ? "#{m[1]}@#{rename_to}#{m[2]}" : m[1]
          end

          title.dedup_tags!
          title.chomp!

          if rename_to
            f = "@#{tag}".cyan
            t = "@#{rename_to}".cyan
            Doing.logger.write(log_level, 'Tag:', %(renamed #{f} to #{t} in "#{title}"))
          else
            f = "@#{tag}".cyan
            Doing.logger.write(log_level, 'Tag:', %(removed #{f} from "#{title}"))
          end
        else
          Doing.logger.debug('Skipped:', "not tagged #{"@#{tag}".cyan}")
        end
      elsif title =~ /@#{tag}(?=[ (]|$)/
        Doing.logger.debug('Skipped:', "already tagged #{"@#{tag}".cyan}")
        return title
      else
        add = tag
        add += "(#{value})" unless value.nil?
        title.chomp!
        title += " @#{add}"

        title.dedup_tags!
        title.chomp!
        Doing.logger.write(log_level, 'Tag:', %(added #{('@' + tag).cyan} to "#{title}"))
      end

      title.gsub(/ +/, ' ')
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
      title = dup
      tags = title.scan(/(?<=^| )(@(\S+?)(\([^)]+\))?)(?= |$)/).uniq
      tags.each do |tag|
        found = false
        title.gsub!(/( |^)#{tag[1]}(\([^)]+\))?(?= |$)/) do |m|
          if found
            ''
          else
            found = true
            m
          end
        end
      end
      title
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
