# frozen_string_literal: true

module Doing
  ##
  ## Array helpers
  ##
  class ::Array
    ##
    ## Convert an @tags to plain strings
    ##
    ## @return     [Array] array of strings
    ##
    def tags_to_array
      map { |t| t.sub(/^@/, '') }
    end

    # Convert strings to @tags
    #
    # @example `['one', '@two', 'three'].to_tags`
    # @example `=> ['@one', '@two', '@three']`
    # @return     [Array] Array of @tags
    #
    def to_tags
      map { |t| t.sub(/^@?/, '@') }
    end

    def to_tags!
      replace to_tags
    end

    ##
    ## Hightlight @tags in string for console output
    ##
    ## @param      color  [String] the color to highlight
    ##                    with
    ##
    ## @return     [String] string with @tags highlighted
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
    def nested_hash(value)
      raise StandardError, 'Value can not be nil' if value.nil?

      hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      hsh.dig(*self[0..-2])[self.fetch(-1)] = value
      hsh
    end
  end
end
