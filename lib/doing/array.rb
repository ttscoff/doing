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

    # Convert an array of @tags to plain strings in place
    def tags_to_array!
      replace tags_to_array
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

    # Convert array of strings to array of @tags in place
    def to_tags!
      replace to_tags
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
      tag_color = Doing::Color.send(color)
      to_tags.map { |t| "#{tag_color}#{t}" }
    end

    ##
    ## Tag array for logging
    ##
    ## @return     [String] Highlighted tag array joined with comma
    ##
    def log_tags
      highlight_tags.join(', ')
    end

    ##
    ## Convert array to nested hash, setting last key to value
    ##
    ## @param      value  The value to set
    ##
    def nested_hash(value = nil)
      hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      hsh.dig(*self[0..-2])[fetch(-1)] = value
      hsh
    end
  end
end
