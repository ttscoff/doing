module Doing
  module Completion
    module StringUtils
      def short_desc
        split(/[,.]/)[0].sub(/ \(.*?\)?$/, '').strip
      end

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

    class ::String
      include StringUtils
    end
  end
end
