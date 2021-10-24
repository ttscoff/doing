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
require 'doing/errors'
require 'doing/string'
require 'doing/time'
require 'doing/array'
require 'doing/symbol'
require 'doing/util'
require 'doing/item'
require 'doing/note'
require 'doing/wwid'
require 'doing/plugin_manager'
# require 'doing/markdown_document_listener'

module Doing
  class << self

    # Fetch the logger
    #
    # Returns the LogAdapter instance.
    def logger
      # @logger ||= LogAdapter.new(Stevenson.new, (ENV["JEKYLL_LOG_LEVEL"] || :info).to_sym)
    end

    # Set the log writer.
    #         New log writer must respond to the same methods
    #         as Ruby's interal Logger.
    #
    # writer - the new Logger-compatible log transport
    #
    # Returns the new logger.
    def logger=(writer)
      # @logger = LogAdapter.new(writer, (ENV["JEKYLL_LOG_LEVEL"] || :info).to_sym)
    end

  end
end
