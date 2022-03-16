# @@tag_dir
desc 'Set the default tags for the current directory'
long_desc 'Adds default_tags to a .doingrc file in the current directory. Any entry created in this directory or its
subdirectories will be tagged with the default tags. You can modify these any time using the `config set` commnand or
manually editing the .doingrc file.'
arg_name 'TAG [TAG..]'
command :tag_dir do |c|
  c.example 'doing tag_dir project1 project2', desc: 'Add @project1 and @project2 to to any entries created from the current directory'
  c.example 'doing tag_dir --clear', desc: 'Clear the default tags for the directory'

  c.desc 'Remove all default_tags from the local .doingrc'
  c.switch %i[clear], negatable: false

  c.desc 'Delete tag(s) from the current list'
  c.switch %i[r remove], negatable: false

  c.desc 'Use default editor to edit tag list'
  c.switch %i[e editor], negatable: false

  c.action do |global, options, args|
    if args.empty? && !options[:clear] && !options[:editor]
      all_tags = @wwid.content.all_tags
      $stderr.puts Doing::Color.boldwhite('Enter tags separated by spaces, tab to complete')
      input = Doing::Prompt.read_line(prompt: "Tags to #{options[:remove] ? 'remove' : 'add'}", completions: all_tags)
      tags = input.split_tags
    else
      tags = args.join(' ').split_tags
    end

    cfg_cmd = commands[:config]
    set_cmd = cfg_cmd.commands[:set]

    set_options = { local: true }

    if options[:clear]
      set_args = ['default_tags']
      set_options[:remove] = true
    else
      unless options[:remove]
        current_tags = Doing.setting('default_tags')

        tags.delete_if do |tag|
          if current_tags.include?(tag)
            Doing.logger.info('Skipped:', "#{tag} is already applied by existing config")
            true
          else
            false
          end
        end

        raise EmptyInput, 'No new tags provided' if tags.empty? && !options[:editor]

      end

      if File.exist?('.doingrc')
        local = Doing::Util.safe_load_file('.doingrc')
        dir_tags = local['default_tags'] || []

        if options[:remove]
          tags.each { |tag| dir_tags.delete(tag) }
          tags = dir_tags.sort
        else
          tags.concat(dir_tags)
          tags.sort!.uniq!
        end

        if tags == dir_tags.sort && !options[:remove] && !options[:editor]
          raise UserCancelled, 'Tag(s) already exist for directory'

        end

      end

      if options[:editor]
        input = @wwid.fork_editor(tags.join(' '), message: '# Enter tags separated by spaces')
        input_lines = input.split(/[\n\r]+/).delete_if(&:ignore?)
        edited = input_lines[0]&.strip

        tags = edited.nil? ? [] : edited.split_tags
      end

      set_args = ['default_tags', tags.join(',')]
    end
    action = set_cmd.send(:get_action, nil)
    action.call(global, set_options, set_args)
  end
end
