module Doing
  module Util
    extend self

    ##
    ## @brief      Test if command line tool is available
    ##
    ## @param      cli   (String) The name or path of the cli
    ##
    def exec_available(cli)
      if File.exist?(File.expand_path(cli))
        File.executable?(File.expand_path(cli))
      else
        system "which #{cli}", out: File::NULL, err: File::NULL
      end
    end


    def merge_values(target, overwrite)
      target.merge!(overwrite) do |_key, old_val, new_val|
        if new_val.nil?
          old_val
        elsif mergable?(old_val) && mergable?(new_val)
          deep_merge_hashes(old_val, new_val)
        else
          new_val
        end
      end
    end

    def merge_default_proc(target, overwrite)
      if target.is_a?(Hash) && overwrite.is_a?(Hash) && target.default_proc.nil?
        target.default_proc = overwrite.default_proc
      end
    end

    def duplicate_frozen_values(target)
      target.each do |key, val|
        target[key] = val.dup if val.frozen? && duplicable?(val)
      end
    end

    # Non-destructive version of deep_merge_hashes! See that method.
    #
    # Returns the merged hashes.
    def deep_merge_hashes(master_hash, other_hash)
      deep_merge_hashes!(master_hash.dup, other_hash)
    end

    # Merges a master hash with another hash, recursively.
    #
    # master_hash - the "parent" hash whose values will be overridden
    # other_hash  - the other hash whose values will be persisted after the merge
    #
    # This code was lovingly stolen from some random gem:
    # http://gemjack.com/gems/tartan-0.1.1/classes/Hash.html
    #
    # Thanks to whoever made it.
    def deep_merge_hashes!(target, overwrite)
      merge_values(target, overwrite)
      merge_default_proc(target, overwrite)
      duplicate_frozen_values(target)

      target
    end

    def mergable?(value)
      value.is_a?(Hash) || value.is_a?(Drops::Drop)
    end

    def merge_values(target, overwrite)
      target.merge!(overwrite) do |_key, old_val, new_val|
        if new_val.nil?
          old_val
        elsif mergable?(old_val) && mergable?(new_val)
          deep_merge_hashes(old_val, new_val)
        else
          new_val
        end
      end
    end

    def merge_default_proc(target, overwrite)
      if target.is_a?(Hash) && overwrite.is_a?(Hash) && target.default_proc.nil?
        target.default_proc = overwrite.default_proc
      end
    end

    def duplicate_frozen_values(target)
      target.each do |key, val|
        target[key] = val.dup if val.frozen? && duplicable?(val)
      end
    end
  end
end
