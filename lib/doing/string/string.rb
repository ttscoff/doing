# frozen_string_literal: true

require_relative 'highlight'
require_relative 'query'
require_relative 'tags'
require_relative 'transform'
require_relative 'truncate'
require_relative 'url'

class ::String
  include Doing::Color
  include Doing::StringHighlight
  include Doing::StringQuery
  include Doing::StringTags
  include Doing::StringTransform
  include Doing::StringTruncate
  include Doing::StringURL

  ##
  ## Force UTF-8 encoding if available
  ##
  ## @return     [String] UTF-8 encoded string
  ##
  def utf8
    if String.method_defined? :force_encoding
      dup.force_encoding('utf-8')
    else
      self
    end
  end
end
