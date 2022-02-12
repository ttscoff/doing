# frozen_string_literal: true

module Doing
  ## Tag and search highlighting
  class ::String
    include Doing::Color
    ## @param (see #highlight_tags)
    def highlight_tags!(color = 'yellow', last_color: nil)
      replace highlight_tags(color)
    end

    ##
    ## Colorize @tags with ANSI escapes
    ##
    ## @param      color  [String] color (see #Color)
    ##
    ## @return     [String] string with @tags highlighted
    ##
    def highlight_tags(color = 'yellow', last_color: nil)
      unless last_color
        escapes = scan(/(\e\[[\d;]+m)[^\e]+@/)
        color = color.split(' ') unless color.is_a?(Array)
        tag_color = color.each_with_object([]) { |c, arr| arr << Doing::Color.send(c) }.join('')
        last_color = if escapes.good?
                       (escapes.count > 1 ? escapes[-2..-1] : [escapes[-1]]).map { |v| v[0] }.join('')
                     else
                       Doing::Color.default
                     end
      end
      gsub(/(\s|m)(@[^ ("']+)/, "\\1#{tag_color}\\2#{last_color}")
    end

    def highlight_search!(search, distance: nil, negate: false, case_type: nil)
      replace highlight_search(search, distance: distance, negate: negate, case_type: case_type)
    end

    def highlight_search(search, distance: nil, negate: false, case_type: nil)
      out = dup
      prefs = Doing.config.settings['search'] || {}
      matching = prefs.fetch('matching', 'pattern').normalize_matching
      distance ||= prefs.fetch('distance', 3).to_i
      case_type ||= prefs.fetch('case', 'smart').normalize_case

      if search.rx? || matching == :fuzzy
        rx = search.to_rx(distance: distance, case_type: case_type)
        out.gsub!(rx) { |m| m.bgyellow.black }
      else
        query = search.strip.to_phrase_query

        if query[:must].nil? && query[:must_not].nil?
          query[:must] = query[:should]
          query[:should] = []
        end
        qs = []
        qs.concat(query[:must]) if query[:must]
        qs.concat(query[:should]) if query[:should]
        qs.each do |s|
          rx = Regexp.new(s.wildcard_to_rx, ignore_case(s, case_type))
          out.gsub!(rx) { |m| m.bgyellow.black }
        end
      end
      out
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
    ## Remove color escape codes
    ##
    ## @return     clean string
    ##
    def uncolor
      gsub(/\e\[[\d;]+m/, '')
    end

    ##
    ## @see        #uncolor
    ##
    def uncolor!
      replace uncolor
    end
  end
end
