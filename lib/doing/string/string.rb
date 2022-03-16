# frozen_string_literal: true

require_relative 'highlight'
require_relative 'query'
require_relative 'tags'
require_relative 'transform'
require_relative 'truncate'
require_relative 'url'

module Doing
  class ::String
    include Color
    include StringHighlight
    include StringQuery
    include StringTags
    include StringTransform
    include StringTruncate
    include StringURL

    def utf8
      if String.method_defined? :force_encoding
        dup.force_encoding('utf-8')
      else
        self
      end
    end
  end
end
