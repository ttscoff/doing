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

require_relative 'doing/hash'
require_relative 'doing/colors'
require_relative 'doing/template_string'
require_relative 'doing/string'
require_relative 'doing/time'
require_relative 'doing/array'
require_relative 'doing/symbol'
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
require_relative 'doing/array_chronify'
require_relative 'doing/numeric_chronify'
require_relative 'doing/string_chronify'
# require 'doing/markdown_document_listener'

REGEX_BOOL = /^(?:and|all|any|or|not|none|p(?:at(?:tern)?)?)$/i
REGEX_SORT_ORDER = /^(?:a(?:sc)?|d(?:esc)?)$/i
REGEX_VALUE_QUERY = /^(?:!)?@?(?:\S+) +(?:!?[<>=][=*]?|[$*^]=) +(?:.*?)$/
REGEX_CLOCK = '(?:\d{1,2}+(?::\d{1,2}+)?(?: *(?:am|pm))?|midnight|noon)'
REGEX_TIME = /^#{REGEX_CLOCK}$/i
REGEX_DAY = /^(mon|tue|wed|thur?|fri|sat|sun)(\w+(day)?)?$/i
REGEX_RANGE_INDICATOR = ' +(?:to|through|thru|(?:un)?til|-+) +'
REGEX_RANGE = /^\S+#{REGEX_RANGE_INDICATOR}+\S+/i
REGEX_TIME_RANGE = /^#{REGEX_CLOCK}#{REGEX_RANGE_INDICATOR}#{REGEX_CLOCK}$/i

InvalidExportType = Class.new(RuntimeError)
MissingConfigFile = Class.new(RuntimeError)
TagArray = Class.new(Array)
DateBeginString = Class.new(DateTime)
DateEndString = Class.new(DateTime)
DateRangeString = Class.new(Array)
DateIntervalString = Class.new(DateTime)

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
