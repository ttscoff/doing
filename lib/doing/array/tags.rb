# frozen_string_literal: true

module Doing
  ##
  ## Array helpers
  ##
  class ::Array
    ##
    ## Convert an array of @tags to plain strings
    ##
    ## @return     [Array] array of strings
    ##
    def tags_to_array
      map(&:remove_at).map(&:strip)
    end

    # Convert array of strings to array of @tags
    #
    # @return     [Array] Array of @tags
    #
    # @example
    #   ['one', '@two', 'three'].to_tags
    #   # => ['@one', '@two', '@three']
    def to_tags
      map(&:add_at)
    end

    ##
    ## Hightlight @tags in string for console output
    ##
    ## @param      color  [String] the color to highlight
    ##                    with
    ##
    ## @return     [Array] Array of highlighted @tags
    ##
    def highlight_tags(color = 'cyan')
      to_tags.map { |t| Doing::Color.send(color.to_sym, t) }
    end

    ##
    ## Tag array for logging
    ##
    ## @return     [String] Highlighted tag array joined with comma
    ##
    def log_tags(color = 'cyan')
      highlight_tags(color).join(', ')
    end
  end
end
