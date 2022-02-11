# frozen_string_literal: true

# @@cancel
desc 'End last X entries with no time tracked'
long_desc 'Adds @done tag without datestamp so no elapsed time is recorded.
           Alias for `doing finish --no-date`'
arg_name 'COUNT'
command :cancel do |c|
  c.example 'doing cancel', desc: 'Cancel the last entry'
  c.example 'doing cancel --tag project1 -u 5', desc: 'Cancel the last 5 unfinished entries containing @project1'

  c.desc 'Archive entries'
  c.switch %i[a archive], negatable: false, default_value: false

  c.desc 'Section'
  c.arg_name 'NAME'
  c.flag %i[s section]

  c.desc 'Cancel the last X entries containing TAG. Separate multiple tags with comma (--tag=tag1,tag2).
          Wildcards allowed (*, ?)'
  c.arg_name 'TAG'
  c.flag [:tag], type: TagArray

  c.desc 'Boolean (AND|OR|NOT) with which to combine multiple tag filters. Use PATTERN to parse + and - as booleans'
  c.arg_name 'BOOLEAN'
  c.flag [:bool], must_match: REGEX_BOOL,
                  default_value: :pattern,
                  type: BooleanSymbol

  c.desc 'Cancel the last X entries matching search filter, surround with slashes for regex (e.g. "/query.*/"),
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

  c.desc 'Finish items that *don\'t* match search/tag filters'
  c.switch [:not], default_value: false, negatable: false

  c.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
  c.arg_name 'TYPE'
  c.flag [:case], must_match: REGEX_CASE,
                  default_value: @settings.dig('search', 'case').normalize_case,
                  type: CaseSymbol

  c.desc 'Cancel last entry (or entries) not already marked @done'
  c.switch %i[u unfinished], negatable: false, default_value: false

  c.desc 'Select item(s) to cancel from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

  c.action do |_global_options, options, args|
    options[:fuzzy] = false
    options[:section] = if options[:section]
                          @wwid.guess_section(options[:section]) || options[:section].cap_first
                        else
                          @settings['current_section']
                        end

    raise InvalidArgument, 'Only one argument allowed' if args.length > 1

    unless args.empty? || args[0] =~ /\d+/
      raise InvalidArgument, 'Invalid argument (specify number of recent items to mark @done)'

    end

    options[:count] = if options[:interactive]
                        0
                      else
                        args[0] ? args[0].to_i : 1
                      end

    options[:search] = options[:search].sub(/^'?/, "'") if options[:search] && options[:exact]

    options[:case] = options[:case].normalize_case
    options[:date] = false
    options[:sequential] = false
    options[:tag] ||= []
    options[:tag_bool] = options[:bool].normalize_bool
    options[:tags] = ['done']

    @wwid.tag_last(options)
  end
end
