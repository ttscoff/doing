# @@open
desc 'Open the "doing" file in an editor'
long_desc "`doing open` defaults to using the editors.doing_file setting
in #{Doing.config.config_file} (#{Doing::Util.find_default_editor('doing_file')})."
command :open do |c|
  c.example 'doing open', desc: 'Open the doing file in the default editor'
  c.desc 'Open with editor command (e.g. vim, mate)'
  c.arg_name 'COMMAND'
  c.flag %i[e editor]

  if Sys::Platform.mac?
    c.desc 'Open with app name'
    c.arg_name 'APP_NAME'
    c.flag %i[a app]

    c.desc 'Open with app bundle id'
    c.arg_name 'BUNDLE_ID'
    c.flag %i[b bundle_id]
  end

  c.action do |_global_options, options, _args|
    params = options.clone
    params.delete_if do |k, v|
      k.instance_of?(String) || v.nil? || v == false
    end

    if options[:editor]
      raise MissingEditor, "Editor #{options[:editor]} not found" unless Doing::Util.exec_available(options[:editor].split(/ /).first)

      editor = TTY::Which.which(options[:editor])
      system %(#{editor} "#{File.expand_path(@wwid.doing_file)}")
    elsif Sys::Platform.mac?
      if options[:app]
        system %(open -a "#{options[:app]}" "#{File.expand_path(@wwid.doing_file)}")
      elsif options[:bundle_id]
        system %(open -b "#{options[:bundle_id]}" "#{File.expand_path(@wwid.doing_file)}")
      elsif Doing::Util.find_default_editor('doing_file')
        editor = Doing::Util.find_default_editor('doing_file')
        if Doing::Util.exec_available(editor.split(/ /).first)
          system %(#{editor} "#{File.expand_path(@wwid.doing_file)}")
        else
          system %(open -a "#{editor}" "#{File.expand_path(@wwid.doing_file)}")
        end
      else
        system %(open "#{File.expand_path(@wwid.doing_file)}")
      end
    else
      raise MissingEditor, 'No EDITOR variable defined in environment' if Doing::Util.default_editor.nil?

      system %(#{Doing::Util.default_editor} "#{File.expand_path(@wwid.doing_file)}")
    end
  end
end
