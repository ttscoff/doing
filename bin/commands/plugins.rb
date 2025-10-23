# frozen_string_literal: true

# @@plugins
desc 'List installed plugins'
long_desc %(Lists available plugins, including user-installed plugins.

Export plugins are available with the `--output` flag on commands that support it.

Import plugins are available using `doing import --type PLUGIN`.
)
command :plugins do |c|
  c.example 'doing plugins', desc: 'List all plugins'
  c.example 'doing plugins -t import', desc: 'List all import plugins'

  c.desc 'List plugins of type (import, export)'
  c.arg_name 'TYPE'
  c.flag %i[t type], must_match: /^(?:[iea].*)$/i, default_value: 'all'

  c.desc 'List in single column for completion'
  c.switch %i[c column], negatable: false, default_value: false

  c.action do |_global_options, options, _args|
    Doing::Plugins.list_plugins(options)
  end
end
