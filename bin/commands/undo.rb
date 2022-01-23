# @@undo
desc 'Undo the last X changes to the Doing file'
long_desc 'Reverts the last X commands that altered the doing file.
All changes performed by a single command are undone at once.

Specify a number to jump back multiple revisions, or use --select for an interactive menu.'
arg_name 'COUNT'
command :undo do |c|
  c.example 'doing undo', desc: 'Undo the most recent change to the doing file'
  c.example 'doing undo 5', desc: 'Undo the last 5 changes to the doing file'
  c.example 'doing undo --interactive', desc: 'Select from a menu of available revisions'
  c.example 'doing undo --redo', desc: 'Undo the last undo command'

  c.desc 'Specify alternate doing file'
  c.arg_name 'PATH'
  c.flag %i[f file], default_value: @wwid.doing_file

  c.desc 'Select from recent backups'
  c.switch %i[i interactive], negatable: false

  c.desc 'Remove old backups, retaining X files'
  c.arg_name 'COUNT'
  c.flag %i[p prune], type: Integer

  c.desc 'Redo last undo. Note: you cannot undo a redo'
  c.switch %i[r redo]

  c.action do |_global_options, options, args|
    file = options[:file] || @wwid.doing_file
    count = args.empty? ? 1 : args[0].to_i
    raise InvalidArgument, "Invalid count specified for undo" unless count&.positive?

    if options[:prune]
      Doing::Util::Backup.prune_backups(file, options[:prune])
    elsif options[:redo]
      if options[:interactive]
        Doing::Util::Backup.select_redo(file)
      else
        Doing::Util::Backup.redo_backup(file, count: count)
      end
    else
      if options[:interactive]
        Doing::Util::Backup.select_backup(file)
      else
        Doing::Util::Backup.restore_last_backup(file, count: count)
      end
    end
  end
end
