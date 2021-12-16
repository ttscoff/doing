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
      return false if cli.nil?

      !TTY::Which.which(cli).nil?
    end

    ##
    ## Return the first valid executable from a list of commands
    ##
    ## @example `Doing::Util.first_available_exec('bat', 'less -Xr', 'more -r', 'cat')`
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
    ## Return a location for storing backups, creating if needed
    ##
    ## @return     Path to backup directory
    ##
    def backup_dir
      @backup_dir ||= create_backup_dir
    end

    def create_backup_dir
      dir = File.join(user_home, '.doing_backup')
      if File.exist?(dir) && !File.directory?(dir)
        raise DoingRuntimeError, "Backup error: #{dir} is not a directory"

      end

      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      dir
    end

    ##
    ## Writes a copy of the content to a dated backup file
    ## in a hidden directory
    ##
    ## @param      content  The data to back up
    ##
    def write_backup(content, filename = 'doing_backup.md')
      raise DoingRuntimeError, 'Backup content empty' unless content

      backup_file = File.join(backup_dir, "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')}___#{File.basename(filename)}")
      # compressed = Zlib::Deflate.deflate(content)

      File.open(backup_file, 'w') do |f|
        f.puts content
      end

      prune_backups(filename, 100)
    end

    ##
    ## Delete all but most recent 5 backups
    ##
    ## @param      limit  Maximum number of backups to retain
    ##
    def prune_backups(filename, limit = 10)
      backups = Dir.glob("*___#{File.basename(filename)}", base: backup_dir).sort.reverse
      return unless backups.count > limit

      backups[limit..-1].each do |file|
        FileUtils.rm(File.join(backup_dir, file))
      end
    end

    ##
    ## Restore the most recent backup. If a filename is
    ## provided, only backups of that filename will be used.
    ##
    ## @param      filename  The filename to restore, if
    ##                       different from default
    ##
    def restore_last_backup(filename = nil, count: 1)
      filename ||= Doing.config.settings['doing_file']
      backups = Dir.glob("*___#{File.basename(filename)}", base: backup_dir).sort.reverse
      result = backups.slice(count)
      raise DoingRuntimeError, 'No backups exist' unless result

      backup_file = File.join(backup_dir, result)
      write_backup(IO.read(backup_file), filename)

      FileUtils.mv(backup_file, filename)
      Doing.logger.warn('File update:', "restored from #{result}")
    end

    ##
    ## Select from recent backups. If a filename is
    ## provided, only backups of that filename will be used.
    ##
    ## @param      filename  The filename to restore
    ##
    def select_backup(filename = nil)
      filename ||= Doing.config.settings['doing_file']
      backups = Dir.glob("*___#{File.basename(filename)}", base: backup_dir).sort.reverse[1..-1]
      options = []
      backups.each do |file|
        m = file.match(/^(?<date>\d{4}-\d{2}-\d{2})_(?<time>\d{2}:\d{2}:\d{2})___.*?$/)
        d = Time.parse("#{m['date']} #{m['time']}")
        options.push("#{d.time_ago}\t#{File.join(backup_dir, file)}")
      end
      result = Doing::Prompt.choose_from(options,
                                        sorted: false,
                                        fzf_args: ['--delimiter="\t"', '--with-nth=1', %(--preview='diff -u "#{filename}" {2} | awk "(NR>2)"'), '--preview-window="right,70%,wrap,follow"'])
      raise UserCancelled unless result

      backup_file = result.strip.split(/\t/).last
      # backup_file = File.join(backup_dir, options[result])
      write_backup(IO.read(backup_file), filename)

      FileUtils.mv(backup_file, filename)
      Doing.logger.warn('File update:', "restored from #{backup_file}")
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

      file = File.expand_path(file)

      write_backup(content, file) if backup

      if File.exist?(file) && backup
        # Create a backup copy for the undo command
        FileUtils.cp(file, "#{file}~")
      end

      File.open(file, 'w+') do |f|
        f.puts content
        Doing.logger.debug('Write:', "File written: #{file}")
      end

      Hooks.trigger :post_write, file
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

      if ENV['DOING_EDITOR_TEST']
        return ENV['EDITOR']
      end

      editor_config = Doing.config.settings['editors']

      if editor_config.is_a?(String)
        Doing.logger.warn('Deprecated:', "Please update your configuration, 'editors' should be a mapping. Delete the key and run `doing config --update`.")
        return editor_config
      end

      if editor_config[editor_for]
        editor = editor_config[editor_for]
        # Doing.logger.debug('Editor:', "Using #{editor} from config 'editors->#{editor_for}'")
        return editor unless editor.nil? || editor.empty?
      end

      if editor_for != 'editor' && editor_config['default']
        editor = editor_config['default']
        # Doing.logger.debug('Editor:', "Using #{editor} from config: 'editors->default'")
        return editor unless editor.nil? || editor.empty?
      end

      editor ||= ENV['DOING_EDITOR'] || ENV['GIT_EDITOR'] || ENV['EDITOR']

      unless editor.nil? || editor.empty?
        # Doing.logger.debug('Editor:', "Found editor in environment variables: #{editor}")
        return editor
      end

      Doing.logger.debug('ENV:', 'No EDITOR environment variable, testing available editors')
      editors = %w[vim vi code subl mate mvim nano emacs]
      editors.each do |ed|
        return TTY::Which.which(ed) if TTY::Which.which(ed)

        Doing.logger.debug('ENV:', "#{ed} not available")
      end

      nil
    end
  end
end
