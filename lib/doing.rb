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

require 'chronic'
require 'tty-link'
require 'tty-which'
require 'tty-markdown'
require 'tty-reader'
require 'tty-screen'
require 'sys-uname'

require_relative 'doing/changelog'
require_relative 'doing/hash'
require_relative 'doing/types'
require_relative 'doing/colors'
require_relative 'doing/template_string'
require_relative 'doing/string/string'
require_relative 'doing/time'
require_relative 'doing/array/array'
require_relative 'doing/good'
require_relative 'doing/normalize'
require_relative 'doing/util'
require_relative 'doing/util_backup'
require_relative 'doing/configuration'
require_relative 'doing/section'
require_relative 'doing/items'
require_relative 'doing/note'
require_relative 'doing/item'
require_relative 'doing/wwid'
require_relative 'doing/log_adapter'
require_relative 'doing/prompt'
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
    #
    # Fetch the logger
    #
    # @return     the LogAdapter instance.
    #
    def logger
      @logger ||= LogAdapter.new((ENV['DOING_LOG_LEVEL'] || :info).to_sym)
    end

    def config
      @config ||= Configuration.new
    end

    def settings
      @settings ||= @config.settings
    end

    def config_with(file, options = {})
      @config = Configuration.new(file, options: options)
    end
  end
end
