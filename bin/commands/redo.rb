# @@redo
long_desc 'Shortcut for `doing undo -r`, reverses the last undo command. You cannot undo a redo'
arg_name 'COUNT'
command :redo do |c|
  c.desc 'Specify alternate doing file'
  c.arg_name 'PATH'
  c.flag %i[f file], default_value: @wwid.doing_file

  c.desc 'Select from an interactive menu'
  c.switch %i[i interactive]

  c.action do |_global, options, args|
    file = options[:file] || @wwid.doing_file
    count = args.empty? ? 1 : args[0].to_i
    raise InvalidArgument, "Invalid count specified for redo" unless count&.positive?
    if options[:interactive]
      Doing::Util::Backup.select_redo(file)
    else
      Doing::Util::Backup.redo_backup(file, count: count)
    end
  end
end
