# frozen_string_literal: true
require 'zlib'

module Doing
  module Util
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
        backups = get_backups(filename)
        return unless backups.count > limit

        backups[limit..-1].each do |file|
          FileUtils.rm(File.join(backup_dir, file))
        end

        clear_redo(filename)
      end

      ##
      ## Delete all redo files
      ##
      ## @param      limit  Maximum number of backups to retain
      ##
      def clear_redo(filename)
        filename ||= Doing.config.settings['doing_file']
        backups = Dir.glob("undone*___#{File.basename(filename)}", base: backup_dir).sort.reverse
        backups.each do |file|
          FileUtils.rm(File.join(backup_dir, file))
        end
      end

      ##
      ## Retrieve the most recent backup
      ##
      ## @param      filename  The filename
      ## @return     [String] filename
      ##
      def last_backup(filename = nil, count: 1)
        filename ||= Doing.config.settings['doing_file']

        backup = get_backups(filename).slice(count - 1)
        backup.nil? ? nil : File.join(backup_dir, backup)
      end

      ##
      ## Restore the most recent backup. If a filename is
      ## provided, only backups of that filename will be used.
      ##
      ## @param      filename  The filename to restore, if
      ##                       different from default
      ##
      def restore_last_backup(filename = nil, count: 1)
        Doing.logger.benchmark(:restore_backup, :start)
        filename ||= Doing.config.settings['doing_file']

        backup_file = last_backup(filename, count: count)
        raise DoingRuntimeError, 'End of undo history' if backup_file.nil?

        save_undone(filename)
        FileUtils.mv(backup_file, filename)
        prune_backups_after(File.basename(backup_file))
        Doing.logger.warn('File update:', "restored from #{backup_file}")
        Doing.logger.benchmark(:restore_backup, :finish)
      end

      ##
      ## Undo last undo
      ##
      ## @param      filename  The filename
      ##
      def redo_backup(filename = nil, count: 1)
        filename ||= Doing.config.settings['doing_file']
        # redo_file = File.join(backup_dir, "undone___#{File.basename(filename)}")
        undones = Dir.glob("undone*#{File.basename(filename)}", base: backup_dir).sort.reverse
        total = undones.count
        count = total if count > total

        skipped = undones.slice!(0, count)
        undone = skipped.pop

        raise DoingRuntimeError, 'End of redo history' if undone.nil?

        redo_file = File.join(backup_dir, undone)

        FileUtils.move(redo_file, filename)

        skipped.each do |f|
          FileUtils.mv(File.join(backup_dir, f), File.join(backup_dir, f.sub(/^undone/, '')))
        end

        Doing.logger.warn('File update:', "restored undo step #{count}/#{total}")
        Doing.logger.debug('Backup:', "#{total - skipped.count - 1} redos remaining")
      end

      def clear_undone(filename = nil)
        filename ||= Doing.config.settings['doing_file']
        # redo_file = File.join(backup_dir, "undone___#{File.basename(filename)}")
        Dir.glob("undone*#{File.basename(filename)}", base: backup_dir).each do |f|
          FileUtils.rm(File.join(backup_dir, f))
        end
      end

      ##
      ## Select from recent undos. If a filename is
      ## provided, only backups of that filename will be used.
      ##
      ## @param      filename  The filename to restore
      ##
      def select_redo(filename = nil)
        filename ||= Doing.config.settings['doing_file']

        undones = Dir.glob("undone*#{File.basename(filename)}", base: backup_dir).sort

        raise DoingRuntimeError, 'End of redo history' if undones.empty?

        total = undones.count
        options = undones.each_with_object([]) do |file, arr|
          d, _base = date_of_backup(file)
          next if d.nil?

          arr.push("#{d.time_ago}\t#{File.join(backup_dir, file)}")
        end

        raise DoingRuntimeError, 'No backup files to load' if options.empty?

        backup_file = show_menu(options, filename)
        idx = undones.index(File.basename(backup_file))
        skipped = undones.slice!(idx, undones.count - idx)
        undone = skipped.shift

        redo_file = File.join(backup_dir, undone)

        FileUtils.move(redo_file, filename)

        skipped.each do |f|
          FileUtils.mv(File.join(backup_dir, f), File.join(backup_dir, f.sub(/^undone/, '')))
        end

        Doing.logger.warn('File update:', "restored undo step #{idx}/#{total}")
        Doing.logger.debug('Backup:', "#{total - skipped.count - 1} redos remaining")
      end

      ##
      ## Select from recent backups. If a filename is
      ## provided, only backups of that filename will be used.
      ##
      ## @param      filename  The filename to restore
      ##
      def select_backup(filename = nil)
        filename ||= Doing.config.settings['doing_file']

        options = get_backups(filename).each_with_object([]) do |file, arr|
          d, _base = date_of_backup(file)
          next if d.nil?
          arr.push("#{d.time_ago}\t#{File.join(backup_dir, file)}")
        end

        raise DoingRuntimeError, 'No backup files to load' if options.empty?

        backup_file = show_menu(options, filename)
        Util.write_to_file(File.join(backup_dir, "undone___#{File.basename(filename)}"), IO.read(filename), backup: false)
        FileUtils.mv(backup_file, filename)
        prune_backups_after(File.basename(backup_file))
        Doing.logger.warn('File update:', "restored from #{backup_file}")
      end

      def show_menu(options, filename)
        if TTY::Which.which('colordiff')
          preview = 'colordiff -U 1'
          pipe = '| awk "(NR>2)"'
        elsif TTY::Which.which('git')
          preview = 'git --no-pager diff -U1 --color=always --minimal --word-diff'
          pipe = ' | awk "(NR>4)"'
        else
          preview = 'diff -U 1'
          pipe = if TTY::Which.which('delta')
                   ' | delta --no-gitconfig --syntax-theme=1337'
                 elsif TTY::Which.which('diff-so-fancy')
                   ' | diff-so-fancy'
                 elsif TTY::Which.which('ydiff')
                   ' | ydiff -c always --wrap < /dev/tty'
                 else
                   cmd = 'sed -e "s/^-/`echo -e "\033[31m"`-/;s/^+/`echo -e "\033[32m"`+/;s/^@/`echo -e "\033[34m"`@/;s/\$/`echo -e "\033[0m"`/"'
                   "| bash -c #{Shellwords.escape(cmd)}"
                 end
          pipe += ' | awk "(NR>2)"'
        end

        result = Doing::Prompt.choose_from(options,
                                           prompt: 'Select a backup to restore',
                                           sorted: false,
                                           fzf_args: [
                                             '--delimiter="\t"',
                                             '--with-nth=1',
                                             %(--preview='#{preview} "#{filename}" {2} #{pipe}'),
                                             '--disabled',
                                             '--height=10',
                                             '--preview-window="right,70%,nowrap,follow"',
                                             '--header="Select a revision to restore"'
                                           ])
        raise UserCancelled unless result

        result.strip.split(/\t/).last
      end

      ##
      ## Writes a copy of the content to a dated backup file
      ## in a hidden directory
      ##
      ## @param      content  The data to back up
      ##
      def write_backup(filename = nil)
        Doing.logger.benchmark(:_write_backup, :start)
        filename ||= Doing.config.settings['doing_file']

        unless File.exist?(filename)
          Doing.logger.debug('Backup:', "original file doesn't exist (#{filename})")
          return
        end

        backup_file = File.join(backup_dir, "#{timestamp_filename}___#{File.basename(filename)}")
        # compressed = Zlib::Deflate.deflate(content)
        # Zlib::GzipWriter.open(backup_file + '.gz') do |gz|
        #   gz.write(IO.read(filename))
        # end

        FileUtils.cp(filename, backup_file)

        prune_backups(filename, Doing.config.settings['history_size'].to_i)
        clear_undone(filename)
        Doing.logger.benchmark(:_write_backup, :finish)
      end

      private

      def timestamp_filename
        Time.now.strftime('%Y-%m-%d_%H.%M.%S')
      end

      def get_backups(filename = nil, include_forward: false)
        filename ||= Doing.config.settings['doing_file']
        backups = Dir.glob("*___#{File.basename(filename)}", base: backup_dir).sort.reverse
        backups.delete_if { |f| f =~ /^undone/ } unless include_forward
      end

      def save_undone(filename = nil)
        filename ||= Doing.config.settings['doing_file']
        undone_file = File.join(backup_dir, "undone#{timestamp_filename}___#{File.basename(filename)}")
        FileUtils.cp(filename, undone_file)
      end

      ##
      ## Retrieve date from backup filename
      ##
      ## @param      filename  The filename
      ##
      def date_of_backup(filename)
        m = filename.match(/^(?:undone)?(?<date>\d{4}-\d{2}-\d{2})_(?<time>\d{2}\.\d{2}\.\d{2})___(?<file>.*?)$/)
        return nil if m.nil?

        [Time.parse("#{m['date']} #{m['time'].gsub(/\./, ':')}"), m['file']]
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
        dir = File.expand_path(Doing.config.settings['backup_dir']) || File.join(user_home, '.doing_backup')
        if File.exist?(dir) && !File.directory?(dir)
          raise DoingRuntimeError, "Backup error: #{dir} is not a directory"

        end

        unless File.exist?(dir)
          FileUtils.mkdir_p(dir)
          Doing.logger.warn('Backup:', "backup directory created at #{dir}")
        end

        dir
      end

      ##
      ## Delete backups newer than selected filename
      ##
      ## @param      filename  The filename
      ##
      def prune_backups_after(filename)
        target_date, base = date_of_backup(filename)
        return if target_date.nil?

        counter = 0
        get_backups(base).each do |file|
          date, _base = date_of_backup(file)
          if date && target_date < date
            FileUtils.mv(File.join(backup_dir, file), File.join(backup_dir, "undone#{file}"))
            counter += 1
          end
        end
        Doing.logger.debug('Backup:', "deleted #{counter} files newer than restored backup")
      end
    end
  end
end
