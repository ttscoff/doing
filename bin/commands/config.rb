# @@config
desc 'Edit the configuration file or output a value from it'
long_desc %(Run without arguments, `doing config` opens your `config.yml` in an editor.
If local configurations are found in the path between the current directory
and the root (/), a menu will allow you to select which to open in the editor.

It will use the editor defined in `config_editor_app`, or one specified with `--editor`.

Use `doing config get` to output the configuration to the terminal, and
provide a dot-separated key path to get a specific value. Shows the current value
including keys/overrides set by local configs.)
command :config do |c|
  c.example 'doing config', desc: "Open an active configuration in #{Doing::Util.find_default_editor('config')}"
  c.example 'doing config get doing_file', desc: 'Output the value of a config key as YAML'
  c.example 'doing config get plugins.plugin_path -o json', desc: 'Output the value of a key path as JSON'
  c.example 'doing config set plugins.say.say_voice Alex', desc: 'Set the value of a key path and update config file'
  c.example 'doing config set plug.say.voice Zarvox', desc: 'Key paths for get and set are fuzzy matched'

  c.default_command :edit

  c.desc 'DEPRECATED'
  c.switch %i[d dump]

  c.desc 'DEPRECATED'
  c.switch %i[u update]

  # @@config.list
  c.desc 'List configuration paths, including .doingrc files in the current and parent directories'
  c.long_desc 'Config files are listed in order of precedence (if there are multiple configs detected).
  Values defined in the top item in the list will override values in configutations below it.'
  c.command :list do |list|
    list.action do |global, options, args|
      puts @config.additional_configs.join("\n")
      puts @config.config_file
    end
  end

  # @@config.edit
  c.desc 'Open config file in editor'
  c.command :edit do |edit|
    edit.example 'doing config edit', desc: 'Open a config file in the default editor'
    edit.example 'doing config edit --editor vim', desc: 'Open config in specific editor'

    edit.desc 'Editor to use'
    edit.arg_name 'EDITOR'
    edit.flag %i[e editor], default_value: nil

    if `uname` =~ /Darwin/
      edit.desc 'Application to use'
      edit.arg_name 'APP_NAME'
      edit.flag %i[a app]

      edit.desc 'Application bundle id to use'
      edit.arg_name 'BUNDLE_ID'
      edit.flag %i[b bundle_id]

      edit.desc "Use the config_editor_app defined in ~/.config/doing/config.yml (#{@settings.key?('config_editor_app') ? @settings['config_editor_app'] : 'config_editor_app not set'})"
      edit.switch %i[x default]
    end

    edit.action do |global, options, args|
      if options[:update] || options[:dump]
        cmd = commands[:config]
        if options[:update]
          cmd = cmd.commands[:update]
        elsif options[:dump]
          cmd = cmd.commands[:get]
        end
        action = cmd.send(:get_action, nil)
        action.call(global, options, args)
        Doing.logger.warn('Deprecated:', '--dump and --update are deprecated,
                             use `doing config get` and `doing config update`')
        Doing.logger.output_results
        return
      end

      config_file = @config.choose_config

      if `uname` =~ /Darwin/
        if options[:default]
          editor = Doing::Util.find_default_editor('config')
          if editor
            if Doing::Util.exec_available(editor.split(/ /).first)
              system %(#{editor} "#{config_file}")
            else
              `open -a "#{editor}" "#{config_file}"`
            end
          else
            raise InvalidArgument, 'No viable editor found in config or environment.'
          end
        elsif options[:app] || options[:bundle_id]
          if options[:app]
            `open -a "#{options[:app]}" "#{config_file}"`
          elsif options[:bundle_id]
            `open -b #{options[:bundle_id]} "#{config_file}"`
          end
        else
          editor = options[:editor] || Doing::Util.find_default_editor('config')

          raise MissingEditor, 'No viable editor defined in config or environment' unless editor

          if Doing::Util.exec_available(editor.split(/ /).first)
            system %(#{editor} "#{config_file}")
          else
            `open -a "#{editor}" "#{config_file}"`
          end
        end
      else
        editor = options[:editor] || Doing::Util.default_editor
        raise MissingEditor, 'No EDITOR variable defined in environment' unless editor && Doing::Util.exec_available(editor.split(/ /).first)

        system %(#{editor} "#{config_file}")
      end
    end
  end

  # @@config.update @@config.refresh
  c.desc 'Update default config file, adding any missing keys'
  c.command %i[update refresh] do |update|
    update.action do |_global, options, args|
      @config.configure({rewrite: true, ignore_local: true})
      Doing.logger.warn('Config:', 'config refreshed')
    end
  end

  # @@config.undo
  c.desc 'Undo the last change to a config file'
  c.command :undo do |undo|
    undo.action do |_global, options, args|
      config_file = @config.choose_config
      Doing::Util::Backup.restore_last_backup(config_file, count: 1)
    end
  end

  # @@config.get @@config.dump
  c.desc 'Output a key\'s value'
  c.arg 'KEY_PATH'
  c.command %i[get dump] do |dump|
    dump.example 'doing config get', desc: 'Output the entire configuration'
    dump.example 'doing config get timer_format --output raw', desc: 'Output the value of timer_format as a plain string'
    dump.example 'doing config get doing_file', desc: 'Output the value of the doing_file setting, respecting local configurations'
    dump.example 'doing config get -o json plug.plugpath', desc: 'Key path is fuzzy matched: output the value of plugins->plugin_path as JSON'

    dump.desc 'Format for output (json|yaml|raw)'
    dump.arg_name 'FORMAT'
    dump.flag %i[o output], default_value: 'yaml', must_match: /^(?:y(?:aml)?|j(?:son)?|r(?:aw)?)$/

    dump.action do |_global, options, args|

      keypath = args.join('.')
      cfg = @config.value_for_key(keypath)
      real_path = @config.resolve_key_path(keypath)

      if cfg
        val = cfg.map {|k, v| v }[0]
        if real_path.count.positive?
          nested_cfg = {}
          nested_cfg.deep_set(real_path, val)
        else
          nested_cfg = val
        end

        if options[:output] =~ /^r/
          if val.is_a?(Hash)
            $stdout.puts YAML.dump(val)
          elsif val.is_a?(Array)
            $stdout.puts val.join(', ')
          else
            $stdout.puts val.to_s
          end
        else
          $stdout.puts case options[:output]
                       when /^j/
                         JSON.pretty_generate(val)
                       else
                         YAML.dump(nested_cfg)
                       end
        end
      else
        Doing.logger.log_now(:error, 'Config:', "Key #{keypath} not found")
      end
      Doing.logger.output_results
    end
  end

  # @@config.set
  c.desc 'Set a key\'s value in the config file'
  c.arg 'KEY VALUE'
  c.command :set do |set|
    set.example 'doing config set timer_format human', desc: 'Set the value of timer_format to "human"'
    set.example 'doing config set plug.plugpath ~/my_plugins', desc: 'Key path is fuzzy matched: set the value of plugins->plugin_path'

    set.desc 'Delete specified key'
    set.switch %i[r remove], default_value: false, negatable: false

    set.action do |_global, options, args|
      if args.count < 2 && !options[:remove]
        raise InvalidArgument, 'config set requires at least two arguments, key path and value'

      end

      value = options[:remove] ? nil : args.pop
      keypath = args.join('.')
      real_path = @config.resolve_key_path(keypath, create: true)
      old_value = @settings.dig(*real_path)
      old_type = old_value&.class.to_s || nil

      if old_value.is_a?(Hash) && !options[:remove]
        Doing.logger.log_now(:warn, 'Config:', "Config key must point to a single value, #{real_path.join('->').boldwhite} is a mapping")
        didyou = 'Did you mean:'
        old_value.keys.each do |k|
          Doing.logger.log_now(:warn, "#{didyou}", "#{keypath}.#{k}?")
          didyou = '..........or:'
        end
        raise InvalidArgument, 'Config value is a mapping, can not be set to a single value'

      end

      config_file = @config.choose_config(create: true)

      cfg = Doing::Util.safe_load_file(config_file) || {}

      $stderr.puts "Updating #{config_file}".yellow

      if options[:remove]
        cfg.deep_set(real_path, nil)
        $stderr.puts "#{'Deleting key:'.yellow} #{real_path.join('->').boldwhite}"
      else
        current_value = cfg.dig(*real_path)
        cfg.deep_set(real_path, value.set_type(old_type))
        $stderr.puts "#{' Key path:'.yellow} #{real_path.join('->').boldwhite}"
        $stderr.puts "#{'Inherited:'.yellow} #{(old_value ? old_value.to_s : 'empty').boldwhite}"
        $stderr.puts "#{'  Current:'.yellow} #{ (current_value ? current_value.to_s : 'empty').boldwhite }"
        $stderr.puts "#{'      New:'.yellow} #{value.set_type(old_type).to_s.boldwhite}"
      end

      res = Doing::Prompt.yn('Update selected config', default_response: true)

      raise UserCancelled, 'Cancelled' unless res

      Doing::Util.write_to_file(config_file, YAML.dump(cfg), backup: true)
      Doing.logger.warn('Config:', "#{config_file} updated")
    end
  end
end
