# frozen_string_literal: true

module Doing
  # Plugin handling
  module Plugins
    class << self

      def user_home
        @user_home ||= Util.user_home
      end

      def plugins
        @plugins ||=  {
                        import: {},
                        export: {}
                      }
      end

      ##
      # Load plugins from plugins folder
      #
      def load_plugins(add_dir = nil)
        plugins_path(add_dir).each do |plugin_search_path|
          Dir.glob(File.join(plugin_search_path, '**', '*.rb')).sort.each do |plugin|
            require plugin
          end
        end

        plugins
      end

      # Public: Setup the plugin search path
      #
      # Returns an Array of plugin search paths
      def plugins_path(add_dir = nil)
        paths = Array(File.join(File.dirname(__FILE__), 'plugins'))
        paths << File.join(add_dir) if add_dir
        paths.map { |d| File.expand_path(d) }
      end

      ##
      # Register a plugin
      #
      # param: +[String|Array]+ title  The name of the plugin (can be an array of names)
      #
      # param: +type+ The plugin type (:import, :export)
      #
      # param: +klass+ The class responding to :render or :import
      #
      #
      # returns: Success boolean
      #
      def register(title, type, klass)
        type = validate_plugin(title, type, klass)
        return unless type

        if title.is_a?(Array)
          title.each { |t| register(t, type, klass) }
          return
        end

        settings = if klass.respond_to? :settings
                     klass.settings
                   else
                     { trigger: title.normalize_trigger, config: {} }
                   end

        plugins[type] ||= {}
        plugins[type][title] = {
          trigger: settings[:trigger].normalize_trigger || title.normalize_trigger,
          class: klass,
          templates: settings[:templates] || nil,
          config: settings[:config] || {}
        }

        return unless ENV['DOING_PLUGIN_DEBUG']

        Doing.logger.debug('Plugin Manager:', "Registered #{type} plugin \"#{title}\"")

      end

      def validate_plugin(title, type, klass)
        type = valid_type(type)
        if type == :import && !klass.respond_to?(:import)
          raise Errors::PluginUncallable.new('Import plugins must respond to :import', type: type, plugin: title)
        end

        if type == :export && !klass.respond_to?(:render)
          raise Errors::PluginUncallable.new('Export plugins must respond to :render', type: type, plugin: title)
        end

        type
      end

      def valid_type(type, default: nil)
        type ||= default

        t = type.to_s
        type = case t
               when /^i(m(p(o(r(t)?)?)?)?)?$/
                 :import
               when /^e(x(p(o(r(t)?)?)?)?)?$/
                 :export
               else
                 raise Errors::InvalidPluginType, 'Invalid plugin type'
               end

        type.to_sym
      end

      ##
      ## @brief      List available plugins to stdout
      ##
      ## @param      options  { type, separator }
      ##
      def list_plugins(options = {})
        separator = options[:column] ? "\n" : "\t"
        type = options[:type].nil? || options[:type] =~ /all/i ? 'all' : [valid_type(options[:type])]

        case type
        when :import
          puts plugin_names(type: :import, separator: separator)
        when :export
          puts plugin_names(type: :export, separator: separator)
        else
          print 'Import plugins: '
          puts plugin_names(type: :import, separator: ', ')
          print 'Export plugins: '
          puts plugin_names(type: :export, separator: ', ')
        end
      end

      ##
      ## @brief      Return array of available plugin names
      ##
      ## @param      type  Plugin type (:import, :export)
      ##
      ## @returns    [Array<String>] plugin names
      ##
      def available_plugins(type: :export)
        type = valid_type(type)
        plugins[type].keys.sort
      end

      ##
      ## @brief      Return string version of plugin names
      ##
      ## @param      type       Plugin type (:import, :export)
      ## @param      separator  The separator to join names with
      ##
      ## @return     [String]   Plugin names
      ##
      def plugin_names(type: :export, separator: '|')
        type = valid_type(type)
        available_plugins(type: type).join(separator)
      end

      ##
      ## @brief      Return a regular expression of all
      ##             plugin triggers for type
      ##
      ## @param      type  The type :import or :export
      ##
      def plugin_regex(type: :export)
        type = valid_type(type)
        pattern = []
        plugins[type].each do |_, options|
          pattern << options[:trigger].normalize_trigger
        end
        Regexp.new("^(?:#{pattern.join('|')})$", true)
      end

      def plugin_templates(type: :export)
        type = valid_type(type)
        templates = []
        plugs = plugins[type].clone
        plugs.delete_if { |t, o| o[:templates].nil? }.each do |_, options|
          options[:templates].each do |t|
            templates << t[:name]
          end
        end

        templates
      end

      def template_regex(type: :export)
        type = valid_type(type)
        pattern = []
        plugs = plugins[type].clone
        plugs.delete_if { |t, o| o[:templates].nil? }.each do |_, options|
          options[:templates].each do |t|
            pattern << t[:trigger].normalize_trigger
          end
        end
        Regexp.new("^(?:#{pattern.join('|')})$", true)
      end

      def template_for_trigger(trigger, type: :export)
        type = valid_type(type)
        plugs = plugins[type].clone
        plugs.delete_if { |t, o| o[:templates].nil? }.each do |_, options|
          options[:templates].each do |t|
            if trigger =~ /^(?:#{t[:trigger].normalize_trigger})$/
              return options[:class].template(trigger)
            end
          end
        end
        raise Errors::InvalidArgument, "No template type matched \"#{trigger}\""
      end
    end
  end
end
