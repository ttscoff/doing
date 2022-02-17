# frozen_string_literal: true

##
## Add presets of flags and switches to a command.
##
## :add_entry => --noauto, --note, --ask, --editor, --back
##
## :search => --search, --case, --exact
##
## :tag_filter => --tag, --bool, --not, --val
##
## :date_filter => --before, --after, --from
##
## @param      type  [Symbol] The type
## @param      cmd   The GLI command to which the options will be added
##
def add_options(type, cmd)
  cmd_name = cmd.name.to_s
  action = case cmd_name
           when /again/
             'Repeat'
           when /grep/
             'Search'
           when /mark/
             'Flag'
           when /(last|tags|view)/
             'Show'
           else
             cmd_name.capitalize
           end

  case type
  when :add_entry
    cmd.desc 'Exclude auto tags and default tags'
    cmd.switch %i[X noauto], default_value: false, negatable: false

    cmd.desc 'Include a note'
    cmd.arg_name 'TEXT'
    cmd.flag %i[n note]

    cmd.desc 'Prompt for note via multi-line input'
    cmd.switch %i[ask], negatable: false, default_value: false

    cmd.desc "Edit entry with #{Doing::Util.default_editor}"
    cmd.switch %i[e editor], negatable: false, default_value: false

    cmd.desc 'Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]'
    cmd.arg_name 'DATE_STRING'
    cmd.flag %i[b back started], type: DateBeginString
  when :search
    cmd.desc 'Filter entries using a search query, surround with slashes for regex (e.g. "/query.*/"),
            start with single quote for exact match ("\'query")'
    cmd.arg_name 'QUERY'
    cmd.flag [:search]

    cmd.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
    cmd.arg_name 'TYPE'
    cmd.flag [:case], must_match: REGEX_CASE,
                      default_value: @settings.dig('search', 'case').normalize_case,
                      type: CaseSymbol

    cmd.desc 'Force exact search string matching (case sensitive)'
    cmd.switch %i[x exact], default_value: @config.exact_match?, negatable: @config.exact_match?
  when :tag_filter
    cmd.desc 'Filter entries by tag. Combine multiple tags with a comma. Wildcards allowed (*, ?)'
    cmd.arg_name 'TAG'
    cmd.flag [:tag], type: TagArray

    cmd.desc 'Perform a tag value query ("@done > two hours ago" or "@progress < 50").
            May be used multiple times, combined with --bool'
    cmd.arg_name 'QUERY'
    cmd.flag [:val], multiple: true, must_match: REGEX_VALUE_QUERY

    cmd.desc "#{action} items that *don't* match search/tag filters"
    cmd.switch [:not], default_value: false, negatable: false

    cmd.desc 'Boolean used to combine multiple tags. Use PATTERN to parse + and - as booleans'
    cmd.arg_name 'BOOLEAN'
    cmd.flag [:bool], must_match: REGEX_BOOL,
                      default_value: :pattern,
                      type: BooleanSymbol
  when :date_filter
    if action =~ /Archive/
      cmd.desc 'Archive entries older than date (natural language).'
    else
      cmd.desc "#{action} entries older than date (natural language). If this is only a time (8am, 1:30pm, 15:00), all
              dates will be included, but entries will be filtered by time of day"
    end
    cmd.arg_name 'DATE_STRING'
    cmd.flag [:before], type: DateBeginString

    if action =~ /Archive/
      cmd.desc 'Archive entries newer than date (natural language).'
    else
      cmd.desc "#{action} entries newer than date (natural language). If this is only a time (8am, 1:30pm, 15:00), all
              dates will be included, but entries will be filtered by time of day"
    end
    cmd.arg_name 'DATE_STRING'
    cmd.flag [:after], type: DateEndString

    if action =~ /Archive/
      cmd.desc %(
          Date range (natural language) to archive: `doing archive --from "1/1/21 to 12/31/21"`.
        )
    else
      cmd.desc %(
        Date range (natural language) to #{action.downcase}, or a single day to filter on.
        To specify a range, use "to": `doing #{cmd_name} --from "monday 8am to friday 5pm"`.

        If values are only time(s) (6am to noon) all dates will be included, but entries will be filtered
        by time of day.
      )
    end
    cmd.arg_name 'DATE_OR_RANGE'
    cmd.flag [:from], type: DateRangeString
  end
end
