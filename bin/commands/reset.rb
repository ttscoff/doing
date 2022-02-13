# @@reset @@begin
desc 'Reset the start time of an entry'
long_desc 'Update the start time of the last entry or the last entry matching a tag/search filter.
If no argument is provided, the start time will be reset to the current time.
If a date string is provided as an argument, the start time will be set to the parsed result.'
arg_name 'DATE_STRING', optional: true
command %i[reset begin] do |c|
  c.example 'doing reset', desc: 'Reset the start time of the last entry to the current time'
  c.example 'doing reset --tag project1', desc: 'Reset the start time of the most recent entry tagged @project1 to the current time'
  c.example 'doing reset 3pm', desc: 'Reset the start time of the last entry to 3pm of the current day'
  c.example 'doing begin --tag todo --resume', desc: 'alias for reset. Updates the last @todo entry to the current time, removing @done tag.'

  c.desc 'Limit search to section'
  c.arg_name 'NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc 'Resume entry (remove @done)'
  c.switch %i[r resume], default_value: true

  c.desc 'Change start date but do not remove @done (shortcut for --no-resume)'
  c.switch [:n]

  c.desc 'Select from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

  add_options(:search, c)
  add_options(:tag_filter, c)

  c.action do |global_options, options, args|
    if args.count.positive?
      reset_date = args.join(' ').chronify(guess: :begin)
      raise InvalidArgument, 'Invalid date string' unless reset_date

    else
      reset_date = Time.now
    end

    options[:fuzzy] = false

    options[:section] = @wwid.guess_section(options[:section]) || options[:section].cap_first if options[:section]

    if options[:search]
      search = options[:search]
      search.sub!(/^'?/, "'") if options[:exact]
      options[:search] = search
    end

    items = @wwid.filter_items([], opt: options)

    last_entry = if options[:interactive]
                   Doing::Prompt.choose_from_items(items, include_section: options[:section].nil?,
                                                          menu: true,
                                                          header: '',
                                                          prompt: 'Select an entry to start/reset > ',
                                                          multiple: false,
                                                          sort: false,
                                                          show_if_single: true)
                 else
                   items.reverse.last
                 end


    raise NoResults, 'No entry matching parameters was found.' unless last_entry

    old_item = last_entry.clone

    @wwid.reset_item(last_entry, date: reset_date, resume: options[:resume])
    Doing::Hooks.trigger :post_entry_updated, @wwid, last_entry, old_item
    # new_entry = Doing::Item.new(last_entry.date, last_entry.title, last_entry.section, new_note)

    @wwid.write(@wwid.doing_file)
  end
end
