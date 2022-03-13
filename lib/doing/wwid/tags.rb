# frozen_string_literal: true

module Doing
  # Tag methods for WWID class
  class WWID
    ##
    ## List all tags that exist on given items
    ##
    ## @param      items   [Array] array of Item
    ## @param      opt     [Hash] additional options
    ## @param      counts  [Boolean] Include tag counts in
    ##                     results
    ##
    ## @return     [Hash or Array] if counts is true, returns a
    ##             hash with { tag: count }. If false, returns a
    ##             simple array of tags.
    ##
    def all_tags(items, opt: {}, counts: false)
      if counts
        all_tags = {}
        items.each do |item|
          item.tags.each do |tag|
            if all_tags.key?(tag.downcase)
              all_tags[tag.downcase] += 1
            else
              all_tags[tag.downcase] = 1
            end
          end
        end

        all_tags.sort_by { |_, count| count }
      else
        all_tags = []
        items.each { |item| all_tags.concat(item.tags.map(&:downcase)).uniq! }
        all_tags.sort
      end
    end

    def tag_groups(items, opt: {})
      all_items = filter_items(items, opt: opt)
      tags = all_tags(all_items, opt: {})
      groups = {}
      tags.each do |tag|
        groups[tag] ||= []
        groups[tag] = filter_items(all_items, opt: { tag: tag, tag_bool: :or })
      end

      groups
    end
  end
end
