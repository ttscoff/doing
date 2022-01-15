# frozen_string_literal: true

module Doing
  ##
  ## This class describes an item note.
  ##
  class Note < Array

    ##
    ## Initializes a new note
    ##
    ## @param      note  [Array] Initial note, can be string
    ##                   or array
    ##
    def initialize(note = [])
      super()

      add(note) if note
    end

    ##
    ## Add note contents, optionally replacing existing note
    ##
    ## @param      note     [Array] The note to add, can be
    ##                      String, Array, or Note
    ## @param      replace  [Boolean] replace existing
    ##                      content
    ##
    def add(note, replace: false)
      clear if replace
      if note.is_a?(String)
        append_string(note)
      elsif note.is_a?(Array)
        append(note)
      end
    end

    ##
    ## Remove blank lines and comments (#)
    ##
    ## @return     [Array] compressed array
    ##
    def compress
      delete_if { |l| l =~ /^\s*$/ || l =~ /^#/ }
    end

    def compress!
      replace compress
    end

    ##
    ## Remove leading/trailing whitespace for
    ##             every line of note
    ##
    ## @return     [Array] Stripped note
    ##
    def strip_lines
      map(&:strip)
    end

    def strip_lines!
      replace strip_lines
    end

    ##
    ## Note as multi-line string
    def to_s
      compress.strip_lines.map { |l| "\t\t#{l}" }.join("\n")
    end

    # @private
    def inspect
      "<Doing::Note - characters:#{compress.strip_lines.join(' ').length} lines:#{count}>"
    end

    ##
    ## Test if a note is equal (compare string
    ##             representations)
    ##
    ## @param      other  [Note] The other Note
    ##
    ## @return     [Boolean] true if equal
    def equal?(other)
      return false unless other.is_a?(Note)

      to_s == other.to_s
    end

    private

    ##
    ## Append an array of strings to note
    ##
    ## @param      lines  [Array] Array of strings
    ##
    def append(lines)
      concat(lines)
      replace compress
    end

    ##
    ## Append a string to the note content
    ##
    ## @param      input  [String] The input string,
    ##                    newlines will be split
    ##
    def append_string(input)
      concat(input.split(/\n/).map(&:strip))
      replace compress
    end
  end
end
