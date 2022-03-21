# frozen_string_literal: true

module Doing
  module Types
    REGEX_CASE = /^[cis].*?$/i.freeze
    REGEX_TAG_SORT = /^(?:n(?:ame)?|t(?:ime)?)$/i.freeze
    REGEX_BOOL = /^(?:and|all|any|or|not|none|p(?:at(?:tern)?)?)$/i.freeze
    REGEX_SORT_ORDER = /^(?:a(?:sc)?|d(?:esc)?)$/i.freeze
    REGEX_VALUE_QUERY = /^(?:!)?@?(?:\S+) +(?:!?[<>=][=*]?|[$*^]=) +(?:.*?)$/.freeze
    REGEX_CLOCK = '(?:\d{1,2}+(?::\d{1,2}+)?(?: *(?:am|pm))?|midnight|noon)'
    REGEX_TIME = /^#{REGEX_CLOCK}$/i.freeze
    REGEX_DAY = /^(mon|tue|wed|thur?|fri|sat|sun)(\w+(day)?)?$/i.freeze
    REGEX_RANGE_INDICATOR = ' +(?:to|through|thru|(?:un)?til|-+) +'
    REGEX_RANGE = /^\S+.*?#{REGEX_RANGE_INDICATOR}\S+.*?$/i.freeze
    REGEX_TIME_RANGE = /^#{REGEX_CLOCK}(?:#{REGEX_RANGE_INDICATOR}#{REGEX_CLOCK})?$/i.freeze

    InvalidExportType = Class.new(RuntimeError)
    MissingConfigFile = Class.new(RuntimeError)

    AgeSymbol = Class.new(String)
    BooleanSymbol = Class.new(Symbol)
    CaseSymbol = Class.new(Symbol)
    DateBeginString = Class.new(DateTime)
    DateEndString = Class.new(DateTime)
    DateIntervalString = Class.new(DateTime)
    DateRangeOptionalString = Class.new(Array)
    DateRangeString = Class.new(Array)
    ExportTemplate = Class.new(String)
    MatchingSymbol = Class.new(Symbol)
    OrderSymbol = Class.new(Symbol)
    TagArray = Class.new(Array)
    TagSortSymbol = Class.new(Symbol)
    TemplateName = Class.new(String)
  end
end
