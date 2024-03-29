# frozen_string_literal: true

module Doing
  # Section Object
  class Section
    attr_accessor :original, :title

    def initialize(title, original: nil)
      super()

      @title = title

      @original = if original.nil?
                    "#{title}:"
                  else
                    original =~ /:(\s+@[^ (]+(\([^)]*\))?)*?$/ ? original : "#{original}:"
                  end
    end

    def equal?(other)
      @title == other.title
    end

    # Outputs section title
    def to_s
      @title
    end

    # @private
    def inspect
      %(#<Doing::Section @title="#{@title}" @original="#{@original}">)
    end
  end
end
