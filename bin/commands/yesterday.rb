# frozen_string_literal: true

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
  c.flag %i[s section], default_value: 'All', multiple: true

  add_options(:output_template, c, default_template: 'today')
  add_options(:time_filter, c)
  add_options(:time_display, c)
  add_options(:save, c)

  c.action do |_global_options, options, _args|
    if options[:output] && options[:output] !~ Doing::Plugins.plugin_regex(type: :export)
      raise InvalidPlugin.new('output',
                              options[:output])
    end

    options[:sort_tags] = options[:tag_sort]

    opt = options.clone
    opt[:order] = Doing.setting(['templates', options[:config_template], 'order'])
    opt[:yesterday] = true
    Doing::Pager.page @wwid.yesterday(options[:section], options[:times], options[:output], opt).chomp
    Doing.config.save_view(opt.to_view, options[:save].downcase) if options[:save]
  end
end
