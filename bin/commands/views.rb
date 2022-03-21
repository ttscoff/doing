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
  c.switch %i[c column], default_value: false, negatable: false

  c.desc 'Open YAML for view in editor (requires argument)'
  c.switch %i[e editor], negatable: false

  c.desc 'Output/edit view in alternative format (json, yaml)'
  c.arg_name 'FORMAT'
  c.flag %i[o output], must_match: /^[jy]/i, default_value: 'yaml'

  c.desc 'Delete view config'
  c.switch %i[r remove], negatable: false

  c.action do |_global_options, options, args|
    cmd = Doing::ViewsCommand.new(options, args, @wwid)

    if args.count.positive?
      if options[:remove]
        cmd.remove_views
      elsif options[:editor]
        cmd.edit_views
      else
        cmd.output_views
      end
    else
      cmd.list_views
    end
  end
end

module Doing
  # views Command
  class ViewsCommand
    def initialize(options, args, wwid)
      @options = options
      @args = args
      @wwid = wwid

      @views = {}
      args.each do |v|
        view = @wwid.get_view(v)
        raise InvalidArgument, 'Unrecognized view' unless view

        @views[v] = view if view
      end
    end

    def list_views
      joiner = @options[:column] ? "\n" : "\t"
      print @wwid.views.join(joiner)
    end

    def save_view(view, res)
      val = if res.nil? || !res.key?(view) || res[view]&.empty?
              nil
            else
              res[view]
            end

      Doing.set("views.#{view}", val)
    end

    def remove_views
      @args.each do |v|
        Doing.set("views.#{v}", nil)
      end

      save_config
    end

    def edit_views
      res = if @options[:output] =~ /^j/i
              JSON.parse(@wwid.fork_editor(JSON.pretty_generate(@views), message: nil))
            else
              YAML.safe_load(@wwid.fork_editor(YAML.dump(@views), message: nil))
            end
      @args.each do |v|
        save_view(v, res)
      end
      save_config
    end

    def output_views
      out = if @options[:output] =~ /^j/i
              JSON.pretty_generate(@views)
            else
              YAML.dump(@views)
            end

      Doing::Pager.page out
    end

    def save_config
      Doing::Util.write_to_file(Doing.config.config_file, YAML.dump(Doing.settings), backup: true)
      Doing.logger.warn('Config:', "#{Doing.config.config_file} updated")
    end
  end
end
