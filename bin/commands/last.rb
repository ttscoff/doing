# @@last
desc 'Show the last entry, optionally edit'
long_desc 'Shows the last entry. Using --search and --tag filters, you can view/edit the last entry matching a filter,
allowing `doing last` to target historical entries.'
command :last do |c|
  c.example 'doing last', desc: 'Show the most recent entry in all sections'
  c.example 'doing last -s Later', desc: 'Show the most recent entry in the Later section'
  c.example 'doing last --tag project1,work --bool AND', desc: 'Show most recent entry tagged @project1 and @work'
  c.example 'doing last --search "side hustle"', desc: 'Show most recent entry containing "side hustle" (fuzzy matching)'
  c.example 'doing last --search "\'side hustle"', desc: 'Show most recent entry containing "side hustle" (exact match)'
  c.example 'doing last --edit', desc: 'Open the most recent entry in an editor for modifications'
  c.example 'doing last --search "\'side hustle" --edit', desc: 'Open most recent entry containing "side hustle" (exact match) in editor'

  c.desc 'Specify a section'
  c.arg_name 'NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc "Edit entry with #{Doing::Util.default_editor}"
  c.switch %i[e editor], negatable: false, default_value: false

  c.desc "Delete the last entry"
  c.switch %i[d delete], negatable: false, default_value: false

  c.desc "Highlight search matches in output. Only affects command line output"
  c.switch %i[h hilite], default_value: Doing.settings.dig('search', 'highlight')

  c.desc 'Show elapsed time if entry is not tagged @done'
  c.switch [:duration]

  add_options(:output_template, c, default_template: 'last')
  add_options(:search, c)
  add_options(:tag_filter, c)
  add_options(:save)

  c.action do |global_options, options, _args|
    options[:fuzzy] = false
    raise InvalidArgument, '--tag and --search can not be used together' if options[:tag] && options[:search]

    options[:tag] ||= []

    options[:search] = options[:search].sub(/^'?/, "'") if options[:search] && options[:exact]

    if options[:editor]
      @wwid.edit_last(section: options[:section],
                     options: {
                       search: options[:search],
                       fuzzy: options[:fuzzy],
                       case: options[:case],
                       tag: options[:tag],
                       tag_bool: options[:bool],
                       not: options[:not],
                       val: options[:val],
                       bool: options[:bool]
                     })
    else
      last = @wwid.last(times: true, section: options[:section],
                     options: {
                        config_template: options[:config_template],
                        template: options[:template],
                        duration: options[:duration],
                        search: options[:search],
                        fuzzy: options[:fuzzy],
                        case: options[:case],
                        hilite: options[:hilite],
                        negate: options[:not],
                        output: options[:output],
                        tag: options[:tag],
                        tag_bool: options[:bool],
                        delete: options[:delete],
                        bool: options[:bool],
                        val: options[:val]
                      })
      Doing::Pager::page last.strip if last
      Doing.config.save_view(options.to_view, options[:save].downcase) if options[:save]
    end
  end
end
