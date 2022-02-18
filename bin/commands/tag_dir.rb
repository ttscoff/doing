# @@tag_dir
desc 'Set the default tags for the current directory'
long_desc 'Adds default_tags to a .doingrc file in the current directory. Any entry created in this directory or its
subdirectories will be tagged with the default tags. You can modify these any time using the `config set` commnand or
manually editing the .doingrc file.'
arg_name 'TAG [TAG..]'
command :tag_dir do |c|
  c.example 'doing tag_dir project1 project2', desc: 'Add @project1 and @project2 to to any entries created from the current directory'
  c.example 'doing tag_dir --remove', desc: 'Clear the default tags for the directory'

  c.desc 'Remove all default_tags from the local .doingrc'
  c.switch %i[r remove], negatable: false

  c.action do |global, options, args|
    tags = args.join(' ').gsub(/ *, */, ' ').split(' ')

    cfg_cmd = commands[:config]
    set_cmd = cfg_cmd.commands[:set]

    set_options = { local: true }
    if options[:remove]
      set_args = ['default_tags']
      set_options[:remove] = true
    else
      current_tags = Doing.setting('default_tags')

      tags.delete_if do |tag|
        if current_tags.include?(tag)
          Doing.logger.info('Skipped:', "#{tag} is already applied by existing config")
          true
        else
          false
        end
      end

      raise EmptyInput, 'No new tags provided' if tags.empty?

      if File.exist?('.doingrc')
        local = Doing::Util.safe_load_file('.doingrc')
        dir_tags = local['default_tags'] || []

        tags.concat(dir_tags)
        tags.sort!.uniq!

        raise UserCancelled, 'Tag(s) already exist for directory' if tags == dir_tags.sort
      end

      set_args = ['default_tags', tags.join(',')]
    end
    action = set_cmd.send(:get_action, nil)
    action.call(global, set_options, set_args)
  end
end
