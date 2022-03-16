# frozen_string_literal: true

module Doing
  class Items < Array
    ##
    ## Get all tags on Items in self
    ##
    ## @return     [Array] array of tags
    ##
    def all_tags
      each_with_object([]) do |entry, tags|
        tags.concat(entry.tags).sort!.uniq!
      end
    end

    ##
    ## Return Items containing items that don't exist in
    ## receiver
    ##
    ## @param      items  [Items] Receiver
    ##
    ## @return     [Hash] Hash of added and deleted items
    ##
    def diff(items)
      a = clone
      b = items.clone

      a.delete_if do |item|
        if b.index(item)
          b.delete(item)
          true
        else
          false
        end
      end
      { deleted: b, added: a }
    end

    ##
    ## Remove duplicated entries. Duplicate entries must have matching start date, title, note, and section
    ##
    ## @return     [Items] Items array with duplicate entries removed
    ##
    def dedup(match_section: true)
      unique = Items.new
      each do |item|
        unique.push(item) unless unique.include?(item, match_section: match_section)
      end

      unique
    end

    # @see #dedup
    def dedup!(match_section: true)
      replace dedup(match_section: match_section)
    end
  end
end
