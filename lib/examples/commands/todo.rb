# frozen_string_literal: true

# @@todo
desc 'Add an item as a Todo'
long_desc 'Adds an item to a Todo section, and tags it with @todo'
arg_name 'ENTRY'
command :todo do |c|
  c.example 'doing todo "Something I\'ll think about tomorrow"', desc: 'Add an entry to the Todo section with tag @todo'
  c.example 'doing later -e', desc: 'Open $EDITOR to create an entry and optional note'

  c.desc "Edit entry with #{Doing::Util.default_editor}"
  c.switch %i[e editor], negatable: false, default_value: false

  c.desc 'Note'
  c.arg_name 'TEXT'
  c.flag %i[n note]

  c.desc 'Prompt for note via multi-line input'
  c.switch %i[ask], negatable: false, default_value: false

  c.action do |global_options, options, args|
    cmd = commands[:now]
    options[:section] = 'Todo'
    options[:finish_last] = false
    action = cmd.send(:get_action, nil)
    string = args.join(' ').add_tags('todo')
    action.call(global_options, options, [string])
  end
end
