# frozen_string_literal: true

# Example command that calls an existing command (tag) with
# preset options
desc 'Add an item to the Later section'
arg_name 'ENTRY'
command :later do |c|
  c.example 'doing later "Something I\'ll think about tomorrow"', desc: 'Add an entry to the Later section'
  c.example 'doing later -e', desc: 'Open $EDITOR to create an entry and optional note'

  c.desc "Edit entry with #{Doing::Util.default_editor}"
  c.switch %i[e editor], negatable: false, default_value: false

  c.desc 'Backdate start time to date string [4pm|20m|2h|yesterday noon]'
  c.arg_name 'DATE_STRING'
  c.flag %i[b back started], type: DateBeginString

  c.desc 'Note'
  c.arg_name 'TEXT'
  c.flag %i[n note]

  c.desc 'Prompt for note via multi-line input'
  c.switch %i[ask], negatable: false, default_value: false

  c.action do |global_options, options, args|
    cmd = commands[:now]
    options[:section] = 'Later'
    options[:finish_last] = false
    action = cmd.send(:get_action, nil)
    action.call(global_options, options, args)
  end
end
