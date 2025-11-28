# frozen_string_literal: true

require_relative 'dates'
require_relative 'tags'
require_relative 'state'
require_relative 'query'

module Doing
  ##
  ## This class describes a single WWID item
  ##
  class Item
    include ItemDates
    include ItemQuery
    include ItemState
    include ItemTags

    attr_accessor :date, :title, :section, :note, :id

    # attr_reader :id

    include Color

    ##
    ## Initialize an item with date, title, section, and
    ## optional note
    ##
    ## @param      date     [Time] The item's start date
    ## @param      title    [String] The title
    ## @param      section  [String] The section to which
    ##                      the item belongs
    ## @param      note     [Array or String] The note
    ##                      (optional)
    ## @param      id       MD5 identifier
    ##
    def initialize(date, title, section, note = nil, id = nil)
      @date = date.is_a?(Time) ? date : Time.parse(date)
      @title = title
      @section = section
      @note = Note.new(note)
      @id = id&.valid_id? ? id.strip : gen_id
    end

    def gen_id
      Digest::MD5.hexdigest(to_s)
    end

    ##
    ## Test for equality between items
    ##
    ## @param      other          [Item] The other item
    ## @param      match_section  [Boolean] If true, require item sections to match
    ##
    ## @return     [Boolean] is equal?
    ##
    def equal?(other, match_section: false)
      return false if @title.strip != other.title.strip

      return false if @date != other.date

      return false unless @note.equal?(other.note)

      return false if match_section && !@section.equal?(other.section)

      true
    end

    ##
    ## Move item from current section to destination section
    ##
    ## @param      new_section  [String] The destination
    ##                          section
    ## @param      label        [Boolean] add @from(original
    ##                          section) tag
    ## @param      log          [Boolean] log this action
    ##
    ## @return     nothing
    ##
    def move_to(new_section, label: true, log: true)
      from = @section

      tag('from', rename_to: 'from', value: from, force: true) if label
      @section = new_section

      Doing.logger.count(@section == 'Archive' ? :archived : :moved) if log
      Doing.logger.debug("#{@section == 'Archive' ? 'Archived' : 'Moved'}:",
                         "#{@title.trunc(60)} from #{from} to #{@section}")
      self
    end

    # outputs item in Doing file format, including leading tab
    def to_s
      "\t- #{@date.strftime('%Y-%m-%d %H:%M')} | #{@title} <#{@id}>#{@note.good? ? "\n#{@note}" : ''}"
    end

    ##
    ## outputs a colored string with relative date and highlighted tags
    ##
    ## @return     Pretty representation of the object.
    ##
    def to_pretty(elements: %i[date title section])
      output = []
      elements.each do |e|
        case e
        when :date
          output << format('%13s |', @date.relative_date).cyan
        when :section
          output << "#{Color.magenta}(#{Color.white(@section)}#{Color.magenta})"
        when :title
          output << @title.white.highlight_tags('cyan')
        end
      end

      output.join(' ')
    end

    # @private
    def inspect
      # %(<Doing::Item @date=#{@date} @title="#{@title}" @section:"#{@section}" @note:#{@note.to_s}>)
      %(<Doing::Item @date=#{@date.strftime('%F %T')} @section=#{@section} @title=#{@title.trunc(30)}>)
    end

    def clone
      Marshal.load(Marshal.dump(self))
    end
  end
end
