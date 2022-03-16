# frozen_string_literal: true

require_relative 'array'
require_relative 'numeric'
require_relative 'string'

class ::String
  include Doing::ChronifyString
end

class ::Array
  include Doing::ChronifyArray
end

class ::Numeric
  include Doing::ChronifyNumeric
end
