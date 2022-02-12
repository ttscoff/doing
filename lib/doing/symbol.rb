# frozen_string_literal: true

module Doing
  ##
  ## Symbol helpers
  ##
  class ::Symbol
    def normalize_tag_sort(default = :name)
      to_s.normalize_tag_sort
    end

    def normalize_bool(default = :and)
      to_s.normalize_bool(default)
    end

    def normalize_age(default = :newest)
      to_s.normalize_age(default)
    end

    def normalize_order(default = :asc)
      to_s.normalize_order(default)
    end

    def normalize_case(default = :smart)
      to_s.normalize_case(default)
    end

    def normalize_matching(default = :pattern)
      to_s.normalize_matching(default)
    end
  end
end
