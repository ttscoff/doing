# frozen_string_literal: true

module Doing
  class Items < Array
    # List sections, title only
    #
    # @return     [Array] section titles
    #
    def section_titles
      @sections.map(&:title)
    end

    # Test if section already exists
    #
    # @param      section  [String] section title
    #
    # @return     [Boolean] true if section exists
    #
    def section?(section)
      section = section.is_a?(Section) ? section.title.downcase : section.downcase
      @sections.map { |i| i.title.downcase }.include?(section)
    end

    ##
    ## Return the best section match for a search query
    ##
    ## @param      frag      The search query
    ## @param      distance  The distance apart characters can be (fuzziness)
    ##
    ## @return     [Section] (first) matching section object
    ##
    def guess_section(frag, distance: 2)
      section = nil
      re = frag.to_rx(distance: distance, case_type: :ignore)
      @sections.each do |sect|
        next unless sect.title =~ /#{re}/i

        Doing.logger.debug('Match:', %(Assuming "#{sect.title}" from "#{frag}"))
        section = sect
        break
      end

      section
    end

    # Add a new section to the sections array. Accepts
    # either a Section object, or a title string that will
    # be converted into a Section.
    #
    # @param      section  [Section] The section to add. A
    #                      String value will be converted to
    #                      Section automatically.
    # @param      log      [Boolean] Add a log message
    #                      notifying the user about the
    #                      creation of the section.
    #
    # @return     nothing
    #
    def add_section(section, log: false)
      section = section.is_a?(Section) ? section : Section.new(section.cap_first)

      return if section?(section)

      @sections.push(section)
      Doing.logger.info('New section:', %("#{section}" added)) if log
    end

    def delete_section(section, log: false)
      return unless section?(section)

      raise DoingRuntimeError, 'Section not empty' if in_section(section).count.positive?

      @sections.each do |sect|
        next unless sect.title == section && in_section(sect).count.zero?

        @sections.delete(sect)
        Doing.logger.info('Removed section:', %("#{section}" removed)) if log
      end

      Doing.logger.error('Not found:', %("#{section}" not found))
    end
  end
end
