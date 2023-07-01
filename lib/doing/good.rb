# frozen_string_literal: true

module Doing
  # Numeric helpers
  class ::Numeric
    # Test of number is positive
    def good?
      self >= 0
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
      !nil? && !self&.empty? || false
    end
  end

  # Time helpers
  class ::Time
    ##
    ## Tests if object is nil
    ##
    ## @return     [Boolean] true if object is defined and
    ##             has content
    ##
    def good?
      !nil?
    end
  end

  # String helpers
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

  # Array helpers
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

  # Boolean helpers
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

  # Boolean helpers
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
