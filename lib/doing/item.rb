# frozen_string_literal: true

module Doing
  ##
  ## This class describes a single WWID item
  ##
  class Item
    attr_accessor :date, :title, :section, :note

    # attr_reader :id

    include Color

    ##
    ## Initialize an item with date, title, section, and
    ## optional note
    ##
    ## @param      date     [Time] The item's start date
    ## @param      title    [String] The title
    ## @param      section  [String] The section to which
    ##                      the item belongs
    ## @param      note     [Array or String] The note
    ##                      (optional)
    ##
    def initialize(date, title, section, note = nil)
      @date = date.is_a?(Time) ? date : Time.parse(date)
      @title = title
      @section = section
      @note = Note.new(note)
    end

    # def date=(new_date)
    #   @date = new_date.is_a?(Time) ? new_date : Time.parse(new_date)
    # end

    ## If the entry doesn't have a @done date, return the elapsed time
    def duration
      return nil unless should_time? && should_finish?

      return nil if @title =~ /(?<=^| )@done\b/

      return Time.now - @date
    end

    ##
    ## Get the difference between the item's start date and
    ## the value of its @done tag (if present)
    ##
    ## @return     Interval in seconds
    ##
    def interval
      @interval ||= calc_interval
    end

    ##
    ## Get the value of the item's @done tag
    ##
    ## @return     [Time] @done value
    ##
    def end_date
      @end_date ||= Time.parse(Regexp.last_match(1)) if @title =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/
    end

    def calculate_end_date(opt)
      if opt[:took]
        if @date + opt[:took] > Time.now
          @date = Time.now - opt[:took]
          Time.now
        else
          @date + opt[:took]
        end
      elsif opt[:back]
        if opt[:back].is_a? Integer
          @date + opt[:back]
        else
          @date + (opt[:back] - @date)
        end
      else
        Time.now
      end
    end

    # Generate a hash that represents the entry
    #
    # @return [String] entry hash
    def id
      @id ||= (@date.to_s + @title + @section).hash
    end

    ##
    ## Test for equality between items
    ##
    ## @param      other          [Item] The other item
    ## @param      match_section  [Boolean] If true, require item sections to match
    ##
    ## @return     [Boolean] is equal?
    ##
    def equal?(other, match_section: false)
      return false if @title.strip != other.title.strip

      return false if @date != other.date

      return false unless @note.equal?(other.note)

      return false if match_section && @section != other.section

      true
    end

    ##
    ## Test if two items occur at the same time (same start date and equal duration)
    ##
    ## @param      item_b  [Item] The item to compare
    ##
    ## @return     [Boolean] is equal?
    ##
    def same_time?(item_b)
      date == item_b.date ? interval == item_b.interval : false
    end

    ##
    ## Test if the interval between start date and @done
    ## value overlaps with another item's
    ##
    ## @param      item_b  [Item] The item to compare
    ##
    ## @return     [Boolean] overlaps?
    ##
    def overlapping_time?(item_b)
      return true if same_time?(item_b)

      start_a = date
      a_interval = interval
      end_a = a_interval ? start_a + a_interval.to_i : start_a
      start_b = item_b.date
      b_interval = item_b.interval
      end_b = b_interval ? start_b + b_interval.to_i : start_b
      (start_a >= start_b && start_a <= end_b) || (end_a >= start_b && end_a <= end_b) || (start_a < start_b && end_a > end_b)
    end

    ##
    ## Updates the title of the Item by expanding natural
    ## language dates within configured date tags (tags
    ## whose value is expected to be a date)
    ##
    ## @param      additional_tags  An array of additional
    ##                              tag names to consider
    ##                              dates
    ##
    def expand_date_tags(additional_tags = nil)
      @title.expand_date_tags(additional_tags)
    end

    ##
    ## Add (or remove) tags from the title of the item
    ##
    ## @param      tags    [Array] The tags to apply
    ## @param      options Additional options
    ##
    ## @option options :date       [Boolean] Include timestamp?
    ## @option options :single     [Boolean] Log as a single change?
    ## @option options :value      [String] A value to include as @tag(value)
    ## @option options :remove     [Boolean] if true remove instead of adding
    ## @option options :rename_to  [String] if not nil, rename target tag to this tag name
    ## @option options :regex      [Boolean] treat target tag string as regex pattern
    ## @option options :force      [Boolean] with rename_to, add tag if it doesn't exist
    ##
    def tag(tags, **options)
      added = []
      removed = []

      date = options.fetch(:date, false)
      options[:value] ||= date ? Time.now.strftime('%F %R') : nil
      options.delete(:date)

      single = options.fetch(:single, false)
      options.delete(:single)

      tags = tags.to_tags if tags.is_a? ::String

      remove = options.fetch(:remove, false)
      tags.each do |tag|
        bool = remove ? :and : :not
        if tags?(tag, bool)
          @title = @title.tag(tag, **options).strip
          remove ? removed.push(tag) : added.push(tag)
        end
      end

      Doing.logger.log_change(tags_added: added, tags_removed: removed, count: 1, item: self, single: single)

      self
    end

    ##
    ## Get a list of tags on the item
    ##
    ## @return     [Array] array of tags (no values)
    ##
    def tags
      @title.scan(/(?<= |\A)@([^\s(]+)/).map { |tag| tag[0] }.sort.uniq
    end

    ##
    ## Return all tags including parenthetical values
    ##
    ## @return     [Array<Array>] Array of array pairs,
    ##             [[tag1, value], [tag2, value]]
    ##
    def tags_with_values
      @title.scan(/(?<= |\A)@([^\s(]+)(?:\((.*?)\))?/).map { |tag| [tag[0], tag[1]] }.sort.uniq
    end

    ##
    ## convert tags on item to an array with @ symbols removed
    ##
    ## @return     [Array] array of tags
    ##
    def tag_array
      tags.tags_to_array
    end

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

    ##
    ## Test if item has a @done tag
    ##
    ## @return     [Boolean] true item has @done tag
    ##
    def finished?
      tags?('done')
    end

    ##
    ## Test if item does not contain @done tag
    ##
    ## @return     [Boolean] true if item is missing @done tag
    ##
    def unfinished?
      tags?('done', negate: true)
    end

    ##
    ## Test if item is included in never_finish config and
    ## thus should not receive a @done tag
    ##
    ## @return     [Boolean] item should receive @done tag
    ##
    def should_finish?
      should?('never_finish')
    end

    ##
    ## Test if item is included in never_time config and
    ## thus should not receive a date on the @done tag
    ##
    ## @return     [Boolean] item should receive @done date
    ##
    def should_time?
      should?('never_time')
    end

    ##
    ## Move item from current section to destination section
    ##
    ## @param      new_section  [String] The destination
    ##                          section
    ## @param      label        [Boolean] add @from(original
    ##                          section) tag
    ## @param      log          [Boolean] log this action
    ##
    ## @return     nothing
    ##
    def move_to(new_section, label: true, log: true)
      from = @section

      tag('from', rename_to: 'from', value: from, force: true) if label
      @section = new_section

      Doing.logger.count(@section == 'Archive' ? :archived : :moved) if log
      Doing.logger.debug("#{@section == 'Archive' ? 'Archived' : 'Moved'}:",
                         "#{@title.trunc(60)} from #{from} to #{@section}")
      self
    end

    # outputs item in Doing file format, including leading tab
    def to_s
      "\t- #{@date.strftime('%Y-%m-%d %H:%M')} | #{@title}#{@note.good? ? "\n#{@note}" : ''}"
    end

    ##
    ## outputs a colored string with relative date and highlighted tags
    ##
    ## @return     Pretty representation of the object.
    ##
    def to_pretty(elements: %i[date title section])
      output = []
      elements.each do |e|
        case e
        when :date
          output << format('%13s |', @date.relative_date).cyan
        when :section
          output << "#{magenta}(#{white(@section)}#{magenta})"
        when :title
          output << @title.white.highlight_tags('cyan')
        end
      end

      output.join(' ')
    end

    # @private
    def inspect
      # %(<Doing::Item @date=#{@date} @title="#{@title}" @section:"#{@section}" @note:#{@note.to_s}>)
      %(<Doing::Item @date=#{@date}>)
    end

    def clone
      Marshal.load(Marshal.dump(self))
    end

    private

    def should?(key)
      config = Doing.settings
      return true unless config[key].is_a?(Array)

      config[key].each do |tag|
        if tag =~ /^@/
          return false if tags?(tag.sub(/^@/, '').downcase)
        elsif section.downcase == tag.downcase
          return false
        end
      end

      true
    end

    def calc_interval
      return nil unless should_time? && should_finish?

      done = end_date
      return nil if done.nil?

      start = @date

      t = (done - start).to_i
      t.positive? ? t : nil
    end

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
      raise InvalidTimeExpression, 'Unrecognized date/time expression' if val.nil?

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
      # If tag name matches a trigger for elapsed time test
      if tag =~ /^(elapsed|dur(ation)?|int(erval)?)$/i
        is_match = duration_matches?(value, comp)

        comp =~ /!/ || negate ? !is_match : is_match
      # Else if tag name matches a trigger for start date
      elsif tag =~ /^(d(ate)?|t(ime)?)$/i
        is_match = date_matches?(value, comp)

        comp =~ /!/ || negate ? !is_match : is_match
      # Else if tag name matches a trigger for all text
      elsif tag =~ /text/i
        is_match = value_string_matches?([@title, @note.to_s(prefix: '')].join(' '), comp, value)

        comp =~ /!/ || negate ? !is_match : is_match
      # Else if tag name matches a trigger for title
      elsif tag =~ /title/i
        is_match = value_string_matches?(@title, comp, value)

        comp =~ /!/ || negate ? !is_match : is_match
      # Else if tag name matches a trigger for note
      elsif tag =~ /note/i
        is_match = value_string_matches?(@note.to_s(prefix: ''), comp, value)

        comp =~ /!/ || negate ? !is_match : is_match
      # Else if item contains tag being tested
      elsif all_tags?([tag])
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
      else
        false
      end
    end

    def split_tags(tags)
      tags.to_tags.tags_to_array
    end
  end
end
