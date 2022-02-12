# @@finish
desc 'Mark last X entries as @done'
long_desc 'Marks the last X entries with a @done tag and current date. Does not alter already completed entries.'
arg_name 'COUNT', optional: true
command :finish do |c|
  c.example 'doing finish', desc: 'Mark the last entry @done'
  c.example 'doing finish --auto --section Later 10', desc: 'Add @done to any unfinished entries in the last 10 in Later, setting the finish time based on the start time of the task after it'
  c.example 'doing finish --search "a specific entry" --at "yesterday 3pm"', desc: 'Search for an entry containing string and set its @done time to yesterday at 3pm'

  c.desc 'Include date'
  c.switch [:date], negatable: true, default_value: true

  c.desc 'Backdate completed date to date string [4pm|20m|2h|yesterday noon]'
  c.arg_name 'DATE_STRING'
  c.flag %i[b back started], type: DateBeginString

  c.desc 'Set the completed date to the start date plus XX[hmd]'
  c.arg_name 'INTERVAL'
  c.flag %i[t took for], type: DateIntervalString

  c.desc %(Set finish date to specific date/time (natural langauge parsed, e.g. --at=1:30pm). If used, ignores --back.)
  c.arg_name 'DATE_STRING'
  c.flag %i[at finished], type: DateEndString

  c.desc 'Finish the last X entries containing TAG.
  Separate multiple tags with comma (--tag=tag1,tag2), combine with --bool. Wildcards allowed (*, ?).'
  c.arg_name 'TAG'
  c.flag [:tag], type: TagArray

  c.desc 'Finish the last X entries matching search filter, surround with slashes for regex (e.g. "/query.*/"), start with single quote for exact match ("\'query")'
  c.arg_name 'QUERY'
  c.flag [:search]

  c.desc 'Perform a tag value query ("@done > two hours ago" or "@progress < 50"). May be used multiple times, combined with --bool'
  c.arg_name 'QUERY'
  c.flag [:val], multiple: true, must_match: REGEX_VALUE_QUERY

  # c.desc '[DEPRECATED] Use alternative fuzzy matching for search string'
  # c.switch [:fuzzy], default_value: false, negatable: false

  c.desc 'Force exact search string matching (case sensitive)'
  c.switch %i[x exact], default_value: @config.exact_match?, negatable: @config.exact_match?

  c.desc 'Finish items that *don\'t* match search/tag filters'
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

  c.desc 'Overwrite existing @done tag with new date'
  c.switch %i[update], negatable: false, default_value: false

  c.desc 'Remove @done tag'
  c.switch %i[r remove], negatable: false, default_value: false

  c.desc 'Finish last entry (or entries) not already marked @done'
  c.switch %i[u unfinished], negatable: false, default_value: false

  c.desc %(Auto-generate finish dates from next entry's start time.
  Automatically generate completion dates 1 minute before next item (in any section) began.
  --auto overrides the --date and --back parameters.)
  c.switch [:auto], negatable: false, default_value: false

  c.desc 'Archive entries'
  c.switch %i[a archive], negatable: false, default_value: false

  c.desc 'Section'
  c.arg_name 'NAME'
  c.flag %i[s section]

  c.desc 'Select item(s) to finish from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

  c.action do |_global_options, options, args|
    options[:fuzzy] = false
    unless options[:auto]
      if options[:took]
        took = options[:took]
        raise InvalidTimeExpression, 'Unable to parse date string for --took' if took.nil?
      end

      raise InvalidArgument, '--back and --took can not be used together' if options[:back] && options[:took]

      raise InvalidArgument, '--search and --tag can not be used together' if options[:search] && options[:tag]

      if options[:at]
        finish_date = options[:at]
        finish_date = finish_date.chronify(guess: :begin) if finish_date.is_a? String
        raise InvalidTimeExpression, 'Unable to parse date string for --at' if finish_date.nil?

        date = options[:took] ? finish_date - took : finish_date
      elsif options[:back]
        date = options[:back]

        raise InvalidTimeExpression, 'Unable to parse date string' if date.nil?
      else
        date = Time.now
      end
    end

    if options[:tag].nil?
      tags = []
    else
      tags = options[:tag]
    end

    raise InvalidArgument, 'Only one argument allowed' if args.length > 1

    raise InvalidArgument, 'Invalid argument (specify number of recent items to mark @done)' unless args.length == 0 || args[0] =~ /\d+/

    if options[:interactive]
      count = 0
    else
      count = args[0] ? args[0].to_i : 1
    end

    search = nil

    if options[:search]
      search = options[:search]
      search.sub!(/^'?/, "'") if options[:exact]
    end

    opts = {
      archive: options[:archive],
      back: date,
      case: options[:case].normalize_case,
      count: count,
      date: options[:date],
      fuzzy: options[:fuzzy],
      interactive: options[:interactive],
      not: options[:not],
      remove: options[:remove],
      search: search,
      section: options[:section],
      sequential: options[:auto],
      tag: tags,
      tag_bool: options[:bool].normalize_bool,
      tags: ['done'],
      took: options[:took],
      unfinished: options[:unfinished],
      update: options[:update],
      val: options[:val]
    }

    @wwid.tag_last(opts)
  end
end
