# @@tags
desc 'List all tags in the current Doing file'
arg_name 'MAX_COUNT', optional: true, type: Integer
command :tags do |c|
  c.desc 'Section'
  c.arg_name 'SECTION_NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc 'Show count of occurrences'
  c.switch %i[c counts]

  c.desc 'Output in a single line with @ symbols. Ignored if --counts is specified.'
  c.switch %i[l line]

  c.desc 'Sort by name or count'
  c.arg_name 'SORT_ORDER'
  c.flag %i[sort], default_value: 'name', must_match: /^(?:n(?:ame)?|c(?:ount)?)$/

  c.desc 'Sort order (asc/desc)'
  c.arg_name 'ORDER'
  c.flag %i[o order], must_match: REGEX_SORT_ORDER, default_value: 'asc'

  c.desc 'Get tags for entries matching tags. Combine multiple tags with a comma. Wildcards allowed (*, ?)'
  c.arg_name 'TAG'
  c.flag [:tag]

  c.desc 'Get tags for items matching search. Surround with
  slashes for regex (e.g. "/query/"), start with a single quote for exact match ("\'query").'
  c.arg_name 'QUERY'
  c.flag [:search]

  c.desc 'Perform a tag value query ("@done > two hours ago" or "@progress < 50"). May be used multiple times, combined with --bool'
  c.arg_name 'QUERY'
  c.flag [:val], multiple: true, must_match: REGEX_VALUE_QUERY

  # c.desc '[DEPRECATED] Use alternative fuzzy matching for search string'
  # c.switch [:fuzzy], default_value: false, negatable: false

  c.desc 'Force exact search string matching (case sensitive)'
  c.switch %i[x exact], default_value: @config.exact_match?, negatable: @config.exact_match?

  c.desc 'Get tags from items that *don\'t* match search/tag filters'
  c.switch [:not], default_value: false, negatable: false

  c.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
  c.arg_name 'TYPE'
  c.flag [:case], must_match: /^[csi]/, default_value: @settings.dig('search', 'case')

  c.desc 'Boolean used to combine multiple tags. Use PATTERN to parse + and - as booleans'
  c.arg_name 'BOOLEAN'
  c.flag [:bool], must_match: REGEX_BOOL, default_value: 'PATTERN'

  c.desc 'Select items to scan from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

  c.action do |_global, options, args|
    section = @wwid.guess_section(options[:section]) || options[:section].cap_first
    options[:count] = args.count.positive? ? args[0].to_i : 0

    items = @wwid.filter_items([], opt: options)

    if options[:interactive]
      items = Doing::Prompt.choose_from_items(items, include_section: options[:section].nil?,
        menu: true,
        header: '',
        prompt: 'Select entries to scan > ',
        multiple: true,
        sort: true,
        show_if_single: true)
    end

    # items = @wwid.content.in_section(section)
    tags = @wwid.all_tags(items, counts: true)

    if options[:sort] =~ /^n/i
      tags = tags.sort_by { |tag, count| tag }
    else
      tags = tags.sort_by { |tag, count| count }
    end

    tags.reverse! if options[:order].normalize_order == 'desc'

    if options[:counts]
      tags.each { |t, c| puts "#{t} (#{c})" }
    else
      if options[:line]
        puts tags.map { |t, c| t }.to_tags.join(' ')
      else
        tags.each { |t, c| puts "#{t}" }
      end
    end
  end
end
