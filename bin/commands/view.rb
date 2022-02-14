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

  c.desc "Output to export format (#{Doing::Plugins.plugin_names(type: :export)})"
  c.arg_name 'FORMAT'
  c.flag %i[o output]

  c.desc 'Age (oldest|newest)'
  c.arg_name 'AGE'
  c.flag %i[age], default_value: :newest, type: AgeSymbol

  c.desc 'Show time intervals on @done tasks'
  c.switch %i[t times], default_value: true, negatable: true

  c.desc 'Show elapsed time on entries without @done tag'
  c.switch [:duration]

  c.desc 'Show intervals with totals at the end of output'
  c.switch [:totals], default_value: false, negatable: false

  c.desc 'Include colors in output'
  c.switch [:color], default_value: true, negatable: true

  c.desc "Highlight search matches in output. Only affects command line output"
  c.switch %i[h hilite], default_value: @settings.dig('search', 'highlight')

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
  add_options(:tag_filter, c)
  add_options(:date_filter, c)

  c.action do |global_options, options, args|
    options[:fuzzy] = false
    if options[:output] && options[:output] !~ Doing::Plugins.plugin_regex(type: :export)
      raise DoingRuntimeError, %(Invalid output type "#{options[:output]}")

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
                @settings['current_section']
              end

    view = @wwid.get_view(title)

    if view
      page_title = view['title'] || title.cap_first
      only_timed = if (view.key?('only_timed') && view['only_timed']) || options[:only_timed]
                     true
                   else
                     false
                   end

      template = view['template'] || nil
      date_format = view['date_format'] || nil

      tags_color = view['tags_color'] || nil
      tag_filter = false
      if options[:tag]
        tag_filter = { 'tags' => [], 'bool' => 'OR' }
        bool = options[:bool]
        tag_filter['bool'] = bool
        tag_filter['tags'] = if bool == :pattern
                               options[:tag]
                             else
                               options[:tag].gsub(/[, ]+/, ' ').split(' ').map(&:strip)
                             end
      elsif view.key?('tags') && view['tags'].good?
        tag_filter = { 'tags' => [], 'bool' => 'OR' }
        bool = view.key?('tags_bool') && !view['tags_bool'].nil? ? view['tags_bool'].normalize_bool : :pattern
        tag_filter['bool'] = bool
        tag_filter['tags'] = if view['tags'].instance_of?(Array)
                               bool == :pattern ? view['tags'].join(' ').strip : view['tags'].map(&:strip)
                             else
                               bool == :pattern ? view['tags'].strip : view['tags'].gsub(/[, ]+/, ' ').split(' ').map(&:strip)
                             end
      end

      # If the -o/--output flag was specified, override any default in the view template
      options[:output] ||= view.key?('output_format') ? view['output_format'] : 'template'

      count = if options[:count]
                options[:count]
              elsif view.key?('count')
                view['count']
              else
                10
              end

      section = if options[:section]
                  section
                else
                  view['section'] || @settings['current_section']
                end
      order = if view.key?('order')
                view['order'].normalize_order
              else
                :asc
              end

      totals = if options[:totals]
                 true
               else
                 view['totals'] || false
               end
      tag_order = options[:tag_order] || view['tag_order']&.normalize_order || :asc

      options[:times] = true if totals
      output_format = options[:output]&.downcase || 'template'

      options[:sort_tags] = if options[:tag_sort]
                              options[:tag_sort]
                            elsif view.key?('tag_sort')
                              view['tag_sort'].normalize_tag_sort
                            else
                              false
                            end

      %w[before after from duration].each { |k| options[k.to_sym] = view[k] if view.key?(k) && !options[k.to_sym] }

      search = nil

      if options[:search]
        search = options[:search]
        search.sub!(/^'?/, "'") if options[:exact]
      end

      options[:age] ||= :newest

      opts = options.clone
      opts[:age] = options[:age]
      opts[:count] = count
      opts[:format] = date_format
      opts[:highlight] = options[:color]
      opts[:hilite] = options[:hilite]
      opts[:only_timed] = only_timed
      opts[:order] = order
      opts[:output] = options[:interactive] ? nil : options[:output]
      opts[:output] = output_format
      opts[:page_title] = page_title
      opts[:search] = search
      opts[:section] = section
      opts[:tag_filter] = tag_filter
      opts[:tag_order] = tag_order
      opts[:tags_color] = tags_color
      opts[:template] = template
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
