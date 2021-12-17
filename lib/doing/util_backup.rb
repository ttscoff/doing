# frozen_string_literal: true

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

        result = get_backups(filename).slice(count - 1)
        raise DoingRuntimeError, 'End of undo history' if result.nil?

        backup_file = File.join(backup_dir, result)

        save_undone(filename)
        FileUtils.mv(backup_file, filename)
        prune_backups_after(File.basename(backup_file))
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

        options = get_backups(filename).each_with_object([]) do |file, arr|
          d, _base = date_of_backup(file)
          arr.push("#{d.time_ago}\t#{File.join(backup_dir, file)}")
        end

        backup_file = show_menu(options, filename)
        write_to_file(File.join(backup_dir, "undone___#{File.basename(filename)}"), IO.read(filename), backup: false)
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
          preview = 'diff -u'
          pipe = if TTY::Which.which('delta')
                   ' | delta --no-gitconfig --syntax-theme=1337'
                 elsif TTY::Which.which('diff-so-fancy')
                   ' | diff-so-fancy'
                 elsif TTY::Which.which('ydiff')
                   ' | ydiff -c always --wrap < /dev/tty'
                 else
                   ''
                 end
          pipe += ' | awk "(NR>2)"'
        end

        result = Doing::Prompt.choose_from(options,
                                           sorted: false,
                                           fzf_args: [
                                             '--delimiter="\t"',
                                             '--with-nth=1',
                                             %(--preview='#{preview} "#{filename}" {2} #{pipe}'),
                                             '--preview-window="right,70%,wrap,follow"'
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
        filename ||= Doing.config.settings['doing_file']

        unless File.exist?(filename)
          Doing.logger.debug('Backup:', "original file doesn't exist (#{filename})")
          return
        end

        backup_file = File.join(backup_dir, "#{Time.now.strftime('%Y-%m-%d_%H.%M.%S')}___#{File.basename(filename)}")
        # compressed = Zlib::Deflate.deflate(content)

        FileUtils.cp(filename, backup_file)

        prune_backups(filename, 100)
      end

      private

      def get_backups(filename = nil)
        filename ||= Doing.config.settings['doing_file']
        backups = Dir.glob("*___#{File.basename(filename)}", base: backup_dir).sort.reverse
        backups.delete_if { |f| f =~ /^undone/ }
      end

      def save_undone(filename = nil)
        filename ||= Doing.config.settings['doing_file']
        undone_file = File.join(backup_dir, "undone___#{File.basename(filename)}")
        FileUtils.cp(filename, undone_file)
      end

      ##
      ## Retrieve date from backup filename
      ##
      ## @param      filename  The filename
      ##
      def date_of_backup(filename)
        m = filename.match(/^(?<date>\d{4}-\d{2}-\d{2})_(?<time>\d{2}\.\d{2}\.\d{2})___(?<file>.*?)$/)
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
        counter = 0
        get_backups(base).each do |file|
          date, _base = date_of_backup(file)
          if date && target_date < date
            FileUtils.rm(File.join(backup_dir, file))
            counter += 1
          end
        end
        Doing.logger.debug('Backup:', "deleted #{counter} files newer than restored backup")
      end
    end
  end
end
