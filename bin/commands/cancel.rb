# frozen_string_literal: true

# @@cancel
desc 'End last X entries with no time tracked'
long_desc 'Adds @done tag without datestamp so no elapsed time is recorded.
           Alias for `doing finish --no-date`'
arg_name 'COUNT'
command :cancel do |c|
  c.example 'doing cancel', desc: 'Cancel the last entry'
  c.example 'doing cancel --tag project1 -u 5', desc: 'Cancel the last 5 unfinished entries containing @project1'

  c.desc 'Archive entries'
  c.switch %i[a archive], negatable: false, default_value: false

  c.desc 'Section'
  c.arg_name 'NAME'
  c.flag %i[s section]

  c.desc 'Cancel last entry (or entries) not already marked @done'
  c.switch %i[u unfinished], negatable: false, default_value: false

  c.desc 'Select item(s) to cancel from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

  add_options(:search, c)
  add_options(:tag_filter, c)

  c.action do |_global_options, options, args|
    options[:fuzzy] = false
    options[:section] = if options[:section]
                          @wwid.guess_section(options[:section]) || options[:section].cap_first
                        else
                          Doing.setting('current_section')
                        end

    raise InvalidArgument, 'Only one argument allowed' if args.length > 1

    unless args.empty? || args[0] =~ /\d+/
      raise InvalidArgument, 'Invalid argument (specify number of recent items to mark @done)'

    end

    options[:count] = if options[:interactive]
                        0
                      else
                        args[0] ? args[0].to_i : 1
                      end

    options[:search] = options[:search].sub(/^'?/, "'") if options[:search] && options[:exact]

    options[:case] = options[:case].normalize_case
    options[:date] = false
    options[:sequential] = false
    options[:tag] ||= []
    options[:tag_bool] = options[:bool].normalize_bool
    options[:tags] = ['done']

    @wwid.tag_last(options)
  end
end
