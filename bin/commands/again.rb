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

  c.desc 'Backdate start date by interval or set to time [4pm|20m|2h|"yesterday noon"]'
  c.arg_name 'DATE_STRING'
  c.flag %i[b back started], type: DateBeginString

  c.desc 'Repeat last entry matching tags. Combine multiple tags with a comma. Wildcards allowed (*, ?)'
  c.arg_name 'TAG'
  c.flag [:tag], type: TagArray

  c.desc 'Repeat last entry matching search. Surround with
  slashes for regex (e.g. "/query/"), start with a single quote for exact match ("\'query").'
  c.arg_name 'QUERY'
  c.flag [:search]

  c.desc 'Perform a tag value query ("@done > two hours ago" or "@progress < 50").
          May be used multiple times, combined with --bool'
  c.arg_name 'QUERY'
  c.flag [:val], multiple: true, must_match: REGEX_VALUE_QUERY

  # c.desc '[DEPRECATED] Use alternative fuzzy matching for search string'
  # c.switch [:fuzzy], default_value: false, negatable: false

  c.desc 'Force exact search string matching (case sensitive)'
  c.switch %i[x exact], default_value: @config.exact_match?, negatable: @config.exact_match?

  c.desc 'Resume items that *don\'t* match search/tag filters'
  c.switch [:not], default_value: false, negatable: false

  c.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
  c.arg_name 'TYPE'
  c.flag [:case], must_match: REGEX_CASE,
                  default_value: @settings.dig('search', 'case').normalize_case,
                  type: CaseSymbol

  c.desc 'Boolean used to combine multiple tags. Use PATTERN to parse + and - as booleans'
  c.arg_name 'BOOLEAN'
  c.flag [:bool], must_match: REGEX_BOOL,
                  default_value: :pattern,
                  type: BooleanSymbol

  c.desc "Edit duplicated entry with #{Doing::Util.default_editor} before adding"
  c.switch %i[e editor], negatable: false, default_value: false

  c.desc 'Add a note'
  c.arg_name 'TEXT'
  c.flag %i[n note]

  c.desc 'Prompt for note via multi-line input'
  c.switch %i[ask], negatable: false, default_value: false

  c.desc 'Select item to resume from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

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

    puts options[:case]
   # @wwid.repeat_last(options)
  end
end
