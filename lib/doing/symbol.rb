# frozen_string_literal: true

module Doing
  ##
  ## @brief      Symbol helpers
  ##
  class ::Symbol
    def normalize_bool!
      replace normalize_bool
    end

    def normalize_bool
      to_s.normalize_bool
    end
  end
end
