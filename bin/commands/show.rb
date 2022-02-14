# @@show
desc 'List all entries'
long_desc %(
  The argument can be a section name, @tag(s) or both.
  "pick" or "choose" as an argument will offer a section menu. Run with `--menu` to get a menu of available tags.

  Show tags by passing @tagname arguments. Multiple tags can be combined, and you can specify the boolean used to
  combine them with `--bool (AND|OR|NOT)`. You can also use @+tagname to require a tag to match, or @-tagname to ignore
  entries containing tagname. +/- operators require `--bool PATTERN` (which is the default).
)
arg_name '[SECTION|@TAGS]'
command :show do |c|
  c.example 'doing show Currently', desc: 'Show entries in the Currently section'
  c.example 'doing show @project1', desc: 'Show entries tagged @project1'
  c.example 'doing show Later @doing', desc: 'Show entries from the Later section tagged @doing'
  c.example 'doing show @oracle @writing --bool and', desc: 'Show entries tagged both @oracle and @writing'
  c.example 'doing show Currently @devo --bool not', desc: 'Show entries in Currently NOT tagged @devo'
  c.example 'doing show Ideas @doing --from "mon to fri"', desc: 'Show entries tagged @doing from the Ideas section added between monday and friday of the current week.'
  c.example 'doing show --interactive Later @doing', desc: 'Create a menu from entries from the Later section tagged @doing to perform batch actions'

  c.desc 'Max count to show'
  c.arg_name 'MAX'
  c.flag %i[c count], default_value: 0, must_match: /^\d+$/, type: Integer

  c.desc 'Age (oldest|newest)'
  c.arg_name 'AGE'
  c.flag %i[a age], default_value: :newest, type: AgeSymbol

  c.desc "Highlight search matches in output. Only affects command line output"
  c.switch %i[h hilite], default_value: @settings.dig('search', 'highlight')

  c.desc 'Sort order (asc/desc)'
  c.arg_name 'ORDER'
  c.flag %i[s sort], must_match: REGEX_SORT_ORDER, default_value: :asc, type: OrderSymbol

  c.desc 'Show time intervals on @done tasks'
  c.switch %i[t times], default_value: true, negatable: true

  c.desc 'Show elapsed time on entries without @done tag'
  c.switch [:duration]

  c.desc 'Show intervals with totals at the end of output'
  c.switch [:totals], default_value: false, negatable: false

  c.desc 'Sort tags by (name|time)'
  default = @settings['tag_sort'].normalize_tag_sort || :name
  c.arg_name 'KEY'
  c.flag [:tag_sort], must_match: REGEX_TAG_SORT, default_value: default, type: TagSortSymbol

  c.desc 'Tag sort direction (asc|desc)'
  c.arg_name 'DIRECTION'
  c.flag [:tag_order], must_match: REGEX_SORT_ORDER, default_value: :asc, type: OrderSymbol

  c.desc 'Only show items with recorded time intervals'
  c.switch [:only_timed], default_value: false, negatable: false

  c.desc "Output using a template from configuration"
  c.arg_name 'TEMPLATE_KEY'
  c.flag [:config_template], type: TemplateName, default_value: 'default'

  c.desc 'Override output format with a template string containing %placeholders'
  c.arg_name 'TEMPLATE_STRING'
  c.flag [:template]

  c.desc 'Select section or tag to display from a menu'
  c.switch %i[m menu], negatable: false, default_value: false

  c.desc 'Select from a menu of matching entries to perform additional operations'
  c.switch %i[i interactive], negatable: false, default_value: false

  c.desc "Output to export format (#{Doing::Plugins.plugin_names(type: :export)})"
  c.arg_name 'FORMAT'
  c.flag %i[o output]

  add_options(:search, c)
  add_options(:tag_filter, c)
  add_options(:date_filter, c)

  c.action do |global_options, options, args|
    options[:fuzzy] = false
    if options[:output] && options[:output] !~ Doing::Plugins.plugin_regex(type: :export)
      raise DoingRuntimeError, %(Invalid output type "#{options[:output]}")

    end

    tag_filter = false
    tags = []

    if args.length.positive?
      case args[0]
      when /^all$/i
        section = 'All'
        args.shift
      when /^(choose|pick)$/i
        section = @wwid.choose_section(include_all: true)

        args.shift
      when /^[@+-]/
        section = 'All'
      else
        begin
          section = @wwid.guess_section(args[0])
        rescue WrongCommand
          cmd = commands[:view]
          action = cmd.send(:get_action, nil)
          return action.call(global_options, options, args)
        end

        raise InvalidSection, "No such section: #{args[0]}" unless section

        args.shift
      end
      if args.length.positive?
        args.each do |arg|
          arg.split(/,/).each do |tag|
            tags.push(tag.strip.sub(/^@/, ''))
          end
        end
      end
    else
      section = options[:menu] ? @wwid.choose_section(include_all: true) : @settings['current_section']
      section ||= 'All'
    end

    tags.concat(options[:tag]) if options[:tag]

    options[:times] = true if options[:totals]

    template = @settings['templates'][options[:config_template]].deep_merge({
                                                    'wrap_width' => @settings['wrap_width'] || 0,
                                                    'date_format' => @settings['default_date_format'],
                                                    'order' => @settings['order']&.normalize_order || :asc,
                                                    'tags_color' => @settings['tags_color']
                                                  })

    if options[:search]
      search = options[:search]
      search.sub!(/^'?/, "'") if options[:exact]
      options[:search] = search
    end

    options[:section] = section

    if tags.good?
      tag_filter = {
        'tags' => tags,
        'bool' => options[:bool]
      }
    end

    options[:tag_filter] = tag_filter
    options[:tag] = nil

    items = @wwid.filter_items([], opt: options)

    if options[:menu]
      Doing.logger.benchmark(:menu, :start)
      tag = @wwid.choose_tag(section, items: items, include_all: true)
      raise UserCancelled unless tag

      tags = tag.split(/ +/).map { |t| t.strip.sub(/^@?/, '') } if tag =~ /^@/
      if tags.good?
        tag_filter = {
          'tags' => tags,
          'bool' => options[:bool]
        }
        options[:tag_filter] = tag_filter
      end
      Doing.logger.benchmark(:menu, :finish)
    end

    options[:age] ||= :newest

    opt = options.clone
    opt[:sort_tags] = options[:tag_sort]
    opt[:count] = options[:count].to_i
    opt[:highlight] = true
    opt[:hilite] = options[:hilite]
    opt[:order] = options[:sort]
    opt[:tag] = nil
    opt[:tags_color] = template['tags_color']

    Doing::Pager.page @wwid.list_section(opt, items: items)
  end
end
