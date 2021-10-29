# frozen_string_literal: true

module Doing
  ##
  ## @brief      Configuration object
  ##
  class Configuration < Hash
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
    }

    # Public: Turn all keys into string
    #
    # Return a copy of the hash where all its keys are strings
    def stringify_keys
      each_with_object({}) { |(k, v), hsh| hsh[k.to_s] = v }
    end

    class << self
      def additional_configs
        @additional_configs ||= find_local_config
      end

      # Static: Produce a Configuration ready for use in a Site.
      # It takes the input, fills in the defaults where values do not exist.
      #
      # user_config - a Hash or Configuration of overrides.
      #
      # Returns a Configuration filled with defaults.
      def from(user_config)
        Util.deep_merge_hashes(DEFAULTS, Configuration[user_config].stringify_keys)
      end

      def config_file
        @config_file ||= File.join(Util.user_home, '.doingrc')
      end

      def config_file=(file)
        @config_file = file
      end

      def get_config_value_with_override(config_key, override)
        override[config_key] || self[config_key] || DEFAULTS[config_key]
      end

      def safe_load_file(filename)
        YAML.load_file(filename) || {}
      end

      ##
      ## @brief      Read local configurations
      ##
      ## @return     Hash of config options
      ##
      def local_config
        local_configs = read_local_configs || {}

        if additional_configs&.count
          file_list = additional_configs.map { |p| p.sub(/^#{Util.user_home}/, '~') }.join(', ')
          Doing.logger.debug('Configuration:', "Local config files found: #{file_list}")
        end

        local_configs
      end

      def read_local_configs
        local_configs = {}

        begin
          additional_configs.each do |cfg|
            local_configs.deep_merge(safe_load_file(cfg))
          end
        rescue StandardError
          Doing.logger.error('Configuration:', 'Error reading local configuration(s)')
        end

        local_configs
      end

      ##
      ## @brief      Reads a configuration.
      ##
      def read_config
        begin
          user_config = safe_load_file(config_file) rescue {}
          user_config['export_templates'].deep_merge(user_config.delete('html_template')) if user_config.key?('html_template')
          user_config.deep_merge(DEFAULTS)
        rescue StandardError
          Doing.logger.error('Configuration:', 'Error reading default configuration')
          user_config = DEFAULTS
        end

        user_config
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
          local_config_files.push(File.join(dir, '.doingrc')) if File.exist? File.join(dir, '.doingrc')

          dir = File.dirname(dir)
        end

        local_config_files.delete(config_file)

        local_config_files
      end

      ##
      ## @brief      Read user configuration and merge with defaults
      ##
      ## @param      opt   (Hash) Additional Options
      ##
      def configure(opt = {})
        opt[:ignore_local] ||= false

        config = read_config.dup

        plugin_config = { 'plugin_path' => nil }

        path = config.dig('plugins', 'plugin_path') || File.join(Util.user_home, '.config', 'doing', 'plugins')
        load_plugins(path)

        Plugins.plugins.each do |_type, plugins|
          plugins.each do |title, plugin|
            plugin_config[title] = plugin[:config] if plugin.key?(:config) && !plugin[:config].empty?
            config['export_templates'][title] ||= nil if plugin.key?(:templates)
          end
        end

        config.deep_merge({ 'plugins' => plugin_config })

        if !File.exist?(config_file) || opt[:rewrite]
          Util.write_to_file(config_file, YAML.dump(config), backup: true)
          Doing.logger.warn('Configuration:', "Config file written to #{config_file}")
        end

        Hooks.trigger :post_config, self

        config.deep_merge(local_config) unless opt[:ignore_local]

        Hooks.trigger :post_local_config, self

        Configuration[config]
      end

      def load_plugins(add_dir = nil)
        FileUtils.mkdir_p(add_dir) if add_dir

        Plugins.load_plugins(add_dir)
      end
    end
  end
end
