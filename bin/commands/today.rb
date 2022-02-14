# @@today
desc 'List entries from today'
long_desc 'List entries from the current day. Use --before, --after, and
--from to specify time ranges.'
command :today do |c|
  c.example 'doing today', desc: 'List all entries with start dates between 12am and 11:59PM for the current day'
  c.example 'doing today --section Later', desc: 'List today\'s entries in the Later section'
  c.example 'doing today --before 3pm --after 12pm', desc: 'List entries with start dates between 12pm and 3pm today'
  c.example 'doing today --output json', desc: 'Output entries from today in JSON format'

  c.desc 'Specify a section'
  c.arg_name 'NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc 'Show time intervals on @done tasks'
  c.switch %i[t times], default_value: true, negatable: true

  c.desc 'Show elapsed time on entries without @done tag'
  c.switch [:duration]

  c.desc 'Show time totals at the end of output'
  c.switch [:totals], default_value: false, negatable: false

  c.desc 'Sort tags by (name|time)'
  default = @settings['tag_sort'].normalize_tag_sort || :name
  c.arg_name 'KEY'
  c.flag [:tag_sort], must_match: REGEX_TAG_SORT, default_value: default, type: TagSortSymbol

  c.desc "Output to export format (#{Doing::Plugins.plugin_names(type: :export)})"
  c.arg_name 'FORMAT'
  c.flag %i[o output]

  c.desc "Output using a template from configuration"
  c.arg_name 'TEMPLATE_KEY'
  c.flag [:config_template], type: TemplateName, default_value: 'today'

  c.desc 'Override output format with a template string containing %placeholders'
  c.arg_name 'TEMPLATE_STRING'
  c.flag [:template]

  c.desc 'View entries before specified time (e.g. 8am, 12:30pm, 15:00)'
  c.arg_name 'TIME_STRING'
  c.flag [:before]

  c.desc 'View entries after specified time (e.g. 8am, 12:30pm, 15:00)'
  c.arg_name 'TIME_STRING'
  c.flag [:after]

  c.desc %(
    Time range to show `doing today --from "12pm to 4pm"`
  )
  c.arg_name 'TIME_RANGE'
  c.flag [:from], type: DateRangeString

  c.action do |_global_options, options, _args|
    raise DoingRuntimeError, %(Invalid output type "#{options[:output]}") if options[:output] && options[:output] !~ Doing::Plugins.plugin_regex(type: :export)

    options[:times] = true if options[:totals]
    options[:sort_tags] = options[:tag_sort]
    filter_options = %i[after before duration from section sort_tags totals template config_template].each_with_object({}) { |k, hsh| hsh[k] = options[k] }

    Doing::Pager.page @wwid.today(options[:times], options[:output], filter_options).chomp
  end
end
