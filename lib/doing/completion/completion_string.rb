# frozen_string_literal: true

module Doing
  module Completion
    module StringUtils
      ##
      ## Get short description for command completion
      ##
      ## @return     [String] Short description
      ##
      def short_desc
        split(/[,.]/)[0].sub(/ \(.*?\)?$/, '').strip
      end

      ##
      ## Truncate string from left
      ##
      ## @param      max   The maximum number of characters
      ##
      def ltrunc(max)
        if length > max
          sub(/^.*?(.{#{max - 3}})$/, '...\1')
        else
          self
        end
      end

      def ltrunc!(max)
        replace ltrunc(max)
      end
    end
  end
end

class ::String
  include Doing::Completion::StringUtils
end
