# frozen_string_literal: true

module Doing
  ##
  ## @brief      Symbol helpers
  ##
  class ::Symbol
    def normalize_bool
      to_s.normalize_bool
    end

    def normalize_order
      to_s.normalize_order
    end
  end
end
