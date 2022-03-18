# frozen_string_literal: true

module Doing
  # Plugin handling
  module Plugins
    class << self
      # Return the user's home directory
      def user_home
        @user_home ||= Util.user_home
      end

      # Storage for registered plugins. Hash with :import
      # and :export keys containing hashes of available
      # plugins.
      #
      # @return     [Hash] registered plugins
      #
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

      ##
      ## Verifies that a plugin is properly configured with
      ## necessary methods for its type. If the plugin fails
      ## validation, a PluginUncallable exception will be
      ## raised.
      ##
      ## @param      title  [String] The title
      ## @param      type   [Symbol] type, :import or
      ##                    :export
      ## @param      klass  [Class] Plugin class
      ##
      def validate_plugin(title, type, klass)
        type = valid_type(type)
        if type == :import && !klass.respond_to?(:import)
          raise Errors::PluginUncallable.new('Import plugins must respond to :import', type, title)
        end

        if type == :export && !klass.respond_to?(:render)
          raise Errors::PluginUncallable.new('Export plugins must respond to :render', type, title)
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
                 raise Errors::InvalidPluginType.new('Invalid plugin type', 'unrecognized')
               end

        type.to_sym
      end

      ##
      ## List available plugins to stdout
      ##
      ## @param      options  [Hash] additional options
      ##
      ## @option options :column [Boolean] display results in a single column
      ## @option options :type [String] Plugin type: all, import, or export
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
      ## @param      type  [Symbol] Plugin type (:import, :export)
      ##
      ## @return     [Array] Array of plugin names (String)
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
      ## @return     [String]   Plugin names joined with separator
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
      ## @return     [Array] Array of template names (String)
      ##
      def plugin_templates(type: :export)
        type = valid_type(type)
        templates = []
        plugs = plugins[type].clone
        plugs.delete_if { |_t, o| o[:templates].nil? }.each do |_, options|
          options[:templates].each do |t|
            out = t[:name]
            out += " (#{t[:format]})" if t.key?(:format)
            templates << out
          end
        end

        templates.sort.uniq
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
        plugs.delete_if { |_, o| o[:templates].nil? }.each do |_, options|
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
      ## @param      save_to  [String] if a path is
      ##                      specified, write the template
      ##                      to that path. Nil for STDOUT
      ##
      ## @return     [String] string content of template for trigger
      ##
      def template_for_trigger(trigger, type: :export, save_to: nil)
        plugins[valid_type(type)].clone.delete_if { |_t, o| o[:templates].nil? }.each do |_, options|
          options[:templates].each do |t|
            next unless trigger =~ /^(?:#{t[:trigger].normalize_trigger})$/

            tpl = options[:class].template(trigger)
            return tpl unless save_to

            raise PluginException.new('No default filename defined', :export, t[:name]) unless t.key?(:filename)

            return save_template(tpl, save_to, t[:filename])
          end
        end
        raise Errors::InvalidArgument, "No template type matched \"#{trigger}\""
      end

      private

      def save_template(tpl, dir, filename)
        dir = File.expand_path(dir)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        raise DoingRuntimeError, "Path #{dir} exists but is not a directory" unless File.directory?(dir)

        file = File.join(dir, filename)
        File.open(file, 'w') do |f|
          f.puts(tpl)
          Doing.logger.warn('File update:', "Template written to #{file}")
        end
      end
    end
  end
end
