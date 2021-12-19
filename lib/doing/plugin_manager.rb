# frozen_string_literal: true

module Doing
  # Plugin handling
  module Plugins
    class << self
      def user_home
        @user_home ||= Util.user_home
      end

      def plugins
        @plugins ||= {
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

      # Setup the plugin search path
      #
      # @param      add_dir  [String] optional additional
      #                      path to include
      #
      # @return     [Array] Returns an Array of plugin search paths
      #
      def plugins_path(add_dir = nil)
        paths = Array(File.join(File.dirname(__FILE__), 'plugins'))
        paths << File.join(add_dir) if add_dir
        paths.map { |d| File.expand_path(d) }
      end


      # Register a plugin
      #
      # @param      title  [String|Array] The name of the
      #                    plugin (can be an array of names)
      # @param      type   [Symbol] The plugin type
      #                    (:import, :export)
      # @param      klass  [Class] The class responding to
      #                    :render or :import
      #
      # @return     [Boolean] Success boolean
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

      ##
      ## Converts a partial symbol to a valid plugin type,
      ## e.g. :imp => :import
      ##
      ## @param      type     [Symbol] the symbol to test
      ## @param      default  [Symbol] fallback value
      ##
      ## @return     [Symbol] :import or :export
      ##
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
      ## List available plugins to stdout
      ##
      ## @param      options  { type, separator }
      ##
      def list_plugins(options = {})
        separator = options[:column] ? "\n" : "\t"
        type = options[:type].nil? || options[:type] =~ /all/i ? 'all' : valid_type(options[:type])

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
      ## Return array of available plugin names
      ##
      ## @param      type  Plugin type (:import, :export)
      ##
      ## @return     [Array<String>] plugin names
      ##
      def available_plugins(type: :export)
        type = valid_type(type)
        plugins[type].keys.sort
      end

      ##
      ## Return string version of plugin names
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
      ## Return a regular expression of all plugin triggers
      ## for type
      ##
      ## @param      type  [Symbol] The type :import or
      ##                   :export
      ##
      ## @return     [Regexp] regular expression
      ##
      def plugin_regex(type: :export)
        type = valid_type(type)
        pattern = []
        plugins[type].each do |_, options|
          pattern << options[:trigger].normalize_trigger
        end
        Regexp.new("^(?:#{pattern.join('|')})$", true)
      end

      ##
      ## Return array of available template names
      ##
      ## @param      type  [Symbol] Plugin type (:import,
      ##                   :export)
      ##
      ## @return     [Array<String>] template names
      ##
      def plugin_templates(type: :export)
        type = valid_type(type)
        templates = []
        plugs = plugins[type].clone
        plugs.delete_if { |_t, o| o[:templates].nil? }.each do |_, options|
          options[:templates].each do |t|
            templates << t[:name]
          end
        end

        templates
      end

      ##
      ## Return a regular expression of all template
      ## triggers for type
      ##
      ## @param      type  [Symbol] The type :import or
      ##                   :export
      ##
      ## @return     [Regexp] regular expression
      ##
      def template_regex(type: :export)
        type = valid_type(type)
        pattern = []
        plugs = plugins[type].clone
        plugs.delete_if { |_t, o| o[:templates].nil? }.each do |_, options|
          options[:templates].each do |t|
            pattern << t[:trigger].normalize_trigger
          end
        end
        Regexp.new("^(?:#{pattern.join('|')})$", true)
      end

      ##
      ## Find and return the appropriate template for a
      ## trigger string. Outputs a string that can be
      ## written out to the terminal for redirection
      ##
      ## @param      trigger  [String] The trigger to test
      ## @param      type     [Symbol] the plugin type
      ##                      (:import, :export)
      ##
      ## @return     [String] string content of template for trigger
      ##
      def template_for_trigger(trigger, type: :export)
        type = valid_type(type)
        plugs = plugins[type].clone
        plugs.delete_if { |_t, o| o[:templates].nil? }.each do |_, options|
          options[:templates].each do |t|
            return options[:class].template(trigger) if trigger =~ /^(?:#{t[:trigger].normalize_trigger})$/
          end
        end
        raise Errors::InvalidArgument, "No template type matched \"#{trigger}\""
      end
    end
  end
end
