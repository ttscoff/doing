# frozen_string_literal: true

module Doing
  ##
  ## Array helpers
  ##
  class ::Array
    def to_tags
      map { |t| t.sub(/^@?/, '@') }
    end

    def highlight_tags(color = 'cyan')
      tag_color = Doing::Color.send(color)
      to_tags.map { |t| "#{tag_color}#{t}" }
    end

    def log_tags
      highlight_tags.join(', ')
    end
  end
end
