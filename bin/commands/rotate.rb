# @@rotate
desc 'Move entries to archive file'
long_desc 'As your doing file grows, commands can get slow. Given that your historical data (and your archive section)
probably aren\'t providing any useful insights a year later, use this command to "rotate" old entries out to an archive
file. You\'ll still have access to all historical data, but it won\'t be slowing down daily operation.'
command :rotate do |c|
  c.example 'doing rotate', desc: 'Move all entries in doing file to a dated secondary file'
  c.example 'doing rotate --section Archive --keep 10', desc: 'Move entries in the Archive section to a secondary file, keeping the most recent 10 entries'
  c.example 'doing rotate --tag project1,done --bool AND', desc: 'Move entries tagged @project1 and @done to a secondary file'

  c.desc 'How many items to keep in each section (most recent)'
  c.arg_name 'X'
  c.flag %i[k keep], must_match: /^\d+$/, type: Integer

  c.desc 'Section to rotate'
  c.arg_name 'SECTION_NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc 'Tag filter, combine multiple tags with a comma. Wildcards allowed (*, ?). Added for compatibility with other commands'
  c.arg_name 'TAG'
  c.flag [:tag]

  c.desc 'Tag boolean (AND|OR|NOT). Use PATTERN to parse + and - as booleans'
  c.arg_name 'BOOLEAN'
  c.flag [:bool], must_match: REGEX_BOOL, default_value: 'PATTERN'

  c.desc 'Search filter'
  c.arg_name 'QUERY'
  c.flag [:search]

  c.desc 'Perform a tag value query ("@done > two hours ago" or "@progress < 50"). May be used multiple times, combined with --bool'
  c.arg_name 'QUERY'
  c.flag [:val], multiple: true, must_match: REGEX_VALUE_QUERY

  # c.desc '[DEPRECATED] Use alternative fuzzy matching for search string'
  # c.switch [:fuzzy], default_value: false, negatable: false

  c.desc 'Force exact search string matching (case sensitive)'
  c.switch %i[x exact], default_value: @config.exact_match?, negatable: @config.exact_match?

  c.desc 'Rotate items that *don\'t* match search string or tag filter'
  c.switch [:not], default_value: false, negatable: false

  c.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
  c.arg_name 'TYPE'
  c.flag [:case], must_match: /^[csi]/, default_value: @settings.dig('search', 'case')

  c.desc 'Rotate entries older than date
    (Flexible date format, e.g. 1/27/2021, 2020-07-19, or Monday 3pm)'
  c.arg_name 'DATE_STRING'
  c.flag [:before]

  c.action do |_global_options, options, args|
    options[:fuzzy] = false
    if options[:section] && options[:section] !~ /^all$/i
      options[:section] = @wwid.guess_section(options[:section])
    end

    options[:bool] = options[:bool].normalize_bool

    options[:case] = options[:case].normalize_case

    search = nil

    if options[:search]
      search = options[:search]
      search.sub!(/^'?/, "'") if options[:exact]
      options[:search] = search
    end

    @wwid.rotate(options)
  end
end
