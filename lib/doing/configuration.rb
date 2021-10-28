module Doing
  class Configuration < Hash
    attr_accessor :default_config_file, :config_file, :config
    attr_reader :additional_configs, :current_section, :default_template, :default_date_format

    def default_config_file
      @default_config_file ||= '.doingrc'
    end

    DEFAULTS = {
      'autotag' => {
        'whitelist' => [],
        'synonyms' => {}
      },
      'doing_file' => '~/what_was_i_doing.md',
      'current_section' => 'Currently',
      'config_editor_app' => nil,
      'editor_app' => nil,
      'paginate' => false,
      'never_time' => [],
      'never_finish' => [],

      'templates' => {
        'default' => {
          'date_format' => '%Y-%m-%d %H:%M',
          'template' => '%date | %title%note',
          'wrap_width' => 0
        },
        'today' => {
          'date_format' => '%_I:%M%P',
          'template' => '%date: %title %interval%note',
          'wrap_width' => 0
        },
        'last' => {
          'date_format' => '%-I:%M%P on %a',
          'template' => '%title (at %date)%odnote',
          'wrap_width' => 88
        },
        'recent' => {
          'date_format' => '%_I:%M%P',
          'template' => '%shortdate: %title (%section)',
          'wrap_width' => 88,
          'count' => 10
        }
      },

      'export_templates' => {},

      'views' => {
        'done' => {
          'date_format' => '%_I:%M%P',
          'template' => '%date | %title%note',
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
      :include_notes => true
    }.each_with_object(Configuration.new) { |(k, v), hsh| hsh[k] = v.freeze }.freeze

    class << self
      # Static: Produce a Configuration ready for use in a Site.
      # It takes the input, fills in the defaults where values do not exist.
      #
      # user_config - a Hash or Configuration of overrides.
      #
      # Returns a Configuration filled with defaults.
      def from(user_config)
        Utils.deep_merge_hashes(DEFAULTS, Configuration[user_config].stringify_keys)
             .add_default_collections.add_default_excludes
      end
    end

    # Public: Turn all keys into string
    #
    # Return a copy of the hash where all its keys are strings
    def stringify_keys
      each_with_object({}) { |(k, v), hsh| hsh[k.to_s] = v }
    end

    def get_config_value_with_override(config_key, override)
      override[config_key] || self[config_key] || DEFAULTS[config_key]
    end

    def safe_load_file(filename)
      YAML.load_file(filename) || {}
    end

    def user_home
      @user_home ||= if Dir.respond_to?('home')
                       Dir.home
                     else
                       File.expand_path('~')
                     end
    end

    ##
    ## @brief      Reads a configuration.
    ##
    def read_config(opt = {})
      @config_file ||= File.join(user_home, default_config_file)

      @additional_configs = if opt[:ignore_local]
                             []
                           else
                             find_local_config
                           end
      begin
        @local_config = {}

        @config = safe_load_file(@config_file) || {} if File.exist?(@config_file)


        if @config.key?('html_template')
          @config['export_templates'].deep_merge(@config['html_template'])
          @config.delete('html_template')
        end

        @additional_configs.each do |cfg|
          new_config = safe_load_file(cfg) || {} if cfg
          @local_config.deep_merge(new_config)
        end

        # @config.deep_merge(@local_config)
      rescue StandardError
        @config = {}
        @local_config = {}
        # exit_now! "error reading config"
      end

      @additional_configs.delete(@config_file)

      if @additional_configs && @additional_configs.count.positive?
        Doing.logger.debug('Configuration:', "Local config files found: #{@additional_configs.map { |p| p.sub(/^#{@user_home}/, '~') }.join(', ')}")
      end
    end

    ##
    ## @brief      Finds a project-specific configuration file
    ##
    ## @return     (String) A file path
    ##
    def find_local_config
      dir = Dir.pwd

      local_config_files = []

      while dir != '/' && (dir =~ %r{[A-Z]:/}).nil?
        local_config_files.push(File.join(dir, default_config_file)) if File.exist? File.join(dir, default_config_file)

        dir = File.dirname(dir)
      end

      local_config_files
    end

    ##
    ## @brief      Read user configuration and merge with defaults
    ##
    ## @param      opt   (Hash) Additional Options
    ##
    def configure(opt = {})
      opt[:ignore_local] ||= false

      @config_file ||= File.join(user_home, default_config_file)

      read_config({ ignore_local: opt[:ignore_local] })

      @current_section = @config['current_section']
      @default_template = @config['templates']['default']['template']
      @default_date_format = @config['templates']['default']['date_format']

      # if ENV['DOING_DEBUG'].to_i == 3
      #   if @config['default_tags'].length > 0
      #     exit_now! "DEFAULT CONFIG CHANGED"
      #   end
      # end

      plugin_config = { 'plugin_path' => nil }

      load_plugins

      Plugins.plugins.each do |_type, plugins|
        plugins.each do |title, plugin|
          plugin_config[title] = plugin[:config] if plugin.key?(:config) && !plugin[:config].empty?
          @config['export_templates'][title] ||= nil if plugin.key?(:templates)
        end
      end

      @config.deep_merge({ 'plugins' => plugin_config })

      write_config if !File.exist?(@config_file) || opt[:rewrite]

      Hooks.trigger :post_config, self

      @config.deep_merge(@local_config)

      Hooks.trigger :post_local_config, self

      @current_section = @config['current_section']
      @default_template = @config['templates']['default']['template']
      @default_date_format = @config['templates']['default']['date_format']

    end

    ##
    ## @brief      Write current configuration to file
    ##
    ## @param      file    The file
    ## @param      backup  The backup
    ##
    def write_config(file = nil, backup: false)
      file ||= @config_file
      write_to_file(file, YAML.dump(@config), backup: backup)
    end

    def load_plugins
      if @config.key?('plugins') && @config['plugins']['plugin_path']
        add_dir = @config['plugins']['plugin_path']
      else
        add_dir = File.join(@user_home, '.config', 'doing', 'plugins')
        FileUtils.mkdir_p(add_dir) if add_dir
      end

      Plugins.load_plugins(add_dir)
    end

  end
end
