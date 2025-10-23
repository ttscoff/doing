# frozen_string_literal: true

module Doing
  module ArrayCleanup
    ##
    ## Like Array#compact -- removes nil items, but also
    ## removes empty strings, zero or negative numbers and FalseClass items
    ##
    ## @return     [Array] Array without "bad" elements
    ##
    def remove_bad
      compact.map { |x| x.is_a?(String) ? x.strip : x }.select(&:good?)
    end

    def remove_bad!
      replace remove_empty
    end

    ##
    ## Like Array#compact -- removes nil items, but also
    ## removes empty elements
    ##
    ## @return     [Array] Array without empty elements
    ##
    def remove_empty
      compact.map { |x| x.is_a?(String) ? x.strip : x }.reject { |x| x.is_a?(String) ? x.empty? : false }
    end

    def remove_empty!
      replace remove_empty
    end
  end
end
