# frozen_string_literal: true

class ::String
  include Doing::Color

  def utf8
    if String.method_defined? :force_encoding
      dup.force_encoding('utf-8')
    else
      self
    end
  end
end

require_relative 'highlight'
require_relative 'query'
require_relative 'tags'
require_relative 'transform'
require_relative 'truncate'
require_relative 'url'
