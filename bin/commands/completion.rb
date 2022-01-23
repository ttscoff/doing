# @@completion
desc 'Generate shell completion scripts'
long_desc 'Generates the necessary scripts to add command line completion to various shells, so typing \'doing\' and hitting
tab will offer completions of subcommands and their options.'
command :completion do |c|
  c.example 'doing completion', desc: 'Output zsh (default) to STDOUT'
  c.example 'doing completion --type zsh --file ~/.zsh-completions/_doing.zsh', desc: 'Output zsh completions to file'
  c.example 'doing completion --type fish --file ~/.config/fish/completions/doing.fish', desc: 'Output fish completions to file'
  c.example 'doing completion --type bash --file ~/.bash_it/completion/enabled/doing.bash', desc: 'Output bash completions to file'

  c.desc 'Shell to generate for (bash, zsh, fish)'
  c.arg_name 'SHELL'
  c.flag %i[t type], must_match: /^(?:[bzf](?:[ai]?sh)?|all)$/i, default_value: 'zsh'

  c.desc 'File to write output to'
  c.arg_name 'PATH'
  c.flag %i[f file], default_value: 'STDOUT'

  c.action do |_global_options, options, _args|
    script_dir = File.join(File.dirname(__FILE__), '..', 'scripts')

    Doing::Completion.generate_completion(type: options[:type], file: options[:file])
  end
end
