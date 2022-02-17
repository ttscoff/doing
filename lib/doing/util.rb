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
    ## Test if command line tool is available
    ##
    ## @param      cli   [String] The name or path of the cli
    ##
    def exec_available(cli)
      return false unless cli.good?

      !TTY::Which.which(cli).nil?
    end

    ##
    ## Return the first valid executable from a list of commands
    ##
    ## @example
    ##   Doing::Util.first_available_exec('bat', 'less -Xr', 'more -r', 'cat')
    ##
    def first_available_exec(*commands)
      commands.compact.map(&:strip).reject(&:empty?).uniq
              .find { |cmd| exec_available(cmd.split.first) }
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

    # Non-destructive version of deep_merge_hashes! See that
    # method.
    #
    # @return     the merged hashes.
    #
    # @param      [Hash] master_hash  The master hash
    # @param      [Hash] other_hash   The other hash
    #
    def deep_merge_hashes(master_hash, other_hash)
      deep_merge_hashes!(master_hash.clone, other_hash)
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

    def duplicable?(obj)
      case obj
      when nil, false, true, Symbol, Numeric
        false
      else
        true
      end
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
    ## Write content to a file
    ##
    ## @param      file     [String] The path to the file to (over)write
    ## @param      content  [String] The content to write to the file
    ## @param      backup   [Boolean] create a ~ backup
    ##
    def write_to_file(file, content, backup: true)
      unless file
        puts content
        return
      end
      Doing.logger.benchmark(:write_file, :start)
      file = File.expand_path(file)

      Backup.write_backup(file) if backup

      File.open(file, 'w+') do |f|
        f.puts content
        Doing.logger.debug('Write:', "File written: #{file}")
      end
      Doing.logger.benchmark(:_post_write_hook, :start)
      Hooks.trigger :post_write, file
      Doing.logger.benchmark(:_post_write_hook, :finish)
      Doing.logger.benchmark(:write_file, :finish)
    end

    def safe_load_file(filename)
      SafeYAML.load_file(filename) || {}
    end

    def default_editor
      @default_editor ||= find_default_editor
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

    def find_default_editor(editor_for = 'default')
      # return nil unless $stdout.isatty || ENV['DOING_EDITOR_TEST']

      return ENV['EDITOR'] if ENV['DOING_EDITOR_TEST']

      editor_config = Doing.setting('editors')

      if editor_config.is_a?(String)
        msg = "Please update your configuration, 'editors' should be a mapping."
        msg << ' Delete the key and run `doing config --update`.'
        Doing.logger.warn('Deprecated:', msg)
        return editor_config
      end

      if editor_config[editor_for]
        editor = editor_config[editor_for]
        Doing.logger.debug('Editor:', "Using #{editor} from config 'editors.#{editor_for}' for #{editor_for}")
        return editor if editor.good?
      end

      if editor_for != 'editor' && editor_config['default']
        editor = editor_config['default']
        Doing.logger.debug('Editor:', "Using #{editor} from config: 'editors.default' for #{editor_for}")
        return editor if editor.good?
      end

      editor ||= ENV['DOING_EDITOR'] || ENV['GIT_EDITOR'] || ENV['EDITOR']

      if editor.good?
        Doing.logger.debug('Editor:', "Found editor in environment variables: #{editor} for #{editor_for}")
        return editor
      end

      Doing.logger.debug('Editor:', 'No EDITOR environment variable, testing available editors')
      editors = %w[vim vi code subl mate mvim nano emacs]
      editors.each do |ed|
        try = TTY::Which.which(ed)
        if try
          Doing.logger.debug('Editor:', "Using editor #{try} for #{editor_for}")
          return try
        end

        Doing.logger.debug('Editor:', "#{ed} not available")
      end

      nil
    end
  end
end
