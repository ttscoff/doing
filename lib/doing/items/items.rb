# frozen_string_literal: true

require_relative 'filter'
require_relative 'modify'
require_relative 'sections'
require_relative 'util'

module Doing
  # A collection of Item objects
  class Items < Array
    attr_accessor :sections

    def initialize
      super
      @sections = []
    end

    ##
    ## Test if self includes Item
    ##
    ## @param      item           [Item] The item to search for
    ## @param      match_section  [Boolean] Section must match
    ##
    ## @return     [Boolean] True if Item exists
    ##
    def include?(item, match_section: true)
      includes = false
      each do |other_item|
        if other_item.equal?(item, match_section: match_section)
          includes = true
          break
        end
      end

      includes
    end

    # Find an item by ID
    #
    # @param      id    The identifier to match
    #
    def find_id(id)
      select { |item| item.id == id }[0]
    end

    ##
    ## Return the index for an entry matching ID
    ##
    ## @param      id    The identifier to match
    ##
    def index_for_id(id)
      i = nil
      each_with_index do |item, idx|
        if item.id == id
          i = idx
          break
        end
      end
      i
    end

    # Output sections and items in Doing file format
    def to_s
      out = []
      @sections.each do |section|
        out.push(section.original)
        items = in_section(section.title).sort_by { |i| [i.date, i.title] }
        items.reverse! if Doing.setting('doing_file_sort').normalize_order == :desc
        items.each { |item| out.push(item.to_s) }
      end

      out.join("\n")
    end

    # @private
    def inspect
      sections = @sections.map { |s| "<Section:#{s.title} #{in_section(s.title).count} items>" }.join(', ')
      "#<Doing::Items #{count} items, #{@sections.count} sections: #{sections}>"
    end
  end
end
