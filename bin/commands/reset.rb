# @@reset @@begin
desc 'Reset the start time of an entry'
long_desc 'Update the start time of the last entry or the last entry matching a tag/search filter.
If no argument is provided, the start time will be reset to the current time.
If a date string is provided as an argument, the start time will be set to the parsed result.'
arg_name 'DATE_STRING', optional: true
command %i[reset begin] do |c|
  c.example 'doing reset', desc: 'Reset the start time of the last entry to the current time'
  c.example 'doing reset --tag project1', desc: 'Reset the start time of the most recent entry tagged @project1 to the current time'
  c.example 'doing reset 3pm', desc: 'Reset the start time of the last entry to 3pm of the current day'
  c.example 'doing begin --tag todo --resume', desc: 'alias for reset. Updates the last @todo entry to the current time, removing @done tag.'

  c.desc 'Limit search to section'
  c.arg_name 'NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc 'Resume entry (remove @done)'
  c.switch %i[r resume], default_value: true

  c.desc 'Change start date but do not remove @done (shortcut for --no-resume)'
  c.switch [:n]

  c.desc 'Reset last entry matching tag. Wildcards allowed (*, ?)'
  c.arg_name 'TAG'
  c.flag [:tag]

  c.desc 'Reset last entry matching search filter, surround with slashes for regex (e.g. "/query.*/"),
          start with single quote for exact match ("\'query")'
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

  c.desc 'Reset items that *don\'t* match search/tag filters'
  c.switch [:not], default_value: false, negatable: false

  c.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
  c.arg_name 'TYPE'
  c.flag [:case], must_match: REGEX_CASE,
                  default_value: @settings.dig('search', 'case').normalize_case,
                  type: CaseSymbol

  c.desc 'Boolean (AND|OR|NOT) with which to combine multiple tag filters. Use PATTERN to parse + and - as booleans'
  c.arg_name 'BOOLEAN'
  c.flag [:bool], must_match: REGEX_BOOL,
                  default_value: :pattern,
                  type: BooleanSymbol

  c.desc 'Select from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

  c.action do |global_options, options, args|
    if args.count.positive?
      reset_date = args.join(' ').chronify(guess: :begin)
      raise InvalidArgument, 'Invalid date string' unless reset_date

    else
      reset_date = Time.now
    end

    options[:fuzzy] = false

    options[:section] = @wwid.guess_section(options[:section]) || options[:section].cap_first if options[:section]

    if options[:search]
      search = options[:search]
      search.sub!(/^'?/, "'") if options[:exact]
      options[:search] = search
    end

    items = @wwid.filter_items([], opt: options)

    last_entry = if options[:interactive]
                   Doing::Prompt.choose_from_items(items, include_section: options[:section].nil?,
                                                          menu: true,
                                                          header: '',
                                                          prompt: 'Select an entry to start/reset > ',
                                                          multiple: false,
                                                          sort: false,
                                                          show_if_single: true)
                 else
                   items.reverse.last
                 end


    raise NoResults, 'No entry matching parameters was found.' unless last_entry

    old_item = last_entry.clone

    @wwid.reset_item(last_entry, date: reset_date, resume: options[:resume])
    Doing::Hooks.trigger :post_entry_updated, @wwid, last_entry, old_item
    # new_entry = Doing::Item.new(last_entry.date, last_entry.title, last_entry.section, new_note)

    @wwid.write(@wwid.doing_file)
  end
end
