# @@rotate
desc 'Move entries to archive file'
long_desc 'As your doing file grows, commands can get slow. Given that your historical data (and your archive section)
probably aren\'t providing any useful insights a year later, use this command to "rotate" old entries out to an archive
file. You\'ll still have access to all historical data, but it won\'t be slowing down daily operation.'
command :rotate do |c|
  c.example 'doing rotate', desc: 'Move all entries in doing file to a dated secondary file'
  c.example 'doing rotate --section Archive --keep 10', desc: 'Move entries in the Archive section to a secondary file, keeping the most recent 10 entries'
  c.example 'doing rotate --tag project1,done --bool AND', desc: 'Move entries tagged @project1 and @done to a secondary file'

  c.desc 'How many items to keep in each section (most recent)'
  c.arg_name 'X'
  c.flag %i[k keep], must_match: /^\d+$/, type: Integer

  c.desc 'Section to rotate'
  c.arg_name 'SECTION_NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc 'Rotate entries older than date
    (Flexible date format, e.g. 1/27/2021, 2020-07-19, or Monday 3pm)'
  c.arg_name 'DATE_STRING'
  c.flag [:before]

  add_options(:search, c)
  add_options(:tag_filter, c)

  c.action do |_global_options, options, _args|
    options[:fuzzy] = false

    options[:section] = @wwid.guess_section(options[:section]) if options[:section] && options[:section] !~ /^all$/i

    search = nil

    if options[:search]
      search = options[:search]
      search.sub!(/^'?/, "'") if options[:exact]
      options[:search] = search
    end

    @wwid.rotate(options)
  end
end
