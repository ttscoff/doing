# frozen_string_literal: true

# @@commands
desc 'Enable and disable Doing commands'
command :commands do |c|
  c.example 'doing commands add', desc: 'Get a menu of available commands'
  c.example 'doing commands add COMMAND', desc: 'Specify a command to enable'
  c.example 'doing commands remove COMMAND', desc: 'Specify a command to disable'

  c.default_command :add

  # @@commands.enable
  c.desc 'Enable Doing commands'
  c.long_desc 'Run without arguments to select commands from a list.'
  c.arg_name 'COMMAND [COMMAND...]'
  c.command %i[add enable] do |add|
    add.action do |_global, _options, args|
      cfg = @settings
      custom_dir = @settings.dig('plugins', 'command_path')

      available = cfg['disabled_commands']
      raise UserCancelled, 'No commands available to enable' unless args.good? || available.good?

      to_enable = if args.good?
                    args
                  else
                    Doing::Prompt.choose_from(available,
                                              prompt: 'Select commands to enable',
                                              multiple: true,
                                              sorted: true).strip.split("\n")
                  end
      to_enable.each do |cmd|
        default_command = File.join(File.dirname(__FILE__), "#{cmd}.rb")
        custom_command = File.join(File.expand_path(custom_dir), "#{cmd}.rb")
        unless File.exist?(default_command) || File.exist?(custom_command)
          raise InvalidArgument, "Command #{cmd} not found"
        end

        raise InvalidArgument, "Command #{cmd} is not disabled" unless available.include?(cmd)

        available.delete(cmd)
      end

      cfg.deep_set(['disabled_commands'], available)

      Doing::Util.write_to_file(@config.config_file, YAML.dump(cfg), backup: true)
      Doing.logger.warn('Config:', "#{@config.config_file} updated")
    end
  end

  # @@commands.disable
  c.desc 'Disable Doing commands'
  c.command %i[remove disable] do |remove|
    remove.action do |_global, _options, args|
      available = Dir.glob(File.join(File.dirname(__FILE__), '*.rb')).map { |cmd| File.basename(cmd, '.rb') }
      cfg = @settings
      custom_dir = @settings.dig('plugins', 'command_path')
      custom_commands = Dir.glob(File.join(File.expand_path(custom_dir), '*.rb'))
      available.concat(custom_commands.map { |cmd| File.basename(cmd, '.rb') })
      disabled = cfg['disabled_commands']
      disabled.each { |cmd| available.delete(cmd) }
      to_disable = if args.good?
                     args
                   else
                     Doing::Prompt.choose_from(available,
                                               prompt: 'Select commands to enable',
                                               multiple: true,
                                               sorted: true).strip.split("\n")
                   end
      to_disable.each do |cmd|
        default_command = File.join(File.dirname(__FILE__), "#{cmd}.rb")
        custom_command = File.join(File.expand_path(custom_dir), "#{cmd}.rb")
        unless File.exist?(default_command) || File.exist?(custom_command)
          raise InvalidArgument, "Command #{cmd} not found"

        end

        raise InvalidArgument, "Command #{cmd} is not enabled" unless available.include?(cmd)
      end

      cfg.deep_set(['disabled_commands'], disabled.concat(to_disable))

      Doing::Util.write_to_file(@config.config_file, YAML.dump(cfg), backup: true)
      Doing.logger.warn('Config:', "#{@config.config_file} updated")
    end
  end
end
