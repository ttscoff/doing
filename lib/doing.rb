# frozen_string_literal: true

require 'doing/version'
require 'time'
require 'date'
require 'yaml'
require 'pp'
require 'csv'
require 'tempfile'
require 'chronic'
require 'haml'
require 'json'
require 'logger'
require 'doing/string'
require 'doing/time'
require 'doing/array'
require 'doing/symbol'
require 'doing/util'
require 'doing/item'
require 'doing/note'
require 'doing/wwid'
require 'doing/colors'
require 'doing/log_adapter'
require 'doing/console_writer'
require 'doing/errors'
require 'doing/plugin_manager'
# require 'doing/markdown_document_listener'

# Main doing module
module Doing
  class << self
    #
    # @brief      Fetch the logger
    #
    # @return     the LogAdapter instance.
    #
    def logger
      @logger ||= LogAdapter.new(ConsoleWriter.new, (ENV['DOING_LOG_LEVEL'] || :info).to_sym)
    end

    #
    # @brief      Set the log writer. New log writer must
    #             respond to the same methods as Ruby's
    #             interal Logger.
    #
    # @param      writer  the new Logger-compatible log
    #                     transport
    #
    # @return     the new logger.
    #
    def logger=(writer)
      @logger = LogAdapter.new(writer, (ENV['DOING_LOG_LEVEL'] || :info).to_sym)
    end
  end
end
