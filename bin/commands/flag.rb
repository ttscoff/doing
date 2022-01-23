# @@mark @@flag
desc 'Mark last entry as flagged'
command %i[mark flag] do |c|
  c.example 'doing flag', desc: 'Add @flagged to the last entry created'
  c.example 'doing mark', desc: 'mark is an alias for flag'
  c.example 'doing flag --tag project1 --count 2', desc: 'Add @flagged to the last 2 entries tagged @project1'
  c.example 'doing flag --interactive --search "/(develop|cod)ing/"', desc: 'Find entries matching regular expression and create a menu allowing multiple selections, selected items will be @flagged'

  c.desc 'Section'
  c.arg_name 'SECTION_NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc 'How many recent entries to tag (0 for all)'
  c.arg_name 'COUNT'
  c.flag %i[c count], default_value: 1, must_match: /^\d+$/, type: Integer

  c.desc 'Don\'t ask permission to flag all entries when count is 0'
  c.switch %i[force], negatable: false, default_value: false

  c.desc 'Include current date/time with tag'
  c.switch %i[d date], negatable: false, default_value: false

  c.desc 'Remove flag'
  c.switch %i[r remove], negatable: false, default_value: false

  c.desc 'Flag last entry (or entries) not marked @done'
  c.switch %i[u unfinished], negatable: false, default_value: false

  c.desc 'Flag the last entry containing TAG.
  Separate multiple tags with comma (--tag=tag1,tag2), combine with --bool. Wildcards allowed (*, ?).'
  c.arg_name 'TAG'
  c.flag [:tag], type: TagArray

  c.desc 'Flag the last entry matching search filter, surround with slashes for regex (e.g. "/query.*/"), start with single quote for exact match ("\'query")'
  c.arg_name 'QUERY'
  c.flag [:search]

  c.desc 'Perform a tag value query ("@done > two hours ago" or "@progress < 50"). May be used multiple times, combined with --bool'
  c.arg_name 'QUERY'
  c.flag [:val], multiple: true, must_match: REGEX_VALUE_QUERY

  # c.desc '[DEPRECATED] Use alternative fuzzy matching for search string'
  # c.switch [:fuzzy], default_value: false, negatable: false

  c.desc 'Force exact search string matching (case sensitive)'
  c.switch %i[x exact], default_value: @config.exact_match?, negatable: @config.exact_match?

  c.desc 'Flag items that *don\'t* match search/tag/date filters'
  c.switch [:not], default_value: false, negatable: false

  c.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
  c.arg_name 'TYPE'
  c.flag [:case], must_match: /^[csi]/, default_value: @settings.dig('search', 'case')

  c.desc 'Boolean (AND|OR|NOT) with which to combine multiple tag filters. Use PATTERN to parse + and - as booleans'
  c.arg_name 'BOOLEAN'
  c.flag [:bool], must_match: REGEX_BOOL, default_value: 'PATTERN'

  c.desc 'Select item(s) to flag from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

  c.action do |_global_options, options, _args|
    options[:fuzzy] = false
    mark = @settings['marker_tag'] || 'flagged'

    raise InvalidArgument, '--search and --tag can not be used together' if options[:search] && options[:tag]

    section = 'All'

    if options[:section]
      section = @wwid.guess_section(options[:section]) || options[:section].cap_first
    end

    if options[:tag].nil?
      search_tags = []
    else
      search_tags = options[:tag]
    end

    if options[:interactive]
      count = 0
      options[:force] = true
    else
      count = options[:count].to_i
    end

    options[:case] = options[:case].normalize_case

    if options[:search]
      search = options[:search]
      search.sub!(/^'?/, "'") if options[:exact]
      options[:search] = search
    end

    if count.zero? && !options[:force]
      if options[:search]
        section_q = ' matching your search terms'
      elsif options[:tag]
        section_q = ' matching your tag search'
      elsif section == 'All'
        section_q = ''
      else
        section_q = " in section #{section}"
      end


      question = if options[:remove]
                   "Are you sure you want to unflag all entries#{section_q}"
                 else
                   "Are you sure you want to flag all records#{section_q}"
                 end

      res = Doing::Prompt.yn(question, default_response: false)

      exit_now! 'Cancelled' unless res
    end

    options[:count] = count
    options[:section] = section
    options[:tag] = search_tags
    options[:tags] = [mark]
    options[:tag_bool] = options[:bool].normalize_bool

    @wwid.tag_last(options)
  end
end
