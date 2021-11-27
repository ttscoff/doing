# frozen_string_literal: true

module Doing
  ##
  ## This class describes a single WWID item
  ##
  class Item
    attr_accessor :date, :title, :section, :note

    attr_reader :id

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

    ##
    ## Add (or remove) tags from the title of the item
    ##
    ## @param      tags    [Array] The tags to apply
    ## @param      **options Additional options
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
    ## Test if item contains tag(s)
    ##
    ## @param      tags    (Array or String) The tags to test. Can be an array or a comma-separated string.
    ## @param      bool    (Symbol) The boolean to use for multiple tags (:and, :or, :not)
    ## @param      negate  [Boolean] negate the result?
    ##
    ## @return     [Boolean] true if tag/bool combination passes
    ##
    def tags?(tags, bool = :and, negate: false)
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
    def search(search, distance: 3, negate: false, case_type: :smart, fuzzy: false)
      text = @title + @note.to_s
      matches = text =~ search.to_rx(distance: distance, case_type: case_type)

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

    def should_finish?
      should?('never_finish')
    end

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
      t > 0 ? t : nil
    end

    def all_tags?(tags)
      tags.each do |tag|
        return false unless @title =~ /@#{tag}/
      end
      true
    end

    def no_tags?(tags)
      tags.each do |tag|
        return false if @title =~ /@#{tag}/
      end
      true
    end

    def any_tags?(tags)
      tags.each do |tag|
        return true if @title =~ /@#{tag}/
      end
      false
    end

    def split_tags(tags)
      tags = tags.split(/ *, */) if tags.is_a? String
      tags.map { |t| t.strip.sub(/^@/, '') }
    end
  end
end
