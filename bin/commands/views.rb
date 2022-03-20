# @@views
desc 'List available custom views. Specify view names to see YAML configurations.'
arg_name 'NAME(S)', optional: true
command :views do |c|
  c.example 'doing views', desc: 'list all views'
  c.example 'doing views -c', desc: 'list views in column, ideal for shell completion'
  c.example 'doing views color', desc: 'dump the YAML for a single view'
  c.example 'doing views -e color', desc: 'edit the YAML configuration for a single view'
  c.example 'doing views -e -o json color finished', desc: 'edit multiple view configs as JSON'

  c.desc 'List in single column'
  c.switch %i[c column], default_value: false

  c.desc 'Open YAML for view in editor (requires argument)'
  c.switch %i[e editor]

  c.desc 'Output/edit view in alternative format (json, yaml)'
  c.arg_name 'FORMAT'
  c.flag %i[o output], must_match: /^[jy]/i, default_value: 'yaml'

  c.action do |_global_options, options, args|
    if args.count.positive?
      views = {}
      args.each { |v| views[v] = @wwid.get_view(v) }

      if options[:editor]
        res = if options[:output] =~ /^j/i
                JSON.parse(@wwid.fork_editor(JSON.pretty_generate(views), message: nil))
              else
                YAML.safe_load(@wwid.fork_editor(YAML.dump(views), message: nil))
              end
        args.each { |v| Doing.set("views.#{v}", res[v]) }
        Doing::Util.write_to_file(Doing.config.config_file, YAML.dump(Doing.settings), backup: true)
        Doing.logger.warn('Config:', "#{Doing.config.config_file} updated")
      elsif options[:output] =~ /^j/i
        out = JSON.pretty_generate(views)
        Doing::Pager.page out
      else
        out = YAML.dump(views)
        Doing::Pager.page out
      end
    else
      joiner = options[:column] ? "\n" : "\t"
      print @wwid.views.join(joiner)
    end
  end
end
