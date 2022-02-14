# frozen_string_literal: true

class ::String
  include Doing::Color
end

require_relative 'highlight'
require_relative 'query'
require_relative 'tags'
require_relative 'transform'
require_relative 'truncate'
require_relative 'url'
