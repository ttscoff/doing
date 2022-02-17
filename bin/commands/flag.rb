# @@mark @@flag
desc 'Mark last entry as flagged'
command %i[mark flag] do |c|
  c.example 'doing flag', desc: 'Add @flagged to the last entry created'
  c.example 'doing mark', desc: 'mark is an alias for flag'
  c.example 'doing flag --tag project1 --count 2', desc: 'Add @flagged to the last 2 entries tagged @project1'
  c.example 'doing flag --interactive --search "/(develop|cod)ing/"', desc: 'Find entries matching regular expression and create a menu allowing multiple selections, selected items will be @flagged'

  c.desc 'Section'
  c.arg_name 'SECTION_NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc 'How many recent entries to tag (0 for all)'
  c.arg_name 'COUNT'
  c.flag %i[c count], default_value: 1, must_match: /^\d+$/, type: Integer

  c.desc 'Don\'t ask permission to flag all entries when count is 0'
  c.switch %i[force], negatable: false, default_value: false

  c.desc 'Include current date/time with tag'
  c.switch %i[d date], negatable: false, default_value: false

  c.desc 'Remove flag'
  c.switch %i[r remove], negatable: false, default_value: false

  c.desc 'Flag last entry (or entries) not marked @done'
  c.switch %i[u unfinished], negatable: false, default_value: false

  c.desc 'Select item(s) to flag from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

  add_options(:search, c)
  add_options(:tag_filter, c)

  c.action do |_global_options, options, _args|
    options[:fuzzy] = false
    mark = Doing.setting('marker_tag', 'flagged')

    raise InvalidArgument, '--search and --tag can not be used together' if options[:search] && options[:tag]

    section = 'All'

    section = @wwid.guess_section(options[:section]) || options[:section].cap_first if options[:section]

    search_tags = options[:tag].nil? ? [] : options[:tag]

    if options[:interactive]
      count = 0
      options[:force] = true
    else
      count = options[:count].to_i
    end

    if options[:search]
      search = options[:search]
      search.sub!(/^'?/, "'") if options[:exact]
      options[:search] = search
    end

    if count.zero? && !options[:force]
      section_q = if options[:search]
                    ' matching your search terms'
                  elsif options[:tag]
                    ' matching your tag search'
                  elsif section == 'All'
                    ''
                  else
                    " in section #{section}"
                  end

      question = if options[:remove]
                   "Are you sure you want to unflag all entries#{section_q}"
                 else
                   "Are you sure you want to flag all records#{section_q}"
                 end

      res = Doing::Prompt.yn(question, default_response: false)

      exit_now! 'Cancelled' unless res
    end

    options[:count] = count
    options[:section] = section
    options[:tag] = search_tags
    options[:tags] = [mark]
    options[:tag_bool] = options[:bool]

    @wwid.tag_last(options)
  end
end
