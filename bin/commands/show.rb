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

  c.desc "Highlight search matches in output. Only affects command line output"
  c.switch %i[h hilite], default_value: Doing.settings.dig('search', 'highlight')

  c.desc "Edit matching entries with #{Doing::Util.default_editor}"
  c.switch %i[e editor], negatable: false, default_value: false

  c.desc 'Age (oldest|newest)'
  c.arg_name 'AGE'
  c.flag %i[a age], default_value: :newest, type: AgeSymbol

  c.desc 'Sort order (asc/desc)'
  c.arg_name 'ORDER'
  c.flag %i[sort], must_match: REGEX_SORT_ORDER, default_value: :asc, type: OrderSymbol

  c.desc 'Only show entries within section'
  c.arg_name 'NAME'
  c.flag %i[s section], multiple: true

  c.desc 'Select section or tag to display from a menu'
  c.switch %i[m menu], negatable: false, default_value: false

  c.desc 'Select from a menu of matching entries to perform additional operations'
  c.switch %i[i interactive], negatable: false, default_value: false

  add_options(:output_template, c)
  add_options(:time_display, c)
  add_options(:search, c)
  add_options(:tag_filter, c)
  add_options(:date_filter, c)
  add_options(:save, c)

  c.action do |global_options, options, args|
    options[:fuzzy] = false
    if options[:output] && options[:output] !~ Doing::Plugins.plugin_regex(type: :export)
      raise InvalidPlugin.new('output', options[:output])

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
        section = options[:section] ? @wwid.guess_section(options[:section]) : 'All'
      else
        sect = options[:section].empty? ? args[0] : options[:section]

        begin
          section = @wwid.guess_section(sect)
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
      if options[:section] && !options[:section].empty?
        section = @wwid.guess_section(options[:section]) || 'All'
      else
        section = options[:menu] ? @wwid.choose_section(include_all: true) : Doing.setting('current_section')
      end
      section ||= 'All'
    end

    tags.concat(options[:tag]) if options[:tag]

    options[:times] = true if options[:totals]

    template = Doing.setting(['templates', options[:config_template]]).deep_merge({
                                                    'wrap_width' => Doing.setting('wrap_width') || 0,
                                                    'date_format' => Doing.setting('default_date_format'),
                                                    'order' => Doing.setting('order')&.normalize_order || :asc,
                                                    'tags_color' => Doing.setting('tags_color')
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

    if options[:save]
      opt[:before] = Doing.original_options[:date_begin] if Doing.original_options[:date_begin].good?
      opt[:after] = Doing.original_options[:date_end] if Doing.original_options[:date_end].good?
      opt[:from] = Doing.original_options[:date_range] if Doing.original_options[:date_range].good?
      Doing.config.save_view(opt.to_view, options[:save].downcase)
    end
  end
end
