# frozen_string_literal: true

module Doing
  # An individual changelog item
  class Entry
    attr_reader :type, :string

    def initialize(string, type)
      @string = string
      @type = type
    end

    def clean(string)
      string.gsub(/\|/, '\|')
    end

    def to_s
      "- #{clean(@string)}"
    end
  end
end
