# @@view
desc 'Display a user-created view'
long_desc 'Views are defined in your configuration (use `doing config` to edit).
Command line options override view configuration.'
arg_name 'VIEW_NAME'
command :view do |c|
  c.example 'doing view color', desc: 'Display entries according to config for view "color"'
  c.example 'doing view color --section Archive --count 10', desc: 'Display view "color", overriding some configured settings'

  c.desc 'Section'
  c.arg_name 'NAME'
  c.flag %i[s section]

  c.desc 'Count to display'
  c.arg_name 'COUNT'
  c.flag %i[c count], must_match: /^\d+$/, type: Integer

  c.desc 'Age (oldest|newest)'
  c.arg_name 'AGE'
  c.flag %i[age], type: AgeSymbol

  c.desc 'Show time intervals on @done tasks'
  c.switch %i[t times], default_value: true, negatable: true

  c.desc 'Show elapsed time on entries without @done tag'
  c.switch [:duration], default_value: false, negatable: false

  c.desc 'Show intervals with totals at the end of output'
  c.switch [:totals], default_value: false, negatable: false

  c.desc 'Include colors in output'
  c.switch [:color], negatable: true

  c.desc "Highlight search matches in output. Only affects command line output"
  c.switch %i[h hilite], default_value: false, negatable: true

  c.desc 'Sort tags by (name|time)'
  c.arg_name 'KEY'
  c.flag [:tag_sort], must_match: REGEX_TAG_SORT, type: TagSortSymbol

  c.desc 'Tag sort direction (asc|desc)'
  c.arg_name 'DIRECTION'
  c.flag [:tag_order], must_match: REGEX_SORT_ORDER, type: OrderSymbol

  c.desc 'Only show items with recorded time intervals (override view settings)'
  c.switch [:only_timed], default_value: false, negatable: false

  c.desc 'Select from a menu of matching entries to perform additional operations'
  c.switch %i[i interactive], negatable: false, default_value: false

  add_options(:search, c)
  add_options(:tag_filter_no_defaults, c)
  add_options(:date_filter, c)
  add_options(:output_template_no_defaults, c)

  c.action do |global_options, options, args|
    options[:fuzzy] = false
    if options[:output] && options[:output] !~ Doing::Plugins.plugin_regex(type: :export)
      raise InvalidPlugin.new('output', options[:output])

    end

    raise InvalidArgument, '--tag and --search can not be used together' if options[:tag] && options[:search]

    title = if args.empty?
              @wwid.choose_view
            else
              begin
                @wwid.guess_view(args[0])
              rescue WrongCommand
                cmd = commands[:show]
                options[:sort] = :asc
                options[:tag_order] = :asc
                action = cmd.send(:get_action, nil)
                return action.call(global_options, options, args)
              end
            end

    section = if options[:section]
                @wwid.guess_section(options[:section]) || options[:section].cap_first
              else
                Doing.setting('current_section')
              end

    view = @wwid.view_to_options(title)

    options = Doing::Util.deep_merge_hashes(view, options)

    options[:totals] = view[:totals] unless options[:totals]
    options[:only_timed] = view[:only_timed] unless options[:only_timed]
    options[:times] = view[:times] if options[:times]
    options[:times] = true if options[:totals]
    options[:duration] = view[:duration] unless options[:duration]
    options[:hilite] = view[:hilite] unless options[:hilite]

    if view
      page_title = options[:title] || title.cap_first
      tag_filter = false
      if options[:tag] && options[:tag].good
        tag_filter = { 'tags' => [], 'bool' => 'OR' }
        bool = options[:bool].normalize_bool
        tag_filter['bool'] = bool
        tag_filter['tags'] = if bool == :pattern
                               options[:tag]
                             else
                               options[:tag].gsub(/[, ]+/, ' ').split(' ').map(&:strip)
                             end
        options[:tags] = nil
        options[:bool] = bool
      elsif options[:tags]
        tag_filter = { 'tags' => [], 'bool' => 'OR' }
        bool = options[:bool] ? options[:bool].normalize_bool : :pattern
        tag_filter['bool'] = bool
        tag_filter['tags'] = if options[:tags].instance_of?(Array)
                               bool == :pattern ? options[:tags].join(' ').strip : options[:tags].map(&:strip)
                             else
                               bool == :pattern ? options[:tags].strip : options[:tags].gsub(/[, ]+/, ' ').split(' ').map(&:strip)
                             end
        options[:tags] = nil
        options[:bool] = bool
      end

      section = options[:section] || Doing.setting('current_section')
      order = options[:order]&.normalize_order || :asc
      totals = options[:totals] || false
      tag_order = options[:tag_order]&.normalize_order || :asc
      output_format = options[:output]&.downcase || 'template'

      options[:times] = true if totals

      options.rename_key(:tag_sort, :sort_tags)
      options[:sort_tags] ||= :name
      options.rename_key(:date_format, :format)
      options.rename_key(:color, :highlight)
      search = nil

      if options[:search]
        search = options[:search]
        search.sub!(/^'?/, "'") if options[:exact]
      end

      options[:age] ||= :newest

      opts = options.clone

      opts[:count] ||= 10
      opts[:order] = order
      opts[:output] = options[:interactive] ? nil : options[:output]
      opts[:output] = output_format
      opts[:page_title] = page_title
      opts[:search] = search
      opts[:section] = section
      opts[:tag_filter] = tag_filter
      opts[:tag_order] = tag_order
      opts[:totals] = totals
      opts[:view_template] = title

      Doing::Pager.page @wwid.list_section(opts)
    elsif title.instance_of?(FalseClass)
      raise UserCancelled, 'Cancelled'
    else
      raise InvalidView, "View #{title} not found in config"
    end
  end
end
