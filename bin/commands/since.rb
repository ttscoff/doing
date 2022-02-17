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

  c.desc 'Show time intervals on @done tasks'
  c.switch %i[t times], default_value: true, negatable: true

  c.desc 'Show elapsed time on entries without @done tag'
  c.switch [:duration]

  c.desc 'Show time totals at the end of output'
  c.switch [:totals], default_value: false, negatable: false

  c.desc 'Sort tags by (name|time)'
  default = Doing.setting('tag_sort').normalize_tag_sort || :name
  c.arg_name 'KEY'
  c.flag [:tag_sort], must_match: REGEX_TAG_SORT, default_value: default, type: TagSortSymbol

  c.desc "Output to export format (#{Doing::Plugins.plugin_names(type: :export)})"
  c.arg_name 'FORMAT'
  c.flag %i[o output]

  c.desc "Output using a template from configuration"
  c.arg_name 'TEMPLATE_KEY'
  c.flag [:config_template], type: TemplateName, default_value: 'default'

  c.desc 'Override output format with a template string containing %placeholders'
  c.arg_name 'TEMPLATE_STRING'
  c.flag [:template]

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

    Doing::Pager.page @wwid.list_date([start, finish], options[:section], options[:times], options[:output],
                        { template: options[:template], config_template: options[:config_template], duration: options[:duration], totals: options[:totals], sort_tags: options[:sort_tags] }).chomp
  end
end
