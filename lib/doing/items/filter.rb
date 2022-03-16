# frozen_string_literal: true

module Doing
  class Items < Array
    # Get a new Items object containing only items in a
    # specified section
    #
    # @param      section  [String] section title
    #
    # @return     [Items] Array of items
    #
    def in_section(section)
      if section =~ /^all$/i
        dup
      else
        items = Items.new.concat(select { |item| !item.nil? && item.section == section })
        items.add_section(section, log: false)
        items
      end
    end

    ##
    ## Search Items for a string (title and note)
    ##
    ## @param      query      [String] The query
    ## @param      case_type  [Symbol] The case type
    ##                        (:smart, :sensitive, :ignore)
    ##
    ## @return     [Items] array of items matching search
    ##
    def search(query, case_type: :smart)
      WWID.new.fuzzy_filter_items(self, query, case_type: case_type)
    end

    ##
    ## Search items by tags
    ##
    ## @param      tags  [Array,String] The tags by which to
    ##                   filter
    ## @param      bool  [Symbol] The bool with which to
    ##                   combine multiple tags
    ##
    ## @return     [Items] array of items matching tag filter
    ##
    def tagged(tags, bool: :and)
      WWID.new.filter_items(self, opt: { tag: tags, bool: bool })
    end

    ##
    ## Filter Items by date. String arguments will be
    ## chronified
    ##
    ## @param      start   [Time,String] Filter items after
    ##                     this date
    ## @param      finish  [Time,String] Filter items before
    ##                     this date
    ##
    ## @return     [Items] array of items with dates between
    ##             targets
    ##
    def between_dates(start, finish)
      start = start.chronify(guess: :begin, future: false) if start.is_a?(String)
      finish = finish.chronify(guess: :end) if finish.is_a?(String)
      WWID.new.filter_items(self, opt: { date_filter: [start, finish] })
    end
  end
end
