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

  # c.desc '[DEPRECATED] Use alternative fuzzy matching for search string'
  # c.switch [:fuzzy], default_value: false, negatable: false

  c.desc 'Force exact string matching (case sensitive)'
  c.switch %i[x exact], default_value: Doing.config.exact_match?, negatable: Doing.config.exact_match?

  c.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
  c.arg_name 'TYPE'
  c.flag [:case], must_match: REGEX_CASE,
                  default_value: Doing.setting('search.case', :smart).normalize_case,
                  type: CaseSymbol

  c.desc "Highlight search matches in output. Only affects command line output"
  c.switch %i[h hilite], default_value: Doing.settings.dig('search', 'highlight')

  c.desc "Edit matching entries with #{Doing::Util.default_editor}"
  c.switch %i[e editor], negatable: false, default_value: false

  c.desc "Delete matching entries"
  c.switch %i[d delete], negatable: false, default_value: false

  c.desc 'Display an interactive menu of results to perform further operations'
  c.switch %i[i interactive], default_value: false, negatable: false

  add_options(:output_template, c)
  add_options(:tag_filter, c)
  add_options(:date_filter, c)
  add_options(:time_display, c)
  add_options(:save, c)

  c.action do |_global_options, options, args|
    options[:fuzzy] = false

    if options[:output] && options[:output] !~ Doing::Plugins.plugin_regex(type: :export)
      raise InvalidPlugin.new('output', options[:output])

    end

    template = Doing.setting(['templates', options[:config_template]]).deep_merge(Doing.settings)
    tags_color = template.key?('tags_color') ? template['tags_color'] : nil

    section = @wwid.guess_section(options[:section]) if options[:section]

    search = args.join(' ')
    search.sub!(/^'?/, "'") if options[:exact]

    options[:times] = true if options[:totals]
    options[:sort_tags] = options[:tag_sort]
    options[:highlight] = true
    options[:search] = search
    options[:section] = section
    options[:tags_color] = tags_color

    Doing::Pager.page @wwid.list_section(options)
    if options[:save]
      options[:before] = Doing.original_options[:date_begin] if Doing.original_options[:date_begin].good?
      options[:after] = Doing.original_options[:date_end] if Doing.original_options[:date_end].good?
      options[:from] = Doing.original_options[:date_range] if Doing.original_options[:date_range].good?
      Doing.config.save_view(options.to_view, options[:save].downcase)
   end
  end
end
