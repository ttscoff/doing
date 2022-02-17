# frozen_string_literal: true

require_relative 'tags'
require_relative 'nested_hash'

class ::Array
  ##
  ## Force UTF-8 encoding of strings in array
  ##
  ## @return     [Array] Encoded lines
  ##
  def utf8
    c = self.class
    if String.method_defined? :force_encoding
      replace c.new(map(&:utf8))
    else
      self
    end
  end
end
