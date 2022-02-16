# frozen_string_literal: true

SHELLS = %w[zsh bash fish all].freeze
SHELL_RX = /^(?:[bzf](?:[ai]?sh)?|all)$/i.freeze

# @@completion
desc 'Generate shell completion scripts for doing'
long_desc 'Generates the necessary scripts to add command line completion to various shells,
so typing \'doing\' and hitting tab will offer completions of subcommands and their options.'
command :completion do |c|
  c.example 'doing completion install zsh',
            desc: 'Install the default zsh completion script and link it to the zsh autolaod directory.'
  c.example 'doing completion generate zsh', desc: 'Generate zsh (default) script to default file, offer to symlink'
  c.example 'doing completion generate fish --file ~/doing.fish',
            desc: 'Generate fish completions to alternative file'

  c.desc 'Deprecated, specify shell as argument to subcommand'
  c.flag %i[t type], must_match: SHELL_RX

  c.desc 'Generate completion scripts, including custom plugins and command options'
  c.long_desc "Argument specifies which shell to install for: #{SHELLS.join(', ')}"
  c.arg_name "[#{SHELLS.join('|')}]"
  c.command :generate do |gen|
    gen.example 'doing completion generate fish', desc: 'Generate fish completion script and link to autoload directory'
    gen.example 'doing completion generate zsh --file ~/.zsh-completions/doing.zsh', desc: 'Generate zsh completion script and save to alternative file'

    gen.desc 'Alternative file to write output to'
    gen.arg_name 'PATH'
    gen.flag %i[f file]

    gen.desc 'Output result to STDOUT only'
    gen.switch [:stdout], negatable: false

    gen.action do |_global_options, options, args|
      args = [options[:type]] if options[:type] && args.count.zero?

      raise MissingArgument, "Specify a shell (#{SHELLS.join('|')})" unless args.count.positive?

      file = options[:stdout] ? 'stdout' : options[:file] || :default

      raise InvalidArgument, '--file can not be used with multiple arguments' if options[:file] && args.count > 1

      args.each do |shell|
        type = Doing::Completion.normalize_type(shell)
        raise InvalidArgument, "Unknown shell #{shell}" if type == :invalid

        Doing::Completion.generate_completion(type: type, file: file)
      end
    end
  end

  c.desc 'Install default completion scripts'
  c.long_desc 'Argument specifies which shell to install for: zsh, bash, fish, or all'
  c.arg_name '[zsh|bash|fish]'
  c.command :install do |install|
    install.example 'doing completion install zsh', desc: 'Install and link zsh completion script'

    # install.flag %i[t type], must_match: /^(?:[bzf](?:[ai]?sh)?|all)$/i

    install.action do |_global_options, options, args|
      type = options[:type] || args[0]&.strip || 'zsh'
      raise InvalidArgument, "Unknown shell #{type}" unless type =~ SHELL_RX

      Doing::Completion.link_default(type)
    end
  end

  c.default_command :generate
end
