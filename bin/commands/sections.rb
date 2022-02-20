# frozen_string_literal: true

# @@add_section
desc 'List, add, or remove sections in the Doing file'
command :sections do |c|
  c.default_command :list

  c.example 'doing sections add Ideas', desc: 'Add a section called Ideas to the doing file'
  c.example 'doing sections remove Reminders', desc: 'Remove the section Reminders'
  c.example 'doing sections list', desc: 'List all sections'

  c.desc 'Add a section'
  c.arg_name 'SECTION_NAME'
  c.command :add do |add|
    add.action do |_g, _o, args|
      raise InvalidArgument, "Section #{args[0]} already exists" if @wwid.sections.include?(args[0])

      @wwid.content.add_section(args.join(' ').cap_first, log: true)
      @wwid.write(@wwid.doing_file)
    end
  end

  c.desc 'List sections'
  c.command :list do |list|
    list.desc 'List in single column'
    list.switch %i[c column], negatable: false, default_value: false

    list.action do |_global_options, options, _args|
      joiner = options[:column] ? "\n" : "\t"
      print @wwid.content.section_titles.join(joiner)
    end
  end

  c.desc 'Remove a section'
  c.arg_name 'SECTION_NAME'
  c.command :remove do |remove|
    remove.desc 'Archive entries in section before deleting. --no-archive permanently deletes section contents'
    remove.switch %i[a archive], default_value: true, negatable: true

    remove.action do |_g, options, args|
      raise InvalidArgument, '--delete cannot be used with --archive' if options[:delete] && options[:archive]

      section = args[0].cap_first

      unless @wwid.sections.include?(section)
        Doing.logger.log_now(:warn, 'Section:', "#{section} not found, did you mean #{guess_section(section)}?")
        raise InvalidArgument, "Section #{args[0]} doesn't exist"

      end

      items = @wwid.content.in_section(section)

      if items.count.positive?
        res = Doing::Prompt.yn("#{options[:archive] ? 'Archive' : 'Delete'} #{items.count} entries from #{section}", default_response: 'n')

        if options[:archive] && res
          @wwid.archive(section, {keep: 0})
        elsif res
          items.each { |item| @wwid.content.delete_item(item) }
        end
      end

      @wwid.content.delete_section(section, log: true)

      @wwid.write(@wwid.doing_file)
    end
  end
end

# For backward compatibility
# @@add_section
command :add_section do |c|
  c.desc 'Archive entries in section before deleting'
  c.switch %i[a archive], default_value: true, negatable: true

  c.desc 'Permanently delete entries in section'
  c.switch %i[d delete], default_value: false

  c.action do |g, o, a|
    cmd = commands[:sections].commands[:add]

    action = cmd.send(:get_action, nil)
    action.call(g, o, a)
  end
end

