# frozen_string_literal: true

module Doing
  # Hash helpers
  class ::Hash
    ##
    ## Freeze all values in a hash
    ##
    ## @return     { description_of_the_return_value }
    ##
    def deep_freeze
      map { |k, v| v.is_a?(Hash) ? v.deep_freeze : v.freeze }.freeze
    end

    def deep_freeze!
      replace deep_freeze
    end

    # Turn all keys into string
    #
    # Return a copy of the hash where all its keys are strings
    def stringify_keys
      each_with_object({}) { |(k, v), hsh| hsh[k.to_s] = v.is_a?(Hash) ? v.stringify_keys : v }
    end

    # Turn all keys into symbols
    def symbolize_keys
      each_with_object({}) { |(k, v), hsh| hsh[k.to_sym] = v.is_a?(Hash) ? v.symbolize_keys : v }
    end

    # Set a nested hash value using an array
    #
    # @example `{}.deep_set(['one', 'two'], 'value')`
    # @example `=> { 'one' => { 'two' => 'value' } }
    #
    # @param      path   [Array] key path
    # @param      value  The value
    #
    def deep_set(path, value)
      if path.count == 1
        unless value.nil? || value =~ /^ *$/
          self[path[0]] = value
        else
          delete(path[0])
        end
      else
        if value
          self.default_proc = ->(h, k) { h[k] = Hash.new(&h.default_proc) }
          dig(*path[0..-2])[path.fetch(-1)] = value
        else
          return self unless dig(*path)

          dig(*path[0..-2]).delete(path.fetch(-1))
          path.pop
          cleaned = self
          path.each do |key|
            if cleaned[key].empty?
              cleaned.delete(key)
              break
            end
            cleaned = cleaned[key]
          end
          empty? ? nil : self
        end
      end
    end
  end
end
