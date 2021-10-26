# frozen_string_literal: true

module Doing
  ##
  ## @brief      This class describes an item note.
  ##
  class Note < Array
    def initialize(note = [])
      super()

      add(note) if note
    end

    def add(note, replace: false)
      clear if replace
      if note.is_a?(String)
        append_string(note)
      elsif note.is_a?(Array)
        append(note)
      end
    end

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

    def equal?(other)
      return false unless other.is_a?(Note)

      to_s == other.to_s
    end
  end
end
