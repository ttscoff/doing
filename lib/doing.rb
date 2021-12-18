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
require 'chronic'
require 'tty-link'
require 'tty-which'
require 'tty-markdown'
# require 'amatch'
require 'haml'
require 'json'
require 'logger'
require 'safe_yaml/load'
require 'doing/hash'
require 'doing/colors'
require 'doing/template_string'
require 'doing/string'
require 'doing/string_chronify'
require 'doing/time'
require 'doing/array'
require 'doing/symbol'
require 'doing/util'
require 'doing/util_backup'
require 'doing/configuration'
require 'doing/section'
require 'doing/items'
require 'doing/note'
require 'doing/item'
require 'doing/wwid'
require 'doing/log_adapter'
require 'doing/prompt'
require 'doing/errors'
require 'doing/hooks'
require 'doing/plugin_manager'
require 'doing/pager'
require 'doing/completion'
require 'doing/boolean_term_parser'
require 'doing/phrase_parser'
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

    def config_with(file, options = {})
      @config = Configuration.new(file, options: options)
    end
  end
end
