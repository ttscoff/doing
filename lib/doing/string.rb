# frozen_string_literal: true

module Doing
  ##
  ## String helpers
  ##
  class ::String
    include Doing::Color
    ##
    ## Determines if receiver is surrounded by slashes or starts with single quote
    ##
    ## @return     True if regex, False otherwise.
    ##
    def is_rx?
      self =~ %r{(^/.*?/$|^')}
    end

    ##
    ## Convert string to fuzzy regex. Characters in words
    ## can be separated by up to *distance* characters in
    ## haystack, spaces indicate unlimited distance.
    ##
    ## @example    `"this word".to_rx(2) => /t.{0,3}h.{0,3}i.{0,3}s.{0,3}.*?w.{0,3}o.{0,3}r.{0,3}d/`
    ##
    ## @param      distance   [Integer] Allowed distance
    ##                        between characters
    ## @param      case_type  The case type
    ##
    ## @return     [Regexp] Regex pattern
    ##
    def to_rx(distance: nil, case_type: nil)
      distance ||= Doing.config.settings.dig('search', 'distance').to_i || 3
      case_type ||= Doing.config.settings.dig('search', 'case')&.normalize_case || :smart
      case_sensitive = case case_type
                       when :smart
                         self =~ /[A-Z]/ ? true : false
                       when :sensitive
                         true
                       else
                         false
                       end

      pattern = case dup.strip
                when %r{^/.*?/$}
                  sub(%r{/(.*?)/}, '\1')
                when /^'/
                  sub(/^'(.*?)'?$/, '\1')
                else
                  split(/ +/).map do |w|
                    w.split('').join(".{0,#{distance}}").gsub(/\+/, '\+').wildcard_to_rx
                  end.join('.*?')
                end
      Regexp.new(pattern, !case_sensitive)
    end

    ##
    ## Test string for truthiness (0, "f", "false", "n", "no" all return false, case insensitive, otherwise true)
    ##
    ## @return     [Boolean] String is truthy
    ##
    def truthy?
      if self =~ /^(0|f(alse)?|n(o)?)$/i
        false
      else
        true
      end
    end

    # Compress multiple spaces to single space
    def compress
      gsub(/ +/, ' ').strip
    end

    def compress!
      replace compress
    end

    ## @param (see #highlight_tags)
    def highlight_tags!(color = 'yellow')
      replace highlight_tags(color)
    end

    ##
    ## Colorize @tags with ANSI escapes
    ##
    ## @param      color  [String] color (see #Color)
    ##
    ## @return     [String] string with @tags highlighted
    ##
    def highlight_tags(color = 'yellow')
      escapes = scan(/(\e\[[\d;]+m)[^\e]+@/)
      color = color.split(' ') unless color.is_a?(Array)
      tag_color = ''
      color.each { |c| tag_color += Doing::Color.send(c) }
      last_color = if !escapes.empty?
                     escapes[-1][0]
                   else
                     Doing::Color.default
                   end
      gsub(/(\s|m)(@[^ ("']+)/, "\\1#{tag_color}\\2#{Doing::Color.reset}#{last_color}")
    end

    ##
    ## Test if line should be ignored
    ##
    ## @return     [Boolean] line is empty or comment
    ##
    def ignore?
      line = self
      line =~ /^#/ || line =~ /^\s*$/
    end

    ##
    ## Truncate to nearest word
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
    ## Truncate string in the middle
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
    ## Remove color escape codes
    ##
    ## @return     clean string
    ##
    def uncolor
      gsub(/\e\[[\d;]+m/,'')
    end

    def uncolor!
      replace uncolor
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
    def wrap(len, pad: 0, indent: '  ', offset: 0, prefix: '', color: '', after: '', reset: '')
      last_color = color.empty? ? '' : after.last_color
      note_rx = /(?i-m)(%(?:[io]d|(?:\^[\s\S])?(?:(?:[ _t]|[^a-z0-9])?\d+)?(?:[\s\S][ _t]?)?)?note)/
      # Don't break inside of tag values
      str = gsub(/@\S+\(.*?\)/) { |tag| tag.gsub(/\s/, '%%%%') }
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
      note = ''
      after = after.dup if after.frozen?
      after.sub!(note_rx) do
        note = Regexp.last_match(0)
        ''
      end
      last_color = ''
      out[0] = format("%-#{pad}s%s%s", out[0], last_color, after)

      left_pad = ' ' * offset
      left_pad += indent
      out.map { |l| "#{left_pad}#{color}#{l}#{last_color}" }.join("\n").strip + last_color + " #{note}".chomp
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

    def pluralize(number)
      number == 1 ? self : "#{self}s"
    end

    ##
    ## Convert a sort order string to a qualified type
    ##
    ## @return     [String] 'asc' or 'desc'
    ##
    def normalize_order!(default = 'asc')
      replace normalize_order(default)
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
    ## Convert a case sensitivity string to a symbol
    ##
    ## @return     Symbol :smart, :sensitive, :ignore
    ##
    def normalize_case!
      replace normalize_case
    end

    def normalize_case(default = :smart)
      case self
      when /^(c|sens)/i
        :sensitive
      when /^i/i
        :ignore
      when /^s/i
        :smart
      else
        default.is_a?(Symbol) ? default : default.normalize_case
      end
    end

    ##
    ## Convert a boolean string to a symbol
    ##
    ## @return     Symbol :and, :or, or :not
    ##
    def normalize_bool!(default = :and)
      replace normalize_bool(default)
    end

    def normalize_bool(default = :and)
      case self
      when /(and|all)/i
        :and
      when /(any|or)/i
        :or
      when /(not|none)/i
        :not
      when /^p/i
        :pattern
      else
        default.is_a?(Symbol) ? default : default.normalize_bool
      end
    end

    ##
    ## Convert a matching configuration string to a symbol
    ##
    ## @return     Symbol :fuzzy, :pattern, :exact
    ##
    def normalize_matching!(default = :pattern)
      replace normalize_bool(default)
    end

    def normalize_matching(default = :pattern)
      case self
      when /^f/i
        :fuzzy
      when /^p/i
        :pattern
      when /^e/i
        :exact
      else
        default.is_a?(Symbol) ? default : default.normalize_matching
      end
    end

    def normalize_trigger!
      replace normalize_trigger
    end

    def normalize_trigger
      gsub(/\((?!\?:)/, '(?:').downcase
    end

    def wildcard_to_rx
      gsub(/\?/, '\S').gsub(/\*/, '\S*?')
    end

    def add_at
      strip.sub(/^([+-]*)@/, '\1')
    end

    def to_tags
      gsub(/ *, */, ' ').gsub(/ +/, ' ').split(/ /).sort.uniq.map(&:add_at)
    end

    def add_tags!(tags, remove: false)
      replace add_tags(tags, remove: remove)
    end

    def add_tags(tags, remove: false)
      title = self.dup
      tags = tags.to_tags
      tags.each { |tag| title.tag!(tag, remove: remove) }
      title
    end

    ##
    ## Add, rename, or remove a tag in place
    ##
    ## @see #tag
    ##
    def tag!(tag, **options)
      replace tag(tag, **options)
    end

    ##
    ## Add, rename, or remove a tag
    ##
    ## @param      tag        The tag
    ## @param      value      [String] Value for tag (@tag(value))
    ## @param      remove     [Boolean] Remove the tag instead of adding
    ## @param      rename_to  [String] Replace tag with this tag
    ## @param      regex      [Boolean] Tag is regular expression
    ## @param      single     [Boolean] Operating on a single item (for logging)
    ## @param      force      [Boolean] With rename_to, add tag if it doesn't exist
    ##
    ## @return     [String] The string with modified tags
    ##
    def tag(tag, value: nil, remove: false, rename_to: nil, regex: false, single: false, force: false)
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
        rx = Regexp.new("(?<=^| )@#{rx_tag}(?<parens>\\((?<value>[^)]*)\\))?(?= |$)", case_sensitive)
        m = title.match(rx)

        if m.nil? && rename_to && force
          title.tag!(rename_to, value: value, single: single)
        elsif m
          title.gsub!(rx) do
            rename_to ? "@#{rename_to}#{value.nil? ? m['parens'] : "(#{value})"}" : ''
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
    ## Remove duplicate tags, leaving only first occurrence
    ##
    ## @return     Deduplicated string
    ##
    def dedup_tags!
      replace dedup_tags
    end

    def dedup_tags
      title = dup
      tags = title.scan(/(?<=\A| )(@(\S+?)(\([^)]+\))?)(?= |\Z)/).uniq
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

    # Returns the last escape sequence from a string.
    #
    # Actually returns all escape codes, with the assumption
    # that the result of inserting them will generate the
    # same color as was set at the end of the string.
    # Because you can send modifiers like dark and bold
    # separate from color codes, only using the last code
    # may not render the same style.
    #
    # @return     [String]  All escape codes in string
    #
    def last_color
      scan(/\e\[[\d;]+m/).join('')
    end

    ##
    ## Turn raw urls into HTML links
    ##
    ## @param      opt   [Hash] Additional Options
    ##
    def link_urls!(**opt)
      fmt = opt.fetch(:format, :html)
      replace link_urls(format: fmt)
    end

    def link_urls(**opt)
      fmt = opt.fetch(:format, :html)
      return self unless fmt

      str = dup

      str = str.remove_self_links if fmt == :markdown

      str.replace_qualified_urls(format: fmt).clean_unlinked_urls
    end

    # Remove <self-linked> formatting
    def remove_self_links
      gsub(/<(.*?)>/) do |match|
        m = Regexp.last_match
        if m[1] =~ /^https?:/
          m[1]
        else
          match
        end
      end
    end

    # Replace qualified urls
    def replace_qualified_urls(**options)
      fmt = options.fetch(:format, :html)
      gsub(%r{(?mi)(?x:
      (?<!["'\[(\\])
      (?<protocol>(?:http|https)://)
      (?<domain>[\w\-]+(?:\.[\w\-]+)+)
      (?<path>[\w\-.,@?^=%&;:/~+#]*[\w\-@^=%&;/~+#])?
      )}) do |_match|
        m = Regexp.last_match
        url = "#{m['domain']}#{m['path']}"
        proto = m['protocol'].nil? ? 'http://' : m['protocol']
        case fmt
        when :terminal
          TTY::Link.link_to("#{proto}#{url}", "#{proto}#{url}")
        when :html
          %(<a href="#{proto}#{url}" title="Link to #{m['domain']}">[#{url}]</a>)
        when :markdown
          "[#{url}](#{proto}#{url})"
        else
          m[0]
        end
      end
    end

    # Clean up unlinked <urls>
    def clean_unlinked_urls
      gsub(/<(\w+:.*?)>/) do |match|
        m = Regexp.last_match
        if m[1] =~ /<a href/
          match
        else
          %(<a href="#{m[1]}" title="Link to #{m[1]}">[link]</a>)
        end
      end
    end

    def set_type(kind = nil)
      if kind
        case kind.to_s
        when /^a/i
          gsub(/^\[ *| *\]$/, '').split(/ *, */)
        when /^i/i
          to_i
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
  end
end
