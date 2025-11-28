# frozen_string_literal: true

# @@tags
desc 'List all tags in the current Doing file'
arg_name 'MAX_COUNT', optional: true, type: Integer
command :tags do |c|
  c.desc 'Section'
  c.arg_name 'SECTION_NAME'
  c.flag %i[s section], default_value: 'All', multiple: true

  c.desc 'Show count of occurrences'
  c.switch %i[c counts]

  c.desc 'Output in a single line with @ symbols. Ignored if --counts is specified.'
  c.switch %i[l line]

  c.desc 'Sort by name or count'
  c.arg_name 'SORT_ORDER'
  c.flag %i[sort], default_value: 'name', must_match: /^(?:n(?:ame)?|c(?:ount)?)$/

  c.desc 'Sort order (asc/desc)'
  c.arg_name 'ORDER'
  c.flag %i[o order], must_match: REGEX_SORT_ORDER, default_value: :asc, type: OrderSymbol

  c.desc 'Select items to scan from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

  add_options(:search, c)
  add_options(:tag_filter, c)

  c.action do |_global, options, args|
    @wwid.guess_section(options[:section]) || options[:section].cap_first
    options[:count] = args.count.positive? ? args[0].to_i : 0

    items = @wwid.filter_items([], opt: options)

    if options[:interactive]
      items = Doing::Prompt.choose_from_items(items, include_section: options[:section].nil?,
                                                     menu: true,
                                                     header: '',
                                                     prompt: 'Select entries to scan > ',
                                                     multiple: true,
                                                     sort: true,
                                                     show_if_single: true)
    end

    # items = @wwid.content.in_section(section)
    tags = @wwid.all_tags(items, counts: true)

    tags = if options[:sort] =~ /^n/i
             tags.sort_by { |tag, _count| tag }
           else
             tags.sort_by { |_tag, count| count }
           end

    tags.reverse! if options[:order] == :desc

    if options[:counts]
      tags.each { |t, c| puts "#{t} (#{c})" }
    elsif options[:line]
      puts tags.map { |t, _c| t }.to_tags.join(' ')
    else
      tags.each { |t, _| puts t }
    end
  end
end
