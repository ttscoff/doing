# frozen_string_literal: true

require 'doing/version'
require 'time'
require 'date'
require 'yaml'
require 'pp'
require 'csv'
require 'tempfile'
require 'zlib'
require 'base64'
require 'plist'
require 'readline'
require 'haml'
require 'json'
require 'logger'
require 'safe_yaml/load'
require 'fcntl'

require 'chronic'
require 'tty-link'
require 'tty-which'
require 'tty-markdown'
require 'tty-reader'
require 'tty-screen'

require_relative 'doing/colors'
require_relative 'doing/types'
require_relative 'doing/hash'
require_relative 'doing/template_string'
require_relative 'doing/string/string'
require_relative 'doing/time'
require_relative 'doing/array/array'
require_relative 'doing/good'
require_relative 'doing/normalize'
require_relative 'doing/util'
require_relative 'doing/changelog/changelog'
require_relative 'doing/util_backup'
require_relative 'doing/configuration'
require_relative 'doing/section'
require_relative 'doing/items/items'
require_relative 'doing/note'
require_relative 'doing/item/item'
require_relative 'doing/wwid/wwid'
require_relative 'doing/logger'
require_relative 'doing/prompt/prompt'
require_relative 'doing/errors'
require_relative 'doing/hooks'
require_relative 'doing/plugin_manager'
require_relative 'doing/pager'
require_relative 'doing/completion'
require_relative 'doing/boolean_term_parser'
require_relative 'doing/phrase_parser'
require_relative 'doing/chronify/chronify'
# require 'doing/markdown_document_listener'

# Main doing module
module Doing
  class << self
    attr_accessor :auto_tag
    #
    # Fetch the logger
    #
    # @return     the Logger instance.
    #
    def logger
      @logger ||= Logger.new((ENV['DOING_LOG_LEVEL'] || :info).to_sym)
    end

    ##
    ## Holds a Configuration object with methods and a @settings hash
    ##
    ## @return     [Configuration] Configuration object
    ##
    def config
      @config ||= Configuration.new
    end

    ##
    ## Shortcut for Doing.config.settings
    ##
    ## @return     [Hash] Settings hash
    ##
    def settings
      config.settings
    end

    ##
    ## Fetch a config setting using a dot-separated keypath
    ## or array of keys
    ##
    ## @param      keypath  [String|Array] Either a
    ##                      dot-separated key path
    ##                      (search.case) or array of keys
    ##                      (['search', 'case'])
    ## @param      default  A default value to return if the
    ##                      provided path returns nil result
    ##
    def setting(keypath, default = nil)
      cfg = config.settings
      case keypath
      when Array
        cfg.dig(*keypath) || default
      when String
        unless keypath =~ /^[.*]?$/
          real_path = config.resolve_key_path(keypath, create: false)
          return default unless real_path&.count&.positive?

          cfg = cfg.dig(*real_path)
        end

        cfg.nil? ? default : cfg
      end
    end

    def set(keypath, value)
      real_path = config.resolve_key_path(keypath, create: false)
      return nil unless real_path&.count&.positive?

      config.settings.deep_set(real_path, value)
    end

    ##
    ## Update configuration from specified file
    ##
    ## @param      file     [String] Path to new config file
    ## @param      options  [Hash] options
    ##
    ## @option options :ignore_local Ignore local configuration files
    ##
    def config_with(file, options = {})
      @config = Configuration.new(file, options: options)
    end
  end
end
