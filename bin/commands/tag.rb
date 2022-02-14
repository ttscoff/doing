# @@tag
desc 'Add tag(s) to last entry'
long_desc 'Add (or remove) tags from the last entry, or from multiple entries
          (with `--count`), entries matching a search (with `--search`), or entries
          containing another tag (with `--tag`).

          When removing tags with `-r`, wildcards are allowed (`*` to match
          multiple characters, `?` to match a single character). With `--regex`,
          regular expressions will be interpreted instead of wildcards.

          For all tag removals the match is case insensitive by default, but if
          the tag search string contains any uppercase letters, the match will
          become case sensitive automatically.

          Tag name arguments do not need to be prefixed with @.'
arg_name 'TAG', :multiple
command :tag do |c|
  c.example 'doing tag mytag', desc: 'Add @mytag to the last entry created'
  c.example 'doing tag --remove mytag', desc: 'Remove @mytag from the last entry created'
  c.example 'doing tag --rename "other*" --count 10 newtag', desc: 'Rename tags beginning with "other" (wildcard) to @newtag on the last 10 entries'
  c.example 'doing tag --search "developing" coding', desc: 'Add @coding to the last entry containing string "developing" (fuzzy matching)'
  c.example 'doing tag --interactive --tag project1 coding', desc: 'Create an interactive menu from entries tagged @project1, selection(s) will be tagged with @coding'

  c.desc 'Section'
  c.arg_name 'SECTION_NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc 'How many recent entries to tag (0 for all)'
  c.arg_name 'COUNT'
  c.flag %i[c count], default_value: 1, must_match: /^\d+$/, type: Integer

  c.desc 'Replace existing tag with tag argument, wildcards (*,?) allowed, or use with --regex'
  c.arg_name 'ORIG_TAG'
  c.flag %i[rename]

  c.desc 'Include a value, e.g. @tag(value)'
  c.arg_name 'VALUE'
  c.flag %i[v value]

  c.desc 'Don\'t ask permission to tag all entries when count is 0'
  c.switch %i[force], negatable: false, default_value: false

  c.desc 'Include current date/time with tag'
  c.switch %i[d date], negatable: false, default_value: false

  c.desc 'Remove given tag(s)'
  c.switch %i[r remove], negatable: false, default_value: false

  c.desc 'Interpret tag string as regular expression (with --remove)'
  c.switch %i[regex], negatable: false, default_value: false

  c.desc 'Tag last entry (or entries) not marked @done'
  c.switch %i[u unfinished], negatable: false, default_value: false

  c.desc 'Autotag entries based on autotag configuration in ~/.config/doing/config.yml'
  c.switch %i[a autotag], negatable: false, default_value: false

  c.desc 'Select item(s) to tag from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

  add_options(:search, c)
  add_options(:tag_filter, c)

  c.action do |_global_options, options, args|
    options[:fuzzy] = false
    # raise MissingArgument, 'You must specify at least one tag' if args.empty? && !options[:autotag]

    raise InvalidArgument, '--search and --tag can not be used together' if options[:search] && options[:tag]

    section = 'All'

    if options[:section]
      section = @wwid.guess_section(options[:section]) || options[:section].cap_first
    end


    if options[:tag].nil?
      search_tags = []
    else
      search_tags = options[:tag]
    end

    if options[:autotag]
      tags = []
    else
      if args.empty?
        tags = []
      else
        tags = if args.join('') =~ /,/
                 args.join('').split(/ *, */)
               else
                 args.join(' ').split(' ') # in case tags are quoted as one arg
               end
      end

      tags.map! { |tag| tag.sub(/^@/, '').strip }
    end

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

    options[:count] = count
    options[:section] = section
    options[:tag] = search_tags
    options[:tags] = tags
    options[:tag_bool] = options[:bool]

    if count.zero? && !options[:force]
      matches = @wwid.filter_items([], opt: options).count

      if matches > 5
        if options[:search]
          section_q = ' matching your search terms'
        elsif options[:tag]
          section_q = ' matching your tag search'
        elsif section == 'All'
          section_q = ''
        else
          section_q = " in section #{section}"
        end


        question = if options[:autotag]
                     "Are you sure you want to autotag #{matches} records#{section_q}"
                   elsif options[:remove]
                     "Are you sure you want to remove #{tags.join(' and ')} from #{matches} records#{section_q}"
                   else
                     "Are you sure you want to add #{tags.join(' and ')} to #{matches} records#{section_q}"
                   end

        res = Doing::Prompt.yn(question, default_response: false)

        raise UserCancelled unless res
      end
    end

    @wwid.tag_last(options)
  end
end
