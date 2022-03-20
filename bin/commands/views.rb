# @@views
desc 'List available custom views. Specify a single view to see its YAML configuration.'
command :views do |c|
  c.desc 'List in single column'
  c.switch %i[c column], default_value: false

  c.desc 'Open YAML for view in editor (requires argument)'
  c.switch %i[e editor]

  c.action do |_global_options, options, args|
    if args.count.positive?
      views = {}
      args.each { |v| views[v] = @wwid.get_view(v) }

      if options[:editor]
        res = YAML.safe_load(@wwid.fork_editor(YAML.dump(views), message: nil))
        args.each { |v| Doing.set("views.#{v}", res[v]) }
        Doing::Util.write_to_file(Doing.config.config_file, YAML.dump(Doing.settings), backup: true)
        Doing.logger.warn('Config:', "#{Doing.config.config_file} updated")
      else
        print YAML.dump(views)
      end
    else
      joiner = options[:column] ? "\n" : "\t"
      print @wwid.views.join(joiner)
    end
  end
end
