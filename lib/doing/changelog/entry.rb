# frozen_string_literal: true

module Doing
  # An individual changelog item
  class Entry
    attr_reader :type, :string

    attr_writer :prefix

    def initialize(string, type, prefix: false)
      @string = string
      @type = type
      @prefix = prefix
    end

    def clean(string)
      string.gsub(/\|/, '\|')
    end

    def print_prefix
      @prefix ? "#{@type}: " : ''
    end

    def to_s
      "- #{print_prefix}#{clean(@string)}"
    end
  end
end
