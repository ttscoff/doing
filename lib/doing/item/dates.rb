# frozen_string_literal: true

module Doing
  module ItemDates
    # def date=(new_date)
    #   @date = new_date.is_a?(Time) ? new_date : Time.parse(new_date)
    # end

    ## If the entry doesn't have a @done date, return the elapsed time
    def duration
      return nil unless should_time? && should_finish?

      return nil if @title =~ /(?<=^| )@done\b/

      Time.now - @date
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

    private

    def calc_interval
      return nil unless should_time? && should_finish?

      done = end_date
      return nil if done.nil?

      start = @date

      t = (done - start).to_i
      t.positive? ? t : nil
    end
  end
end
