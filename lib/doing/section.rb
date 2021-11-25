# frozen_string_literal: true

module Doing
  # Section Hash
  class Section < Hash
    attr_reader :items
    attr_accessor :original

    def initialize(original, items = Items.new)
      super()
      @original = original =~ /:(\s+@\S+(\(.*?\))?)*$/ ? original : "#{original}:"
      @items = items
    end

    def items=(new_items)
      @items = Items.new.concat(new_items)
    end

    def inspect
      %(#<Doing::Section @original="#{@original}" @items=#{@items.inspect}>)
    end
  end
end
