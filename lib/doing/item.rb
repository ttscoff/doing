# frozen_string_literal: true

module Doing
  ##
  ## This class describes a single WWID item
  ##
  class Item
    attr_accessor :date, :title, :section, :note

    # attr_reader :id

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
    ## @param      other [Item] The other item
    ##
    ## @return     [Boolean] is equal?
    ##
    def equal?(other)
      return false if @title.strip != other.title.strip

      return false if @date != other.date

      return false unless @note.equal?(other.note)

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
      interval = interval
      end_a = interval ? start_a + interval.to_i : start_a
      start_b = item_b.date
      interval = item_b.interval
      end_b = interval ? start_b + interval.to_i : start_b
      (start_a >= start_b && start_a <= end_b) || (end_a >= start_b && end_a <= end_b) || (start_a < start_b && end_a > end_b)
    end

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
          @title.tag!(tag, **options).strip!
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
        tags = tags.join(' ') if tags.is_a?(Array)
        matches = tag_pattern?(tags.gsub(/ *, */, ' '))

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
      prefs = Doing.config.settings['search'] || {}
      matching = prefs.fetch('matching', 'pattern').normalize_matching
      distance ||= prefs.fetch('distance', 3).to_i
      case_type ||= prefs.fetch('case', 'smart').normalize_case

      if search.is_rx? || matching == :fuzzy
        matches = @title + @note.to_s =~ search.to_rx(distance: distance, case_type: case_type)
      else
        query = to_phrase_query(search.strip)

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

      # if search.is_rx? || !fuzzy
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
                         "#{@title.truncate(60)} from #{from} to #{@section}")
      self
    end

    # outputs item in Doing file format, including leading tab
    def to_s
      "\t- #{@date.strftime('%Y-%m-%d %H:%M')} | #{@title}#{@note.empty? ? '' : "\n#{@note}"}"
    end

    # @private
    def inspect
      # %(<Doing::Item @date=#{@date} @title="#{@title}" @section:"#{@section}" @note:#{@note.to_s}>)
      %(<Doing::Item @date=#{@date}>)
    end

    private

    def should?(key)
      config = Doing.config.settings
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
      done = end_date
      return nil if done.nil?

      start = @date

      t = (done - start).to_i
      t.positive? ? t : nil
    end

    def all_searches?(searches, case_type: :smart)
      return true if searches.nil? || searches.empty?

      text = @title + @note.to_s
      searches.each do |s|
        rx = Regexp.new(s.wildcard_to_rx, ignore_case(s, case_type))
        return false unless text =~ rx
      end
      true
    end

    def no_searches?(searches, case_type: :smart)
      return true if searches.nil? || searches.empty?

      text = @title + @note.to_s
      searches.each do |s|
        rx = Regexp.new(s.wildcard_to_rx, ignore_case(s, case_type))
        return false if text =~ rx
      end
      true
    end

    def any_searches?(searches, case_type: :smart)
      return true if searches.nil? || searches.empty?

      text = @title + @note.to_s
      searches.each do |s|
        rx = Regexp.new(s.wildcard_to_rx, ignore_case(s, case_type))
        return true if text =~ rx
      end
      false
    end

    def all_tags?(tags)
      return true if tags.nil? || tags.empty?

      tags.each do |tag|
        return false unless @title =~ /@#{tag.wildcard_to_rx}(?= |\(|\Z)/i
      end
      true
    end

    def no_tags?(tags)
      return true if tags.nil? || tags.empty?

      tags.each do |tag|
        return false if @title =~ /@#{tag.wildcard_to_rx}(?= |\(|\Z)/i
      end
      true
    end

    def any_tags?(tags)
      return true if tags.nil? || tags.empty?

      tags.each do |tag|
        return true if @title =~ /@#{tag.wildcard_to_rx}(?= |\(|\Z)/i
      end
      false
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
      return true if queries.nil? || queries.empty?

      queries.each do |q|
        parts = split_value_query(q)
        return true if tag_value_matches?(parts[2], parts[3], parts[4], parts[1])
      end
      false
    end

    def all_values?(queries)
      return true if queries.nil? || queries.empty?

      queries.each do |q|
        parts = split_value_query(q)
        return false unless tag_value_matches?(parts[2], parts[3], parts[4], parts[1])
      end
      true
    end

    def no_values?(queries)
      return true if queries.nil? || queries.empty?

      queries.each do |q|
        parts = split_value_query(q)
        return false if tag_value_matches?(parts[2], parts[3], parts[4], parts[1])
      end
      true
    end

    def tag_value_matches?(tag, comp, value, negate)
      if all_tags?([tag])
        tag_val = tag_value(tag)

        if (value.chronify.nil? && value =~ /[a-z]/i && comp =~ /^!?==?$/) || comp =~ /[$*^]=/
          is_match = case comp
                     when /\^=/
                       tag_val =~ /^#{value.wildcard_to_rx}/i
                     when /\$=/
                       tag_val =~ /#{value.wildcard_to_rx}$/i
                     when %r{==}
                       tag_val =~ /^#{value.wildcard_to_rx}$/i
                     else
                       tag_val =~ /#{value.wildcard_to_rx}/i
                     end

          comp =~ /!/ || negate ? !is_match : is_match
        else
          tag_val = number_or_date(tag_val)
          val = number_or_date(value)

          return false if val.nil? || tag_val.nil?

          return false unless val.class == tag_val.class

          matches = case comp
                    when /^<$/
                      tag_val < val
                    when /^<=$/
                      tag_val <= val
                    when /^>$/
                      tag_val > val
                    when /^>=$/
                      tag_val >= val
                    when /^!=/
                      tag_val != val
                    when /^=/
                      tag_val == val
                    end
          negate.nil? ? matches : !matches
        end
      else
        false
      end
    end

    def to_query(query)
      parser = BooleanTermParser::QueryParser.new
      transformer = BooleanTermParser::QueryTransformer.new
      parse_tree = parser.parse(query)
      transformer.apply(parse_tree).to_elasticsearch
    end

    def to_phrase_query(query)
      parser = PhraseParser::QueryParser.new
      transformer = PhraseParser::QueryTransformer.new
      parse_tree = parser.parse(query)
      transformer.apply(parse_tree).to_elasticsearch
    end

    def tag_pattern?(tags)
      query = to_query(tags)

      no_tags?(query[:must_not]) && all_tags?(query[:must]) && any_tags?(query[:should])
    end

    def split_tags(tags)
      tags = tags.split(/ *, */) if tags.is_a? String
      tags.map { |t| t.strip.add_at }
    end
  end
end
