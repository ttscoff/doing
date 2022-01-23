# @@select
desc 'Display an interactive menu to perform operations'
long_desc 'List all entries and select with typeahead fuzzy matching.

Multiple selections are allowed, hit tab to add the highlighted entry to the
selection, and use ctrl-a to select all visible items. Return processes the
selected entries.

Search in the menu by typing:

sbtrkt  fuzzy-match   Items that match s*b*t*r*k*t

\'wild   exact-match (quoted)  Items that include wild

!fire   inverse-exact-match   Items that do not include fire'
command :select do |c|
  c.example 'doing select', desc: 'Select from all entries. A menu of available actions will be presented after confirming the selection.'
  c.example 'doing select --editor', desc: 'Select entries from a menu and batch edit them in your default editor'
  c.example 'doing select --after "yesterday 12pm" --tag project1', desc: 'Display a menu of entries created after noon yesterday, add @project1 to selected entries'
  c.desc 'Select from a specific section'
  c.arg_name 'SECTION'
  c.flag %i[s section]

  c.desc 'Tag selected entries'
  c.arg_name 'TAG'
  c.flag %i[t tag]

  c.desc 'Reverse -c, -f, --flag, and -t (remove instead of adding)'
  c.switch %i[r remove], negatable: false

  # c.desc 'Add @done to selected item(s), using start time of next item as the finish time'
  # c.switch %i[a auto], negatable: false, default_value: false

  c.desc 'Archive selected items'
  c.switch %i[a archive], negatable: false, default_value: false

  c.desc 'Move selected items to section'
  c.arg_name 'SECTION'
  c.flag %i[m move]

  c.desc 'Initial search query for filtering. Matching is fuzzy. For exact matching, start query with a single quote, e.g. `--query "\'search"'
  c.arg_name 'QUERY'
  c.flag %i[q query]

  c.desc 'Select from entries matching search filter, surround with slashes for regex (e.g. "/query.*/"), start with single quote for exact match ("\'query")'
  c.arg_name 'QUERY'
  c.flag [:search]

  c.desc 'Perform a tag value query ("@done > two hours ago" or "@progress < 50"). May be used multiple times, combined with --bool'
  c.arg_name 'QUERY'
  c.flag [:val], multiple: true, must_match: REGEX_VALUE_QUERY

  c.desc 'Select from entries older than date. If this is only a time (8am, 1:30pm, 15:00), all dates will be included, but entries will be filtered by time of day'
  c.arg_name 'DATE_STRING'
  c.flag [:before], type: DateBeginString

  c.desc 'Select from entries newer than date. If this is only a time (8am, 1:30pm, 15:00), all dates will be included, but entries will be filtered by time of day'
  c.arg_name 'DATE_STRING'
  c.flag [:after], type: DateEndString

  c.desc %(
      Date range to show, or a single day to filter date on.
      Date range argument should be quoted. Date specifications can be natural language.
      To specify a range, use "to" or "through": `doing select --from "monday 8am to friday 5pm"`.

      If values are only time(s) (6am to noon) all dates will be included, but entries will be filtered
      by time of day.
    )
  c.arg_name 'DATE_OR_RANGE'
  c.flag [:from], type: DateRangeString

  c.desc 'Force exact search string matching (case sensitive)'
  c.switch %i[x exact], default_value: @config.exact_match?, negatable: @config.exact_match?

  c.desc 'Select items that *don\'t* match search/tag filters'
  c.switch [:not], default_value: false, negatable: false

  c.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
  c.arg_name 'TYPE'
  c.flag [:case], must_match: /^[csi]/, default_value: @settings.dig('search', 'case')

  c.desc 'Use --no-menu to skip the interactive menu. Use with --query to filter items and act on results automatically. Test with `--output doing` to preview matches'
  c.switch %i[menu], negatable: true, default_value: true

  c.desc 'Cancel selected items (add @done without timestamp)'
  c.switch %i[c cancel], negatable: false, default_value: false

  c.desc 'Delete selected items'
  c.switch %i[d delete], negatable: false, default_value: false

  c.desc 'Edit selected item(s)'
  c.switch %i[e editor], negatable: false, default_value: false

  c.desc 'Add @done with current time to selected item(s)'
  c.switch %i[f finish], negatable: false, default_value: false

  c.desc 'Add flag to selected item(s)'
  c.switch %i[flag], negatable: false, default_value: false

  c.desc 'Perform action without confirmation'
  c.switch %i[force], negatable: false, default_value: false

  c.desc 'Save selected entries to file using --output format'
  c.arg_name 'FILE'
  c.flag %i[save_to]

  c.desc "Output entries to format (#{Doing::Plugins.plugin_names(type: :export)})"
  c.arg_name 'FORMAT'
  c.flag %i[o output]

  c.desc "Copy selection as a new entry with current time and no @done tag. Only works with single selections. Can be combined with --editor."
  c.switch %i[again resume], negatable: false, default_value: false

  c.action do |_global_options, options, args|
    raise DoingRuntimeError, %(Invalid output type "#{options[:output]}") if options[:output] && options[:output] !~ Doing::Plugins.plugin_regex(type: :export)

    raise InvalidArgument, '--no-menu requires --query' if !options[:menu] && !options[:query]

    options[:case] = options[:case].normalize_case

    @wwid.interactive(options) # hooked
  end
end