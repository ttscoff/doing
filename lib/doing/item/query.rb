# frozen_string_literal: true

module Doing
  # Tag and search filtering for a Doing entry
  module ItemQuery
    ##
    ## Test if item contains tag(s)
    ##
    ## @param      tags    (Array or String) The tags to test. Can be an array or a comma-separated string.
    ## @param      bool    (Symbol) The boolean to use for multiple tags (:and, :or, :not)
    ## @param      negate  [Boolean] negate the result?
    ##
    ## @return     [Boolean] true if tag/bool combination passes
    ##
    def tags?(tags, bool = :and, negate: false)
      if bool == :pattern
        tags = tags.to_tags.tags_to_array.join(' ')
        matches = tag_pattern?(tags)

        return negate ? !matches : matches
      end

      tags = split_tags(tags)
      bool = bool.normalize_bool

      matches = case bool
                when :and
                  all_tags?(tags)
                when :not
                  no_tags?(tags)
                else
                  any_tags?(tags)
                end
      negate ? !matches : matches
    end

    ##
    ## Test if item matches tag values
    ##
    ## @param      queries (Array) The tag value queries to test
    ## @param      bool    (Symbol) The boolean to use for multiple tags (:and, :or, :not)
    ## @param      negate  [Boolean] negate the result?
    ##
    ## @return     [Boolean] true if tag/bool combination passes
    ##
    def tag_values?(queries, bool = :and, negate: false)
      bool = bool.normalize_bool

      matches = case bool
                when :and
                  all_values?(queries)
                when :not
                  no_values?(queries)
                else
                  any_values?(queries)
                end
      negate ? !matches : matches
    end

    ##
    ## Determine if case should be ignored for searches
    ##
    ## @param      search     [String] The search string
    ## @param      case_type  [Symbol] The case type
    ##
    ## @return     [Boolean] case should be ignored
    ##
    def ignore_case(search, case_type)
      (case_type == :smart && search !~ /[A-Z]/) || case_type == :ignore
    end

    def highlight_search(search, distance: nil, negate: false, case_type: nil)
      prefs = Doing.setting('search', {})
      matching = prefs.fetch('matching', 'pattern').normalize_matching
      distance ||= prefs.fetch('distance', 3).to_i
      case_type ||= prefs.fetch('case', 'smart').normalize_case
      new_note = Note.new

      if search.rx? || matching == :fuzzy
        rx = search.to_rx(distance: distance, case_type: case_type)
        new_title = @title.gsub(rx) { |m| yellow(m) }
        new_note.add(@note.to_s.gsub(rx) { |m| yellow(m) })
      else
        query = search.strip.to_phrase_query

        if query[:must].nil? && query[:must_not].nil?
          query[:must] = query[:should]
          query[:should] = []
        end
        query[:must].concat(query[:should]).each do |s|
          rx = Regexp.new(s.wildcard_to_rx, ignore_case(s, case_type))
          new_title = @title.gsub(rx) { |m| yellow(m) }
          new_note.add(@note.to_s.gsub(rx) { |m| yellow(m) })
        end
      end

      Item.new(@date, new_title, @section, new_note)
    end

    ##
    ## Test if item matches search string
    ##
    ## @param      search     [String] The search string
    ## @param      negate     [Boolean] negate results
    ## @param      case_type  (Symbol) The case-sensitivity
    ##                        type (:sensitive,
    ##                        :ignore, :smart)
    ##
    ## @return     [Boolean] matches search criteria
    ##
    def search(search, distance: nil, negate: false, case_type: nil)
      prefs = Doing.setting('search', {})
      matching = prefs.fetch('matching', 'pattern').normalize_matching
      distance ||= prefs.fetch('distance', 3).to_i
      case_type ||= prefs.fetch('case', 'smart').normalize_case

      if search.rx? || matching == :fuzzy
        matches = @title + @note.to_s =~ search.to_rx(distance: distance, case_type: case_type)
      else
        query = search.strip.to_phrase_query

        if query[:must].nil? && query[:must_not].nil?
          query[:must] = query[:should]
          query[:should] = []
        end
        matches = no_searches?(query[:must_not], case_type: case_type)
        matches &&= all_searches?(query[:must], case_type: case_type)
        matches &&= any_searches?(query[:should], case_type: case_type)
      end
      # if search =~ /(?<=\A| )[+-]\S/
      # else
      #   text = @title + @note.to_s
      #   matches = text =~ search.to_rx(distance: distance, case_type: case_type)
      # end

      # if search.rx? || !fuzzy
      #   matches = text =~ search.to_rx(distance: distance, case_type: case_type)
      # else
      #   distance = 0.25 if distance > 1
      #   score = if (case_type == :smart && search !~ /[A-Z]/) || case_type == :ignore
      #             text.downcase.pair_distance_similar(search.downcase)
      #           else
      #             score = text.pair_distance_similar(search)
      #           end

      #   if score >= distance
      #     matches = true
      #     Doing.logger.debug('Fuzzy Match:', %(#{@title}, "#{search}" #{score}))
      #   end
      # end

      negate ? !matches : matches
    end

    private

    def all_searches?(searches, case_type: :smart)
      return true unless searches.good?

      text = @title + @note.to_s
      searches.each do |s|
        rx = Regexp.new(s.wildcard_to_rx, ignore_case(s, case_type))
        return false unless text =~ rx
      end
      true
    end

    def no_searches?(searches, case_type: :smart)
      return true unless searches.good?

      text = @title + @note.to_s
      searches.each do |s|
        rx = Regexp.new(s.wildcard_to_rx, ignore_case(s, case_type))
        return false if text =~ rx
      end
      true
    end

    def any_searches?(searches, case_type: :smart)
      return true unless searches.good?

      text = @title + @note.to_s
      searches.each do |s|
        rx = Regexp.new(s.wildcard_to_rx, ignore_case(s, case_type))
        return true if text =~ rx
      end
      false
    end

    def all_tags?(tags)
      return true unless tags.good?

      tags.each do |tag|
        if tag =~ /done/ && !should_finish?
          next
        else
          return false unless @title =~ /@#{tag.wildcard_to_rx}(?= |\(|\Z)/i
        end
      end
      true
    end

    def no_tags?(tags)
      return true unless tags.good?

      tags.each do |tag|
        if tag =~ /done/ && !should_finish?
          return false
        else
          return false if @title =~ /@#{tag.wildcard_to_rx}(?= |\(|\Z)/i
        end
      end
      true
    end

    def any_tags?(tags)
      return true unless tags.good?

      tags.each do |tag|
        if tag =~ /done/ && !should_finish?
          return true
        else
          return true if @title =~ /@#{tag.wildcard_to_rx}(?= |\(|\Z)/i
        end
      end
      false
    end

    def tag_pattern?(tags)
      query = tags.to_query

      no_tags?(query[:must_not]) && all_tags?(query[:must]) && any_tags?(query[:should])
    end

    def tag_value(tag)
      res = @title.match(/@#{tag.sub(/^@/, '').wildcard_to_rx}\((.*?)\)/)
      res ? res[1] : nil
    end

    def number_or_date(value)
      return nil unless value

      if value.strip =~ /^[0-9.]+%?$/
        value.strip.to_f
      else
        value.strip.chronify(guess: :end)
      end
    end

    def split_value_query(query)
      val_rx = /^(!)?@?(\S+) +(!?[<>=][=*]?|[$*^]=) +(.*?)$/
      query.match(val_rx)
    end

    def any_values?(queries)
      return true unless queries.good?

      queries.each do |q|
        parts = split_value_query(q)
        return true if tag_value_matches?(parts[2], parts[3], parts[4], parts[1])
      end
      false
    end

    def all_values?(queries)
      return true unless queries.good?

      queries.each do |q|
        parts = split_value_query(q)

        return false unless tag_value_matches?(parts[2], parts[3], parts[4], parts[1])
      end
      true
    end

    def no_values?(queries)
      return true unless queries.good?

      queries.each do |q|
        parts = split_value_query(q)
        return false if tag_value_matches?(parts[2], parts[3], parts[4], parts[1])
      end
      true
    end

    def duration_matches?(value, comp)
      return false if interval.nil?

      val = value.chronify_qty
      case comp
      when /^<$/
        interval < val
      when /^<=$/
        interval <= val
      when /^>$/
        interval > val
      when /^>=$/
        interval >= val
      when /^!=/
        interval != val
      when /^=/
        interval == val
      end
    end

    def date_matches?(value, comp)
      time_rx = /^(\d{1,2}+(:\d{1,2}+)?( *(am|pm))?|midnight|noon)$/i
      value = "#{@date.strftime('%Y-%m-%d')} #{value}" if value =~ time_rx

      val = value.chronify(guess: :begin)
      raise InvalidTimeExpression, "Unrecognized date/time expression (#{value})" if val.nil?

      case comp
      when /^<$/
        @date < val
      when /^<=$/
        @date <= val
      when /^>$/
        @date > val
      when /^>=$/
        @date >= val
      when /^!=/
        @date != val
      when /^=/
        @date == val
      end
    end

    def value_string_matches?(tag_val, comp, value)
      case comp
      when /\^=/
        tag_val =~ /^#{value.wildcard_to_rx}/i
      when /\$=/
        tag_val =~ /#{value.wildcard_to_rx}$/i
      when %r{==}
        tag_val =~ /^#{value.wildcard_to_rx}$/i
      else
        tag_val =~ /#{value.wildcard_to_rx}/i
      end
    end

    def value_number_matches?(tag_val, comp, value)
      case comp
      when /^<$/
        tag_val < value
      when /^<=$/
        tag_val <= value
      when /^>$/
        tag_val > value
      when /^>=$/
        tag_val >= value
      when /^!=/
        tag_val != value
      when /^=/
        tag_val == value
      end
    end

    ##
    ## Test if a tag's value matches a given value. Value
    ## can be a date string, a text string, or a
    ## number/percentage. Type of comparison is determined
    ## by the comparitor and the objects being compared.
    ##
    ## @param      tag     [String] The tag name from which
    ##                     to get the value
    ## @param      comp    [String] The comparator (e.g. >=
    ##                     or *=)
    ## @param      value   [String] The value to test
    ##                     against
    ## @param      negate  [Boolean] Negate the response
    ##
    ## @return     True if tag value matches, False otherwise.
    ##
    def tag_value_matches?(tag, comp, value, negate)
      # If tag matches existing tag
      if tags?(tag, :and)
        tag_val = tag_value(tag)

        # If the tag value is not a date and contains alpha
        # characters and comparison is ==, or comparison is
        # a string comparitor (*= ^= $=)
        if (value.chronify.nil? && value =~ /[a-z]/i && comp =~ /^!?==?$/) || comp =~ /[$*^]=/
          is_match = value_string_matches?(tag_val, comp, value)

          comp =~ /!/ || negate ? !is_match : is_match
        else
          # Convert values to either a number or a date
          tag_val = number_or_date(tag_val)
          val = number_or_date(value)

          # Fail if either value is nil
          return false if val.nil? || tag_val.nil?

          # Fail unless both values are of the same class (float or date)
          return false unless val.class == tag_val.class

          is_match = value_number_matches?(tag_val, comp, val)

          negate.nil? ? is_match : !is_match
        end
      # If tag name matches a trigger for elapsed time test
      elsif tag =~ /^(elapsed|dur(ation)?|int(erval)?)$/i
        is_match = duration_matches?(value, comp)

        comp =~ /!/ || negate ? !is_match : is_match
      # Else if tag name matches a trigger for start date
      elsif tag =~ /^(d(ate)?|t(ime)?)$/i
        is_match = date_matches?(value, comp)

        comp =~ /!/ || negate ? !is_match : is_match
      # Else if tag name matches a trigger for all text
      elsif tag =~ /^text$/i
        is_match = value_string_matches?([@title, @note.to_s(prefix: '')].join(' '), comp, value)

        comp =~ /!/ || negate ? !is_match : is_match
      # Else if tag name matches a trigger for title
      elsif tag =~ /^title$/i
        is_match = value_string_matches?(@title, comp, value)

        comp =~ /!/ || negate ? !is_match : is_match
      # Else if tag name matches a trigger for note
      elsif tag =~ /^note$/i
        is_match = value_string_matches?(@note.to_s(prefix: ''), comp, value)

        comp =~ /!/ || negate ? !is_match : is_match
      # Else if item contains tag being tested
      else
        false
      end
    end
  end
end
