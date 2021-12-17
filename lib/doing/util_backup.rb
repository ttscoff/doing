# frozen_string_literal: true

module Doing
  ## Backup utils
  module Backup
    extend self
    include Util

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
      # Remove undone___*
      backups.shift
      result = backups.slice(count)
      raise DoingRuntimeError, 'End of undo history' unless result

      backup_file = File.join(backup_dir, result)
      write_to_file(File.join(backup_dir, "undone___#{File.basename(filename)}"), IO.read(filename), backup: false)

      FileUtils.mv(backup_file, filename)
      Doing.logger.warn('File update:', "restored from #{result}")
    end

    ##
    ## Undo last undo
    ##
    ## @param      filename  The filename
    ##
    def redo_backup(filename = nil)
      filename ||= Doing.config.settings['doing_file']
      redo_file = File.join(backup_dir, "undone___#{File.basename(filename)}")
      raise DoingRuntimeError, 'No undo file' unless File.exist?(redo_file)

      FileUtils.move(redo_file, filename)
      Doing.logger.warn('File update:', 'restored last undo')
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
        d = date_of_backup(file)
        options.push("#{d.time_ago}\t#{File.join(backup_dir, file)}")
      end
      result = Doing::Prompt.choose_from(options,
                                         sorted: false,
                                         fzf_args: [
                                           '--delimiter="\t"',
                                           '--with-nth=1',
                                           %(--preview='diff -u "#{filename}" {2} | awk "(NR>2)"'),
                                           '--preview-window="right,70%,wrap,follow"'
                                         ])
      raise UserCancelled unless result

      backup_file = result.strip.split(/\t/).last
      # backup_file = File.join(backup_dir, options[result])
      write_to_file(File.join(backup_dir, "undone___#{File.basename(filename)}"), IO.read(filename), backup: false)
      FileUtils.mv(backup_file, filename)
      prune_backups_after(File.basename(backup_file))
      Doing.logger.warn('File update:', "restored from #{backup_file}")
    end

    ##
    ## Writes a copy of the content to a dated backup file
    ## in a hidden directory
    ##
    ## @param      content  The data to back up
    ##
    def write_backup(content, filename = 'doing_backup.md')
      raise DoingRuntimeError, 'Backup content empty' unless content

      backup_file = File.join(backup_dir, "#{Time.now.strftime('%Y-%m-%d_%H.%M.%S')}___#{File.basename(filename)}")
      # compressed = Zlib::Deflate.deflate(content)

      File.open(backup_file, 'w') do |f|
        f.puts content
      end

      prune_backups(filename, 100)
    end

    private

    ##
    ## Retrieve date from backup filename
    ##
    ## @param      filename  The filename
    ##
    def date_of_backup(filename)
      m = filename.match(/^(?<date>\d{4}-\d{2}-\d{2})_(?<time>\d{2}\.\d{2}\.\d{2})___(?<file>.*?)$/)
      Time.parse("#{m['date']} #{m['time']}")
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
      Doing.logger.warn('Backup:', "backup directory created at #{dir}")
      dir
    end

    ##
    ## Delete backups newer than selected filename
    ##
    ## @param      filename  The filename
    ##
    def prune_backups_after(filename)
      target_date = date_of_backup(filename)
      counter = 0
      Dir.glob("*___#{m['file']}", base: backup_dir).each do |file|
        date = date_of_backup(file)
        if target_date < date
          FileUtils.rm(File.join(backup_dir, file))
          counter += 1
        end
      end
      Doing.logger.debug('Backup:', "deleted #{counter} files newer than restored backup")
    end
  end
end
