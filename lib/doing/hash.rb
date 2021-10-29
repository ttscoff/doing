# frozen_string_literal: true

module Doing
  class ::Hash
    # Public: Turn all keys into string
    #
    # Return a copy of the hash where all its keys are strings
    def stringify_keys
      each_with_object({}) { |(k, v), hsh| hsh[k.to_s] = v }
    end

    def stringify_keys!
      replace stringify_keys
    end
  end
end
