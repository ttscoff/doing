# frozen_string_literal: true

module Doing
  ##
  ## Array helpers
  ##
  module ArrayNestedHash
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
