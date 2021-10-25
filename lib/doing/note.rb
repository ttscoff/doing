# frozen_string_literal: true

module Doing
  ##
  ## @brief      This class describes an item note.
  ##
  class Note < Array
    def append(lines)
      concat(lines)
      replace compress
    end

    def append_string(input)
      concat(input.split(/\n/).map(&:strip))
      replace compress
    end

    def compress!
      replace compress
    end

    def compress
      delete_if { |l| l =~ /^\s*$/ || l =~ /^#/ }
    end

    def strip_lines!
      replace strip_lines
    end

    def strip_lines
      map(&:strip)
    end

    def to_s
      compress.strip_lines.join("\n")
    end


  end
end
