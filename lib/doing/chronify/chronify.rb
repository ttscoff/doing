# frozen_string_literal: true

require_relative 'array'
require_relative 'numeric'
require_relative 'string'

module Doing
  class ::String
    include ChronifyString
  end

  class ::Array
    include ChronifyArray
  end

  class ::Numeric
    include ChronifyNumeric
  end
end
