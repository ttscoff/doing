# frozen_string_literal: true

module Doing
  ##
  ## Configuration object
  ##
  class Configuration
    attr_reader :settings

    attr_writer :ignore_local, :config_file, :force_answer

    def force_answer
      @force_answer ||= false
    end

    MissingConfigFile = Class.new(RuntimeError)

    DEFAULTS = {
      'autotag' => {
        'whitelist' => [],
        'synonyms' => {}
      },
      'editors' => {
        'default' => ENV['DOING_EDITOR'] || ENV['GIT_EDITOR'] || ENV['EDITOR'],
        'doing_file' => nil,
        'config' => nil,
        'pager' => nil
      },
      'plugins' => {
        'plugin_path' => File.join(Util.user_home, '.config', 'doing', 'plugins'),
        'command_path' => File.join(Util.user_home, '.config', 'doing', 'commands')
      },
      'disabled_commands' => [],
      'doing_file' => '~/.local/share/doing/what_was_i_doing.md',
      'doing_file_sort' => 'desc',
      'backup_dir' => '~/.local/share/doing/doing_backup',
      'history_size' => 15,
      'current_section' => 'Currently',
      'paginate' => false,
      'never_time' => [],
      'never_finish' => [],
      'date_tags' => ['done', 'defer(?:red)?', 'waiting'],

      'timer_format' => 'text',
      'interval_format' => 'text',

      'order' => 'asc',

      'shortdate_format' => {
        'today' => '%_I:%M%P',
        'this_week' => '%a %_I:%M%P',
        'this_month' => '%m/%d %_I:%M%P',
        'older' => '%m/%d/%y %_I:%M%P'
      },

      'templates' => {
        'default' => {
          'date_format' => '%Y-%m-%d %H:%M',
          'template' => '%reset%cyan%shortdate %boldwhite%80║ title %boldmagenta[%boldwhite%-10section%boldmagenta]%reset %yellow%interval%boldred%duration%white%80_14┃ note',
          'wrap_width' => 0,
          'order' => 'asc'
        },
        'today' => {
          'date_format' => '%_I:%M%P',
          'template' => '%date: %title %interval%duration%note',
          'wrap_width' => 0,
          'order' => 'asc'
        },
        'last' => {
          'date_format' => '%-I:%M%P on %a',
          'template' => '%title (at %date) %interval%duration%odnote',
          'wrap_width' => 88
        },
        'recent' => {
          'date_format' => '%_I:%M%P',
          'template' => '%reset%cyan%shortdate %boldwhite%80║ title %boldmagenta[%boldwhite%-10section%boldmagenta]%reset  %yellow%interval%boldred%duration%white%80_14┃ note',
          'wrap_width' => 88,
          'count' => 10,
          'order' => 'asc'
        }
      },

      'export_templates' => {},

      'views' => {
        'done' => {
          'date_format' => '%_I:%M%P',
          'template' => '%date | %title (%section)% 18: note',
          'wrap_width' => 0,
          'section' => 'All',
          'count' => 0,
          'order' => 'desc',
          'tags' => 'done complete cancelled',
          'tags_bool' => 'OR'
        },
        'color' => {
          'date_format' => '%F %_I:%M%P',
          'template' => '%boldblack%date %boldgreen| %boldwhite%title%default%note',
          'wrap_width' => 0,
          'section' => 'Currently',
          'count' => 10,
          'order' => 'asc'
        }
      },
      'marker_tag' => 'flagged',
      'marker_color' => 'red',
      'default_tags' => [],
      'tag_sort' => 'name',
      'search' => {
        'matching' => 'pattern', # fuzzy, pattern, exact
        'distance' => 3,
        'case' => 'smart', # sensitive, ignore, smart
        'highlight' => false
      },
      'include_notes' => true,
      'interaction' => {
        'confirm_longer_than' => '5h'
      }
    }.freeze

    def initialize(file = nil, options: {})
      @config_file = file.nil? ? default_config_file : File.expand_path(file)

      @settings = configure(options)
    end

    def config_file
      @config_file ||= default_config_file
    end

    def config_dir
      @config_dir ||= File.join(Util.user_home, '.config', 'doing')
    end

    ##
    ## Check if configuration enforces exact string matching
    ##
    ## @return     [Boolean] exact matching enabled
    ##
    def exact_match?
      search_settings = @settings['search']
      matching = search_settings.fetch('matching', 'pattern').normalize_matching
      matching == :exact
    end

    def default_config_file
      if File.exist?(config_dir) && !File.directory?(config_dir)
        raise DoingRuntimeError, "#{config_dir} exists but is not a directory"

      end

      unless File.exist?(config_dir)
        FileUtils.mkdir_p(config_dir)
        Doing.logger.log_now(:warn, "Config directory created at #{config_dir}")
      end

      File.join(config_dir, 'config.yml')
    end

    def additional_configs
      @additional_configs ||= find_local_config
    end

    ##
    ## Present a menu if there are multiple configs found
    ##
    ## @return     [String] file path
    ##
    def choose_config(create: false, local: false)
      if local && create
        res = File.expand_path('.doingrc')
        FileUtils.touch(res)
        return res
      end

      return @config_file if @force_answer

      if @additional_configs&.count&.positive? || create
        choices = [@config_file].concat(@additional_configs)
        choices.push('Create a new .doingrc in the current directory') if create && !File.exist?('.doingrc')
        res = Doing::Prompt.choose_from(choices.uniq.sort.reverse,
                                        sorted: false,
                                        prompt: 'Local configs found, select which to update > ')

        raise UserCancelled, 'Cancelled' unless res

        if res =~ /^Create a new/
          res = File.expand_path('.doingrc')
          FileUtils.touch(res)
        end

        res.strip || @config_file
      else
        @config_file
      end
    end

    def fetch(*path, default)
      @settings.dig(*path) || default
    end

    ##
    ## Resolve a fuzzy-matched key path
    ##
    ## @param      keypath  [String] A dot-separated key
    ##                      path, e.g.
    ##                      "plugins.plugin_path". Will also
    ##                      work with "plug.path" (fuzzy
    ##                      matched, first match wins)
    ## @return     [Array] ordered array of resolved keys
    ##
    def resolve_key_path(keypath, create: false, distance: 2, exact: false)
      cfg = @settings
      real_path = []
      unless keypath =~ /^[.*]?$/
        paths = keypath.split(/[:.]/)
        element_count = paths.count
        while paths.length.positive? && !cfg.nil?
          path = paths.shift
          new_cfg = nil

          if cfg.is_a?(Hash)
            matches = if exact
                        cfg.select { |key, _| key == path }
                      else
                        cfg.select { |key, _| key =~ path.to_rx(distance: distance) }
                      end
            if matches.count.positive?
              shortest = matches.keys.group_by(&:length).min.last[0]
              real_path << shortest
              new_cfg = matches[shortest]
            end
          else
            new_cfg = cfg
          end

          if new_cfg.nil?
            return real_path if real_path[-1] == path && real_path.count == element_count

            return resolve_key_path(keypath, create: false, distance: distance + 1) if distance < 5 && !create

            return nil unless create

            resolved = real_path.count.positive? ? "Resolved #{real_path.join('.')}, but " : ''
            Doing.logger.log_now(:warn, "#{resolved}#{path} is unknown")
            new_path = [*real_path, path, *paths].compact.join('.')
            Doing.logger.log_now(:warn, "Continuing will create the path #{new_path}")
            res = Prompt.yn('Key path not found, create it?', default_response: true)
            raise InvalidArgument, 'Invalid key path' unless res

            real_path.push(path).concat(paths).compact!
            unless keypath == real_path.join('.')
              Doing.logger.debug('Config:',
                                 "translated key path #{keypath} to #{real_path.join('.')}")
            end
            return real_path
          end
          cfg = new_cfg
        end
      end
      unless keypath == real_path.join('.')
        Doing.logger.debug('Config:',
                           "translated key path #{keypath} to #{real_path.join('.')}")
      end
      real_path
    end

    ##
    ## Get the value for a fuzzy-matched key path
    ##
    ## @param      keypath  [String] A dot-separated key
    ##                      path, e.g.
    ##                      "plugins.plugin_path". Will also
    ##                      work with "plug.path" (fuzzy
    ##                      matched, first match wins)
    ## @return     [Hash] Config value
    ##
    def value_for_key(keypath = '')
      cfg = @settings
      real_path = ['config']
      unless keypath =~ /^[.*]?$/
        real_path = resolve_key_path(keypath, create: false)
        return nil unless real_path&.count&.positive?

        cfg = cfg.dig(*real_path)
      end

      cfg.nil? ? nil : { real_path[-1] => cfg }
    end

    # It takes the input, fills in the defaults where values
    # do not exist.
    #
    # @param      user_config  a Hash or Configuration of
    #                          overrides.
    #
    # @return     [Hash] a Configuration filled with
    #             defaults.
    #
    def from(user_config)
      # Util.deep_merge_hashes(DEFAULTS, Configuration[user_config].stringify_keys)
      Configuration[user_config].stringify_keys.deep_merge(DEFAULTS,
                                                           { extend_existing_arrays: true, sort_merged_arrays: true })
    end

    ##
    ## Method for transitioning from ~/.doingrc to ~/.config/doing/config.yml
    ##
    def update_deprecated_config
      # return # Until further notice
      return if File.exist?(default_config_file)

      old_file = File.join(Util.user_home, '.doingrc')
      return unless File.exist?(old_file)

      Doing.logger.log_now(:warn, 'Deprecated:', "main config file location has changed to #{config_file}")
      res = Prompt.yn("Move #{old_file} to new location, preserving settings?", default_response: true)

      return unless res

      if File.exist?(default_config_file)
        res = Prompt.yn("#{default_config_file} already exists, overwrite it?", default_response: false)

        unless res
          @config_file = old_file
          return
        end
      end

      FileUtils.mv old_file, default_config_file, force: true
      Doing.logger.log_now(:warn, 'Config:', "Config file moved to #{default_config_file}")
      Doing.logger.log_now(:warn, 'Config:', %(If ~/.doingrc exists in the future,
                           it will be considered a local config and its values will override the
                           default configuration.))
      Process.exit 0
    end

    ##
    ## Read user configuration and merge with defaults
    ##
    ## @param      opt   [Hash] Additional Options
    ##
    def configure(opt = {})
      update_deprecated_config if config_file == default_config_file

      @ignore_local = opt[:ignore_local] if opt[:ignore_local]

      config = read_config.clone

      plugin_config = Util.deep_merge_hashes(DEFAULTS['plugins'], config['plugins'] || {})

      load_plugins(plugin_config['plugin_path'])

      Plugins.plugins.each_value do |plugins|
        plugins.each do |title, plugin|
          plugin_config[title] = plugin[:config] if plugin[:config].good?
          config['export_templates'][title] ||= nil if plugin[:templates] && !plugin[:templates].empty?
        end
      end

      config = Util.deep_merge_hashes({
                                        'plugins' => plugin_config
                                      }, config)

      config = find_deprecations(config)

      if !File.exist?(config_file) || opt[:rewrite]
        Util.write_to_file(config_file, YAML.dump(config), backup: true)
        Doing.logger.warn('Config:', "Config file written to #{config_file}")
      end

      Hooks.trigger :post_config, self

      unless @ignore_local
        config = local_config.deep_merge(config,
                                         { extend_existing_arrays: true, sort_merged_arrays: true })
      end
      # config = Util.deep_merge_hashes(config, local_config) unless @ignore_local

      Hooks.trigger :post_local_config, self

      config
    end

    ##
    ## Save a set of options to the `views` configuration
    ##
    ## @param      view   [Hash] view options
    ## @param      title  [String] view title
    ##
    def save_view(view, title)
      title.downcase!
      default_template = Doing.setting('templates.default')
      user_config = Util.safe_load_file(config_file)
      user_config['views'] = {} unless user_config.key?('views')

      view.delete_if { |k, v| v == default_template[k] }

      user_config['views'][title] = view
      Util.write_to_file(config_file, YAML.dump(user_config), backup: true)
      Doing.logger.warn('Config:', %(View "#{title}" saved to #{config_file}))
      Doing.logger.info('Config:', %(to use, run `doing view #{title}`))
      Hooks.trigger :post_config, self
    end

    # @private
    def inspect
      %(<Doing::Configuration #{@settings.hash}>)
    end

    # @private
    def to_s
      YAML.dump(@settings)
    end

    private

    ##
    ## Test for deprecated config keys
    ##
    ## @param      config  The configuration
    ##
    def find_deprecations(config)
      deprecated = false
      if config.key?('editor')
        deprecated = true
        config['editors']['default'] ||= config['editor']
        config.delete('editor')
        Doing.logger.debug('Deprecated:', "config key 'editor' is now 'editors.default', please update your config.")
      end

      if config.key?('config_editor_app') && !config['editors']['config']
        deprecated = true
        config['editors']['config'] = config['config_editor_app']
        config.delete('config_editor_app')
        Doing.logger.debug('Deprecated:',
                           "config key 'config_editor_app' is now 'editors.config', please update your config.")
      end

      if config.key?('editor_app') && !config['editors']['doing_file']
        deprecated = true
        config['editors']['doing_file'] = config['editor_app']
        config.delete('editor_app')
        Doing.logger.debug('Deprecated:',
                           "config key 'editor_app' is now 'editors.doing_file', please update your config.")
      end

      Doing.logger.warn('Deprecated:', 'outdated keys found, please run `doing config --update`.') if deprecated
      config
    end

    ##
    ## Read local configurations
    ##
    ## @return     Hash of config options
    ##
    def local_config
      return {} if @ignore_local

      local_configs = read_local_configs || {}

      if additional_configs&.count
        file_list = additional_configs.map { |p| p.sub(/^#{Util.user_home}/, '~') }.join(', ')
        Doing.logger.debug('Config:', "Local config files found: #{file_list}")
      end

      local_configs
    end

    def read_local_configs
      local_configs = {}

      begin
        additional_configs.each do |cfg|
          local_configs.deep_merge(Util.safe_load_file(cfg), { extend_existing_arrays: true, sort_merged_arrays: true })
        end
      rescue StandardError
        Doing.logger.error('Config:', 'Error reading local configuration(s)')
      end

      local_configs
    end

    ##
    ## Reads a configuration.
    ##
    def read_config
      unless File.exist?(config_file)
        Doing.logger.info('Config:', 'Config file doesn\'t exist, using default configuration')
        return {}.deep_merge(DEFAULTS)
      end

      begin
        user_config = Util.safe_load_file(config_file)
        raise StandardError, 'Invalid config file format' unless user_config.is_a?(Hash)

        if user_config.key?('html_template')
          user_config['export_templates'] ||= {}
          user_config['export_templates'].deep_merge(user_config.delete('html_template'),
                                                     { extend_existing_arrays: true, sort_merged_arrays: true })
        end

        user_config['include_notes'] = user_config.delete(':include_notes') if user_config.key?(':include_notes')

        user_config.deep_merge(DEFAULTS, { extend_existing_arrays: true, sort_merged_arrays: true })
      rescue StandardError => e
        Doing.logger.error('Config:', 'Error reading default configuration')
        Doing.logger.error('Error:', e.message)
        user_config = DEFAULTS
      end

      user_config
    end

    ##
    ## Finds a project-specific configuration file
    ##
    ## @return     [String] A file path
    ##
    def find_local_config
      dir = Dir.pwd

      local_config_files = []

      while dir != '/' && (dir =~ %r{[A-Z]:/}).nil?
        local_config_files.push(File.join(dir, '.doingrc')) if File.exist? File.join(dir, '.doingrc')

        dir = File.dirname(dir)
      end

      local_config_files.delete(config_file)

      local_config_files
    end

    def load_plugins(add_dir = nil)
      FileUtils.mkdir_p(add_dir) if add_dir && !File.exist?(add_dir)

      Plugins.load_plugins(add_dir)
    end
  end
end
