# frozen_string_literal: true

module Doing
  ##
  ## Symbol helpers
  ##
  class ::Symbol
    def normalize_bool(default = :and)
      to_s.normalize_bool(default)
    end

    def normalize_order(default = 'asc')
      to_s.normalize_order(default)
    end

    def normalize_case(default = :smart)
      to_s.normalize_case(default)
    end
  end
end
