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
require 'doing/colors'
require 'doing/string'
require 'doing/time'
require 'doing/array'
require 'doing/symbol'
require 'doing/util'
require 'doing/item'
require 'doing/note'
require 'doing/wwidfile'
require 'doing/wwid'
require 'doing/log_adapter'
require 'doing/errors'
require 'doing/hooks'
require 'doing/plugin_manager'
require 'doing/pager'
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
      @logger ||= LogAdapter.new((ENV['DOING_LOG_LEVEL'] || :info).to_sym)
    end
  end
end
