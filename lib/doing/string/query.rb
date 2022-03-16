# frozen_string_literal: true

module Doing
  ## Handling of search and regex strings
  module StringQuery
    ##
    ## Determine whether case should be ignored for string
    ##
    ## @param      search     The search string
    ## @param      case_type  The case type, :smart,
    ##                        :sensitive, :ignore
    ##
    ## @return     [Boolean] true if case should be ignored
    ##
    def ignore_case(search, case_type)
      (case_type == :smart && search !~ /[A-Z]/) || case_type == :ignore
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
    ## Determines if receiver is surrounded by slashes or starts with single quote
    ##
    ## @return     [Boolean] True if regex, False otherwise.
    ##
    def rx?
      self =~ %r{(^/.*?/$|^')}
    end

    ##
    ## Convert ? and * wildcards to regular expressions.
    ## Uses \S (non-whitespace) instead of . (any character)
    ##
    ## @return     [String] Regular expression string
    ##
    def wildcard_to_rx
      gsub(/\?/, '\S').gsub(/\*/, '\S*?').gsub(/\]\]/, '--')
    end

    ##
    ## Convert string to fuzzy regex. Characters in words
    ## can be separated by up to *distance* characters in
    ## haystack, spaces indicate unlimited distance.
    ##
    ## @example
    ##   "this word".to_rx(3)
    ##   # => /t.{0,3}h.{0,3}i.{0,3}s.{0,3}.*?w.{0,3}o.{0,3}r.{0,3}d/
    ##
    ## @param      distance   [Integer] Allowed distance
    ##                        between characters
    ## @param      case_type  The case type
    ##
    ## @return     [Regexp] Regex pattern
    ##
    def to_rx(distance: nil, case_type: nil)
      distance ||= Doing.config.fetch('search', 'distance', 3).to_i
      case_type ||= Doing.config.fetch('search', 'case', 'smart')&.normalize_case
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

    def to_phrase_query
      parser = PhraseParser::QueryParser.new
      transformer = PhraseParser::QueryTransformer.new
      parse_tree = parser.parse(self)
      transformer.apply(parse_tree).to_elasticsearch
    end

    def to_query
      parser = BooleanTermParser::QueryParser.new
      transformer = BooleanTermParser::QueryTransformer.new
      parse_tree = parser.parse(self)
      transformer.apply(parse_tree).to_elasticsearch
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

    ##
    ## Returns a bool representation of the string.
    ##
    ## @return     [Boolean] Bool representation of the object.
    ##
    def to_bool
      case self
      when /^[yt1]/i
        true
      else
        false
      end
    end
  end
end
