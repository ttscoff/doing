# @@on
desc 'List entries for a date'
long_desc %(Date argument can be natural language. "thursday" would be interpreted as "last thursday,"
and "2d" would be interpreted as "two days ago." If you use "to" or "through" between two dates,
it will create a range.)
arg_name 'DATE_STRING'
command :on do |c|
  c.example 'doing on friday', desc: 'List entries between 12am and 11:59PM last Friday'
  c.example 'doing on 12/21/2020', desc: 'List entries from Dec 21, 2020'
  c.example 'doing on "3d to 1d"', desc: 'List entries added between 3 days ago and 1 day ago'

  c.desc 'Section'
  c.arg_name 'NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc "Output to export format (#{Doing::Plugins.plugin_names(type: :export)})"
  c.arg_name 'FORMAT'
  c.flag %i[o output]

  c.desc "Output using a template from configuration"
  c.arg_name 'TEMPLATE_KEY'
  c.flag [:config_template], type: TemplateName, default_value: 'default'

  c.desc 'Override output format with a template string containing %placeholders'
  c.arg_name 'TEMPLATE_STRING'
  c.flag [:template]

  add_options(:time_display, c)
  add_options(:search, c)
  add_options(:tag_filter, c)
  add_options(:time_filter, c)

  c.action do |_global_options, options, args|
    raise DoingRuntimeError, %(Invalid output type "#{options[:output]}") if options[:output] && options[:output] !~ Doing::Plugins.plugin_regex(type: :export)

    raise MissingArgument, 'Missing date argument' if args.empty?

    date_string = args.join(' ').strip
    if date_string =~ /^tod(?:ay)?/i
      date_string = 'today 01:00 to today 23:59'
    end

    puts date_string

    start, finish = date_string.split_date_range

    raise InvalidTimeExpression, "Unrecognized date string (#{date_string})" unless start

    message = "date interpreted as #{start}"
    message += " to #{finish}" if finish
    Doing.logger.debug('Interpreter:', message)

    options[:times] = true if options[:totals]
    options[:sort_tags] = options[:tag_sort]

    Doing::Pager.page @wwid.list_date([start, finish], options[:section], options[:times], options[:output], options).chomp
  end
end
