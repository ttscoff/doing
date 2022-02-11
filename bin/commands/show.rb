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

  c.desc 'Tag filter, combine multiple tags with a comma. Use `--tag pick` for a menu of available tags. Wildcards allowed (*, ?). Added for compatibility with other commands'
  c.arg_name 'TAG'
  c.flag [:tag], type: TagArray

  c.desc 'Perform a tag value query ("@done > two hours ago" or "@progress < 50"). May be used multiple times, combined with --bool'
  c.arg_name 'QUERY'
  c.flag [:val], multiple: true, must_match: REGEX_VALUE_QUERY

  c.desc 'Tag boolean (AND,OR,NOT). Use PATTERN to parse + and - as booleans'
  c.arg_name 'BOOLEAN'
  c.flag [:bool], must_match: REGEX_BOOL,
                  default_value: :pattern,
                  type: BooleanSymbol

  c.desc 'Max count to show'
  c.arg_name 'MAX'
  c.flag %i[c count], default_value: 0, must_match: /^\d+$/, type: Integer

  c.desc 'Age (oldest|newest)'
  c.arg_name 'AGE'
  c.flag %i[a age], default_value: :newest, type: AgeSymbol

  c.desc 'Show entries older than date. If this is only a time (8am, 1:30pm, 15:00), all dates will be included, but entries will be filtered by time of day'
  c.arg_name 'DATE_STRING'
  c.flag [:before], type: DateBeginString

  c.desc 'Show entries newer than date. If this is only a time (8am, 1:30pm, 15:00), all dates will be included, but entries will be filtered by time of day'
  c.arg_name 'DATE_STRING'
  c.flag [:after], type: DateEndString

  c.desc %(
      Date range to show, or a single day to filter date on.
      Date range argument should be quoted. Date specifications can be natural language.
      To specify a range, use "to" or "through": `doing show --from "monday 8am to friday 5pm"`.

      If values are only time(s) (6am to noon) all dates will be included, but entries will be filtered
      by time of day.
    )

  c.arg_name 'DATE_OR_RANGE'
  c.flag [:from], type: DateRangeString

  c.desc 'Search filter, surround with slashes for regex (/query/), start with single quote for exact match ("\'query")'
  c.arg_name 'QUERY'
  c.flag [:search]

  c.desc "Highlight search matches in output. Only affects command line output"
  c.switch %i[h hilite], default_value: @settings.dig('search', 'highlight')

  # c.desc '[DEPRECATED] Use alternative fuzzy matching for search string'
  # c.switch [:fuzzy], default_value: false, negatable: false

  c.desc 'Force exact search string matching (case sensitive)'
  c.switch %i[x exact], default_value: @config.exact_match?, negatable: @config.exact_match?

  c.desc 'Show items that *don\'t* match search/tag/date filters'
  c.switch [:not], default_value: false, negatable: false

  c.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
  c.arg_name 'TYPE'
  c.flag [:case], must_match: REGEX_CASE,
                  default_value: @settings.dig('search', 'case').normalize_case,
                  type: CaseSymbol

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
