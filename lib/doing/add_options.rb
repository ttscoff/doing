# frozen_string_literal: true

##
## Add presets of flags and switches to a command.
##
## :output_template => --output, --config_template, --template
##
## :add_entry => --noauto, --note, --ask, --editor, --back
##
## :finish_entry => --at/finished, --from, --took
##
## :time_display => --times, --duration, --totals, --tag_sort, --tag_order, --only_timed
##
## :search => --search, --case, --exact
##
## :tag_filter => --tag, --bool, --not, --val
##
## :time_filter => --before, --after, --from
##
## :date_filter => --before, --after, --from
##
## @param      type  [Symbol] The type
## @param      cmd   The GLI command to which the options will be added
##
def add_options(type, cmd, default_template: 'default')
  cmd_name = cmd.name.to_s
  action = case cmd_name
           when /again/
             'Repeat'
           when /grep/
             'Search'
           when /mark/
             'Flag'
           when /(last|tags|view|on)/
             'Show'
           else
             cmd_name.capitalize
           end

  case type
  when :output_template
    cmd.desc "Output to export format (#{Doing::Plugins.plugin_names(type: :export)})"
    cmd.arg_name 'FORMAT'
    cmd.flag %i[o output]

    cmd.desc "Output using a template from configuration"
    cmd.arg_name 'TEMPLATE_KEY'
    cmd.flag [:config_template], type: TemplateName, default_value: default_template

    cmd.desc 'Override output format with a template string containing %placeholders'
    cmd.arg_name 'TEMPLATE_STRING'
    cmd.flag [:template]
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
  when :finish_entry
    cmd.desc %(Set finish date to specific date/time (natural langauge parsed, e.g. --at=1:30pm).
    Used with --took, backdates start date)
    cmd.arg_name 'DATE_STRING'
    cmd.flag %i[at finished], type: DateEndString

    cmd.desc %(
          Start and end times as a date/time range `doing done --from "1am to 8am"`.
          Overrides other date flags.
        )
    cmd.arg_name 'TIME_RANGE'
    cmd.flag [:from], must_match: REGEX_RANGE

    cmd.desc %(Set completion date to start date plus interval (XX[mhd] or HH:MM).
    If used without the --back option, the start date will be moved back to allow
    the completion date to be the current time.)
    cmd.arg_name 'INTERVAL'
    cmd.flag %i[t took for], type: DateIntervalString
  when :search
    cmd.desc 'Filter entries using a search query, surround with slashes for regex (e.g. "/query.*/"),
            start with single quote for exact match ("\'query")'
    cmd.arg_name 'QUERY'
    cmd.flag [:search]

    cmd.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
    cmd.arg_name 'TYPE'
    cmd.flag [:case], must_match: REGEX_CASE,
                      default_value: Doing.settings.dig('search', 'case').normalize_case,
                      type: CaseSymbol

    cmd.desc 'Force exact search string matching (case sensitive)'
    cmd.switch %i[x exact], default_value: Doing.config.exact_match?, negatable: Doing.config.exact_match?
  when :time_display
    cmd.desc 'Show time intervals on @done tasks'
    cmd.switch %i[t times], default_value: true, negatable: true

    cmd.desc 'Show elapsed time on entries without @done tag'
    cmd.switch [:duration]

    cmd.desc 'Show time totals at the end of output'
    cmd.switch [:totals], default_value: false, negatable: false

    cmd.desc 'Sort tags by (name|time)'
    default = Doing.setting('tag_sort').normalize_tag_sort || :name
    cmd.arg_name 'KEY'
    cmd.flag [:tag_sort], must_match: REGEX_TAG_SORT, default_value: default, type: TagSortSymbol

    cmd.desc 'Tag sort direction (asc|desc)'
    cmd.arg_name 'DIRECTION'
    cmd.flag [:tag_order], must_match: REGEX_SORT_ORDER, default_value: :asc, type: OrderSymbol

    cmd.desc 'Only show items with recorded time intervals'
    cmd.switch [:only_timed], default_value: false, negatable: false
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
  when :time_filter
    cmd.desc 'View entries before specified time (e.g. 8am, 12:30pm, 15:00)'
    cmd.arg_name 'TIME_STRING'
    cmd.flag [:before], type: DateEndString

    cmd.desc 'View entries after specified time (e.g. 8am, 12:30pm, 15:00)'
    cmd.arg_name 'TIME_STRING'
    cmd.flag [:after], type: DateBeginString

    cmd.desc %(
      Time range to show `doing #{cmd.name} --from "12pm to 4pm"`
    )
    cmd.arg_name 'TIME_RANGE'
    cmd.flag [:from], type: DateRangeString, must_match: REGEX_TIME_RANGE
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
