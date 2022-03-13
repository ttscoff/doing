module Doing
  # State queries for a Doing entry
  class Item
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
  end
end
