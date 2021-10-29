# frozen_string_literal: true

module Doing
  # Utilities
  module Util
    extend self

    def user_home
      if Dir.respond_to?('home')
        Dir.home
      else
        File.expand_path('~')
      end
    end

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

    def merge_default_proc(target, overwrite)
      return unless target.is_a?(Hash) && overwrite.is_a?(Hash) && target.default_proc.nil?

      target.default_proc = overwrite.default_proc
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
      value.is_a?(Hash)
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

    ##
    ## @brief      Write content to a file
    ##
    ## @param      file     (String) The path to the file to (over)write
    ## @param      content  (String) The content to write to the file
    ## @param      backup   (Boolean) create a ~ backup
    ##
    def write_to_file(file, content, backup: true)
      file = File.expand_path(file)

      if File.exist?(file) && backup
        # Create a backup copy for the undo command
        FileUtils.cp(file, "#{file}~")
      end

      File.open(file, 'w+') do |f|
        f.puts content
      end

      Hooks.trigger :post_write, file
    end
  end
end
