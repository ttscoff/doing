# @since
desc 'List entries since a date'
long_desc %(Date argument can be natural language and are always interpreted as being in the past. "thursday" would be interpreted as "last thursday,"
and "2d" would be interpreted as "two days ago.")
arg_name 'DATE_STRING'
command :since do |c|
  c.example 'doing since 7/30', desc: 'List all entries created since 12am on 7/30 of the current year'
  c.example 'doing since "monday 3pm" --output json', desc: 'Show entries since 3pm on Monday of the current week, output in JSON format'

  c.desc 'Section'
  c.arg_name 'NAME'
  c.flag %i[s section], default_value: 'All'

  add_options(:output_template, c)
  add_options(:time_display, c)
  add_options(:tag_filter, c)
  add_options(:search, c)

  c.action do |_global_options, options, args|
    raise DoingRuntimeError, %(Invalid output type "#{options[:output]}") if options[:output] && options[:output] !~ Doing::Plugins.plugin_regex(type: :export)

    raise MissingArgument, 'Missing date argument' if args.empty?

    date_string = args.join(' ')

    date_string.sub!(/(day) (\d)/, '\1 at \2')
    date_string.sub!(/(\d+)d( ago)?/, '\1 days ago')

    start = date_string.chronify(guess: :begin)
    finish = Time.now

    raise InvalidTimeExpression, 'Unrecognized date string' unless start

    Doing.logger.debug('Interpreter:', "date interpreted as #{start} through the current time")

    options[:times] = true if options[:totals]
    options[:sort_tags] = options[:tag_sort]

    Doing::Pager.page @wwid.list_date([start, finish], options[:section], options[:times], options[:output], options).chomp
  end
end
