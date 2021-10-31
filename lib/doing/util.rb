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
      return false if cli.nil?

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
      unless file
        puts content
        return
      end

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

    def safe_load_file(filename)
      SafeYAML.load_file(filename) || {}
    end

    def default_editor
      @default_editor = find_default_editor
    end

    def editor_with_args
      args_for_editor(default_editor)
    end

    def args_for_editor(editor)
      return editor if editor =~ /-\S/

      args = case editor
             when /^(subl|code|mate)$/
               ['-w']
             when /^(vim|mvim)$/
               ['-f']
             else
               []
             end
      "#{editor} #{args.join(' ')}"
    end

    def find_default_editor(editor_for = 'editor')
      if ENV['DOING_EDITOR_TEST']
        return ENV['EDITOR']
      end

      if Doing.config.settings[editor_for]
        editor = Doing.config.settings[editor_for]
        Doing.logger.debug('ENV:', "Using #{editor} from config")
        return editor unless editor.nil? || editor.empty?
      end

      if editor_for != 'editor' && Doing.config.settings['editor']
        editor = Doing.config.settings['editor']
        Doing.logger.debug('ENV:', "Using #{editor} from config")
        return editor unless editor.nil? || editor.empty?
      end

      editor ||= ENV['DOING_EDITOR'] || ENV['GIT_EDITOR'] || ENV['EDITOR']

      unless editor.nil?
        Doing.logger.debug('Found editor in environment variables')
        return editor unless editor.nil? || editor.empty?
      end

      Doing.logger.debug('ENV:', 'No EDITOR environment variable, testing available editors')
      editors = %w[vim vi code subl mate mvim nano emacs]
      editors.each do |ed|
        return ed if exec_available(ed)
        Doing.logger.debug('ENV:', "#{ed} not available")
      end

      nil
    end
  end
end
