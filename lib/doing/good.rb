# frozen_string_literal: true

module Doing
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
  end
end
