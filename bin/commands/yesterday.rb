# @@yesterday
desc 'List entries from yesterday'
long_desc 'Show only entries with start times within the previous 24 hour period. Use --before, --after, and --from to limit to
time spans within the day.'
command :yesterday do |c|
  c.example 'doing yesterday', desc: 'List all entries from the previous day'
  c.example 'doing yesterday --after 8am --before 5pm', desc: 'List entries from the previous day between 8am and 5pm'
  c.example 'doing yesterday --totals', desc: 'List entries from previous day, including tag timers'

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

    options[:sort_tags] = options[:tag_sort]

    if options[:from]
      options[:from] = options[:from].split(/#{REGEX_RANGE_INDICATOR}/).map do |time|
        "yesterday #{time.sub(/(?mi)(^.*?(?=\d+)|(?<=[ap]m).*?$)/, '')}"
      end.join(' to ').split_date_range
    end

    opt = options.clone
    opt[:order] = Doing.setting(['templates', options[:config_template], 'order'])

    Doing::Pager.page @wwid.yesterday(options[:section], options[:times], options[:output], opt).chomp
  end
end
