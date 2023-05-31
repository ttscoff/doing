# frozen_string_literal: true

# @@archive @@move
desc 'Move entries between sections'
long_desc %(Argument can be a section name to move all entries from a section,
or start with an "@" to move entries matching a tag.

Default with no argument moves items from the "#{Doing.setting('current_section')}" section to Archive.)
arg_name 'SECTION_OR_TAG'
default_value Doing.setting('current_section')
command %i[archive move] do |c|
  c.example 'doing archive Currently', desc: 'Move all entries in the Currently section to Archive section'
  c.example 'doing archive @done', desc: 'Move all entries tagged @done to Archive'
  c.example 'doing archive --to Later @project1', desc: 'Move all entries tagged @project1 to Later section'
  c.example 'doing move Later --tag project1 --to Currently',
            desc: 'Move entries in Later tagged @project1 to Currently (move is an alias for archive)'

  c.desc 'How many items to keep (ignored if archiving by tag or search)'
  c.arg_name 'X'
  c.flag %i[k keep], must_match: /^\d+$/, type: Integer

  c.desc 'Move entries to'
  c.arg_name 'SECTION_NAME'
  c.flag %i[t to], default_value: 'Archive'

  c.desc 'Label moved items with @from(SECTION_NAME)'
  c.switch [:label], default_value: true, negatable: true

  add_options(:search, c)
  add_options(:tag_filter, c)
  add_options(:date_filter, c)

  c.action do |_global_options, options, args|
    options[:fuzzy] = false
    section, tags = if args.empty?
                      [Doing.setting('current_section'), []]
                    elsif args[0] =~ /^all/i
                      ['all', []]
                    elsif args[0] =~ /^@\S+/
                      ['all', args.tags_to_array]
                    else
                      [@wwid.guess_section(args.shift.cap_first), args.tags_to_array]
                    end

    raise InvalidArgument, '--keep and --count can not be used together' if options[:keep] && options[:count]

    tags.concat(options[:tag]) if options[:tag]

    options[:search] = options[:search].sub(/^'?/, "'") if options[:search] && options[:exact]
    options[:destination] = options[:to]
    options[:tags] = tags

    @wwid.archive(section, options)
  end
end
