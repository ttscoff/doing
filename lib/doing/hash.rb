# frozen_string_literal: true

module Doing
  # Hash helpers
  class ::Hash
    ##
    ## Freeze all values in a hash
    ##
    ## @return     Hash with all values frozen
    ##
    def deep_freeze
      chilled = {}
      each do |k, v|
        chilled[k] = v.is_a?(Hash) ? v.deep_freeze : v.freeze
      end

      chilled.freeze
    end

    def deep_freeze!
      replace deep_thaw.deep_freeze
    end

    def deep_thaw
      chilled = {}
      each do |k, v|
        chilled[k] = v.is_a?(Hash) ? v.deep_thaw : v.dup
      end

      chilled.dup
    end

    def deep_thaw!
      replace deep_thaw
    end

    def clone
      Marshal.load(Marshal.dump(self))
    end

    # Turn all keys into string
    #
    # If the hash has both a string and a symbol for key,
    # keep the string value, discarding the symnbol value
    #
    # @return     [Hash] a copy of the hash where all its
    #             keys are strings
    #
    def stringify_keys
      each_with_object({}) do |(k, v), hsh|
        next if k.is_a?(Symbol) && key?(k.to_s)

        hsh[k.to_s] = v.is_a?(Hash) ? v.stringify_keys : v
      end
    end

    # Turn all keys into symbols
    #
    # If the hash has both a string and a symbol for a key,
    # keep the symbol value and discard the string value
    #
    # @return     [Hash] a copy of the hash where all its
    #             keys are symbols
    #
    def symbolize_keys
      each_with_object({}) do |(k, v), hsh|
        next if k.is_a?(String) && key?(k.to_sym)

        hsh[k.to_sym] = v.is_a?(Hash) ? v.symbolize_keys : v
      end
    end

    ##
    ## Turn all non-numeric values into strings
    ##
    ## @return     [Hash] a copy of the hash where all
    ##             non-numeric values are strings
    ##
    def stringify_values
      transform_values do |v|
        if v.is_a?(Hash)
          v.stringify_values
        elsif v.is_a?(Symbol)
          v.to_s
        else
          v
        end
      end
    end

    # Set a nested hash value using an array
    #
    # @example
    #   {}.deep_set(['one', 'two'], 'value')
    #   # => { 'one' => { 'two' => 'value' } }
    #
    # @param      path   [Array] key path
    # @param      value  The value
    #
    def deep_set(path, value)
      if path.count == 1
        if value.nil? || value =~ /^ *$/
          delete(path[0])
        else
          self[path[0]] = value
        end
      elsif value
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

    ##
    ## Rename a key, deleting old key
    ##
    ## @param      old_key  The original key
    ## @param      new_key  The new key
    ## @param      keep     [Boolean] if true, keep old key
    ##                      in addition to new key
    ##
    def rename_key(old_key, new_key, keep: false)
      return unless key?(old_key)

      self[new_key] = self[old_key]
      self[new_key.to_s] = self[old_key] if key?(new_key.to_s)
      delete(old_key) unless keep
    end

    ##
    ## Rename keys in batch
    ##
    ## @param      pairs  [Array] pairs of old and new keys
    ##
    def rename_keys(*pairs)
      pairs.each { |p| rename_key(p[0], p[1]) }
    end

    ##
    ## Remove keys with empty values
    ##
    def remove_empty
      delete_if { |k, v| !v.is_a?(FalseClass) && !v.good? }
    end

    def tag_filter_to_options
      hsh = dup
      if hsh.key?(:tag_filter)
        hsh[:tags] = hsh[:tag_filter][:tags]
        hsh[:bool] = hsh[:tag_filter][:bool]
        hsh.delete(:tag_filter)
      end
      replace hsh
    end

    ##
    ## Convert an options hash to a view config
    ##
    ## @return     [Hash] View representation of the object.
    ##
    def to_view
      hsh = symbolize_keys
      %w[x save c a s o h e editor m menu i interactive d delete t fuzzy time_filter sort_tags].each do |key|
        hsh.delete(key.to_sym) if hsh.key?(key.to_sym)
      end

      hsh.delete_unless_key(:tag, %i[bool])
      hsh.delete_unless_key(:search, %i[exact case])
      hsh.rename_keys(%i[not negate], %i[tag tags])
      hsh.tag_filter_to_options

      hsh = hsh.remove_empty.stringify_keys.stringify_values
      hsh.keys.sort.each_with_object({}) { |k, out| out[k] = hsh[k] }
    end

    ##
    ## Delete array of keys unless key exists
    ##
    ## @param      key        The key to verify
    ## @param      to_delete  [Array] the keys to delete if key doesn't exist
    ##
    def delete_unless_key(key, to_delete)
      unless key?(key)
        to_delete.each { |k| delete(k) }
      end
    end
  end
end
