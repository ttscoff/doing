# frozen_string_literal: true

# @@archive @@move
desc 'Move entries between sections'
long_desc %(Argument can be a section name to move all entries from a section,
or start with an "@" to move entries matching a tag.

Default with no argument moves items from the "#{@settings['current_section']}" section to Archive.)
arg_name 'SECTION_OR_TAG'
default_value @settings['current_section']
command %i[archive move] do |c|
  c.example 'doing archive Currently', desc: 'Move all entries in the Currently section to Archive section'
  c.example 'doing archive @done', desc: 'Move all entries tagged @done to Archive'
  c.example 'doing archive --to Later @project1', desc: 'Move all entries tagged @project1 to Later section'
  c.example 'doing move Later --tag project1 --to Currently',
            desc: 'Move entries in Later tagged @project1 to Currently (move is an alias for archive)'

  c.desc 'How many items to keep (ignored if archiving by tag or search)'
  c.arg_name 'X'
  c.flag %i[k keep], must_match: /^\d+$/, type: Integer

  c.desc 'Move entries to'
  c.arg_name 'SECTION_NAME'
  c.flag %i[t to], default_value: 'Archive'

  c.desc 'Label moved items with @from(SECTION_NAME)'
  c.switch [:label], default_value: true, negatable: true

  c.desc 'Tag filter, combine multiple tags with a comma. Wildcards allowed (*, ?).
          Added for compatibility with other commands'
  c.arg_name 'TAG'
  c.flag [:tag], type: TagArray

  c.desc 'Tag boolean (AND|OR|NOT). Use PATTERN to parse + and - as booleans'
  c.arg_name 'BOOLEAN'
  c.flag [:bool], must_match: REGEX_BOOL,
                  default_value: 'PATTERN'.normalize_bool,
                  type: BooleanSymbol

  c.desc 'Search filter'
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

  c.desc 'Show items that *don\'t* match search string'
  c.switch [:not], default_value: false, negatable: false

  c.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
  c.arg_name 'TYPE'
  c.flag [:case], must_match: REGEX_CASE,
                  default_value: @settings.dig('search', 'case').normalize_case,
                  type: CaseSymbol

  c.desc 'Archive entries older than date
    (Flexible date format, e.g. 1/27/2021, 2020-07-19, or Monday 3pm)'
  c.arg_name 'DATE_STRING'
  c.flag [:before], type: DateEndString

  c.action do |_global_options, options, args|
    options[:fuzzy] = false
    section, tags = if args.empty?
                      [@settings['current_section'], []]
                    elsif args[0] =~ /^all/i
                      ['all', []]
                    elsif args[0] =~ /^@\S+/
                      ['all', args.tags_to_array]
                    else
                      [args.shift.cap_first, args.tags_to_array]
                    end

    raise InvalidArgument, '--keep and --count can not be used together' if options[:keep] && options[:count]

    tags.concat(options[:tag]) if options[:tag]

    options[:search] = options[:search].sub(/^'?/, "'") if options[:search] && options[:exact]
    options[:destination] = options[:to]
    options[:tags] = tags

    @wwid.archive(section, options)
  end
end
