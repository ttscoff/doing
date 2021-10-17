# frozen_string_literal: true

module Doing
  module Plugins
    Uncallable = Class.new(RuntimeError)

    @user_home = if Dir.respond_to?('home')
                       Dir.home
                     else
                       File.expand_path('~')
                     end

    @plugins = {
      import: {},
      export: {}
    }

    ##
    ## @brief      Load plugins from plugins folder
    ##
    def self.load_plugins(add_dir = nil)
      plugins_path(add_dir).each do |plugin_search_path|
        Dir.glob(File.join(plugin_search_path, '**', '*.rb')).each do |plugin|
          require plugin
        end
      end

      @plugins
    end

    # Public: Setup the plugin search path
    #
    # Returns an Array of plugin search paths
    def self.plugins_path(add_dir = nil)
      paths = [
        File.join(File.dirname(__FILE__), 'plugins'),
        File.join(@user_home, '.config', 'doing', 'plugins'),
        File.join(@user_home, '.config', 'baddir')
      ]
      if add_dir
        paths << File.join(add_dir)
      end
      paths.map { |d| File.expand_path(d) }
    end

    ##
    ## @brief      Register a plugin
    ##
    ## @param      opt   The plugin options
    ##
    def self.register_plugin(opt)
      @plugins[opt[:type]] ||= {}
      @plugins[opt[:type]][opt[:name]] = { class: opt[:class], trigger: opt[:trigger] }
      @plugins[opt[:type]][opt[:name]][:config] = opt[:config] if opt.key?(:config)

      obj = Object.const_get(opt[:class]).new
      if opt[:type] == :import
        raise Uncallable, "Import plugins must respond to :import" unless obj.respond_to? :import
      elsif opt[:type] == :export
        raise Uncallable, "Export plugins must respond to :render" unless obj.respond_to? :render
      end
    end
  end
end
