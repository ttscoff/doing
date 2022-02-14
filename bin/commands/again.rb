# frozen_string_literal: true

# @@again @@resume
desc 'Repeat last entry as new entry'
long_desc 'This command is designed to allow multiple time intervals to be created
           for an entry by duplicating it with a new start (and end, eventually) time'
command %i[again resume] do |c|
  c.example 'doing resume',
            desc: 'Duplicate the most recent entry with a new start time, removing any @done tag'
  c.example 'doing again',
            desc: 'again is an alias for resume'
  c.example 'doing resume --editor',
            desc: 'Repeat the last entry, opening the new entry in the default editor'
  c.example 'doing resume --tag project1 --in Projects',
            desc: 'Repeat the last entry tagged @project1, creating the new entry in the Projects section'
  c.example 'doing resume --interactive', desc: 'Select the entry to repeat from a menu'

  c.desc 'Get last entry from a specific section'
  c.arg_name 'NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc 'Add new entry to section (default: same section as repeated entry)'
  c.arg_name 'SECTION_NAME'
  c.flag [:in]

  c.desc 'Select item to resume from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

  add_options(:add_entry, c)
  add_options(:search, c)
  add_options(:tag_filter, c)

  c.action do |_global_options, options, _args|
    options[:fuzzy] = false

    if options[:search]
      options[:search] = options[:exact] ? options[:search].sub(/^'?/, "'") : options[:search]
    end

    if options[:back]
      options[:date] = options[:back]
      raise InvalidTimeExpression, 'Unable to parse date string for --back' if date.nil?

    else
      options[:date] = Time.now
    end

    note = Doing::Note.new(options[:note])
    note.add(Doing::Prompt.read_lines(prompt: 'Add a note')) if options[:ask]

    options[:note] = note
    options[:tag] ||= []
    options[:tag_bool] = options[:bool]

    @wwid.repeat_last(options)
  end
end
