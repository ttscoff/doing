# frozen_string_literal: true

module Doing
  # Numeric helpers
  class ::Numeric
    # Test of number is positive
    def good?
      positive?
    end
  end

  # Object helpers
  class ::Object
    ##
    ## Tests if object is nil or empty
    ##
    ## @return     [Boolean] true if object is defined and
    ##             has content
    ##
    def good?
      !nil? && !empty?
    end
  end

  class ::String
    ##
    ## Tests if object is nil or empty
    ##
    ## @return     [Boolean] true if object is defined and
    ##             has content
    ##
    def good?
      !strip.empty?
    end
  end

  class ::Array
    ##
    ## Tests if object is nil or empty
    ##
    ## @return     [Boolean] true if object is defined and
    ##             has content
    ##
    def good?
      !nil? && !empty?
    end
  end

  class ::FalseClass
    ##
    ## Tests if object is nil or empty
    ##
    ## @return     [Boolean] true if object is defined and
    ##             has content
    ##
    def good?
      false
    end

    def normalize_tag_sort
      :time
    end
  end

  class ::TrueClass
    ##
    ## Tests if object is nil or empty
    ##
    ## @return     [Boolean] true if object is defined and
    ##             has content
    ##
    def good?
      true
    end

    def normalize_tag_sort
      :name
    end
  end
end
