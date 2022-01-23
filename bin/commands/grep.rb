# @@grep @@search
desc 'Search for entries'
long_desc %(
Search all sections (or limit to a single section) for entries matching text or regular expression. Normal strings are fuzzy matched.

To search with regular expressions, single quote the string and surround with slashes: `doing search '/\bm.*?x\b/'`
)
arg_name 'SEARCH_PATTERN'
command %i[grep search] do |c|
  c.example 'doing grep "doing wiki"', desc: 'Find entries containing "doing wiki" using fuzzy matching'
  c.example 'doing search "\'search command"', desc: 'Find entries containing "search command" using exact matching (search is an alias for grep)'
  c.example 'doing grep "/do.*?wiki.*?@done/"', desc: 'Find entries matching regular expression'
  c.example 'doing search --before 12/21 "doing wiki"', desc: 'Find entries containing "doing wiki" with entry dates before 12/21 of the current year'

  c.desc 'Section'
  c.arg_name 'NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc 'Search entries older than date. If this is only a time (8am, 1:30pm, 15:00), all dates will be included, but entries will be filtered by time of day'
  c.arg_name 'DATE_STRING'
  c.flag [:before], type: DateBeginString

  c.desc 'Search entries newer than date. If this is only a time (8am, 1:30pm, 15:00), all dates will be included, but entries will be filtered by time of day'
  c.arg_name 'DATE_STRING'
  c.flag [:after], type: DateEndString

  c.desc %(
      Date range to show, or a single day to filter date on.
      Date range argument should be quoted. Date specifications can be natural language.
      To specify a range, use "to" or "through": `doing search --from "monday 8am to friday 5pm"`.

      If values are only time(s) (6am to noon) all dates will be included, but entries will be filtered
      by time of day.
    )
  c.arg_name 'DATE_OR_RANGE'
  c.flag [:from], type: DateRangeString

  c.desc "Output to export format (#{Doing::Plugins.plugin_names(type: :export)})"
  c.arg_name 'FORMAT'
  c.flag %i[o output]

  c.desc "Output using a template from configuration"
  c.arg_name 'TEMPLATE_KEY'
  c.flag [:config_template], type: TemplateName, default_value: 'default'

  c.desc 'Override output format with a template string containing %placeholders'
  c.arg_name 'TEMPLATE_STRING'
  c.flag [:template]

  c.desc 'Show time intervals on @done tasks'
  c.switch %i[t times], default_value: true, negatable: true

  c.desc 'Show elapsed time on entries without @done tag'
  c.switch [:duration]

  c.desc 'Show intervals with totals at the end of output'
  c.switch [:totals], default_value: false, negatable: false

  c.desc 'Sort tags by (name|time)'
  default = 'time'
  default = @settings['tag_sort'] || 'name'
  c.arg_name 'KEY'
  c.flag [:tag_sort], must_match: /^(?:name|time)$/i, default_value: default

  c.desc 'Only show items with recorded time intervals'
  c.switch [:only_timed], default_value: false, negatable: false

  # c.desc '[DEPRECATED] Use alternative fuzzy matching for search string'
  # c.switch [:fuzzy], default_value: false, negatable: false

  c.desc 'Force exact string matching (case sensitive)'
  c.switch %i[x exact], default_value: @config.exact_match?, negatable: @config.exact_match?

  c.desc 'Show items that *don\'t* match search string'
  c.switch [:not], default_value: false, negatable: false

  c.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
  c.arg_name 'TYPE'
  c.flag [:case], must_match: /^[csi]/, default_value: @settings.dig('search', 'case')

  c.desc "Highlight search matches in output. Only affects command line output"
  c.switch %i[h hilite], default_value: @settings.dig('search', 'highlight')

  c.desc "Edit matching entries with #{Doing::Util.default_editor}"
  c.switch %i[e editor], negatable: false, default_value: false

  c.desc "Delete matching entries"
  c.switch %i[d delete], negatable: false, default_value: false

  c.desc 'Display an interactive menu of results to perform further operations'
  c.switch %i[i interactive], default_value: false, negatable: false

  c.desc 'Perform a tag value query ("@done > two hours ago" or "@progress < 50"). May be used multiple times, combined with --bool'
  c.arg_name 'QUERY'
  c.flag [:val], multiple: true, must_match: REGEX_VALUE_QUERY

  c.desc 'Combine multiple tags or value queries using AND, OR, or NOT'
  c.flag [:bool], must_match: REGEX_BOOL, default_value: 'AND'

  c.action do |_global_options, options, args|
    options[:fuzzy] = false
    raise DoingRuntimeError, %(Invalid output type "#{options[:output]}") if options[:output] && options[:output] !~ Doing::Plugins.plugin_regex(type: :export)

    template = @settings['templates'][options[:config_template]].deep_merge(@settings)
    tags_color = template.key?('tags_color') ? template['tags_color'] : nil

    section = @wwid.guess_section(options[:section]) if options[:section]

    options[:case] = options[:case].normalize_case
    options[:bool] = options[:bool].normalize_bool

    search = args.join(' ')
    search.sub!(/^'?/, "'") if options[:exact]

    options[:times] = true if options[:totals]
    options[:sort_tags] = options[:tag_sort] =~ /^n/i
    options[:highlight] = true
    options[:search] = search
    options[:section] = section
    options[:tags_color] = tags_color

    Doing::Pager.page @wwid.list_section(options)
  end
end
