# frozen_string_literal: true

module Doing
  # Items Array
  class Items < Array
    def inspect
      "#<Doing::Items - #{count} items>"
    end

    def items_for_section(section)
      select { |item| item.section == section }
    end
  end
end
