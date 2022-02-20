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

  c.desc "Output to export format (#{Doing::Plugins.plugin_names(type: :export)})"
  c.arg_name 'FORMAT'
  c.flag %i[o output]

  c.desc "Output using a template from configuration"
  c.arg_name 'TEMPLATE_KEY'
  c.flag [:config_template], type: TemplateName, default_value: 'today'

  c.desc 'Override output format with a template string containing %placeholders'
  c.arg_name 'TEMPLATE_STRING'
  c.flag [:template]

  add_options(:time_filter, c)
  add_options(:time_display, c)

  c.action do |_global_options, options, _args|
    raise DoingRuntimeError, %(Invalid output type "#{options[:output]}") if options[:output] && options[:output] !~ Doing::Plugins.plugin_regex(type: :export)

    options[:times] = true if options[:totals]
    options[:sort_tags] = options[:tag_sort]
    filter_options = %i[after before times duration from section sort_tags totals tag_order template config_template only_timed].each_with_object({}) { |k, hsh| hsh[k] = options[k] }

    Doing::Pager.page @wwid.today(options[:times], options[:output], filter_options).chomp
  end
end
