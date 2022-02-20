# frozen_string_literal: true

module Doing
  # Items Array
  class Items < Array
    attr_accessor :sections

    def initialize
      super
      @sections = []
    end

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
      has_section = false
      section = section.is_a?(Section) ? section.title.downcase : section.downcase
      @sections.each do |s|
        if s.title.downcase == section
          has_section = true
          break
        end
      end
      has_section
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

      raise DoingRuntimeError, 'Section not empty' if in_section(section).count > 0

      deleted = false

      @sections.each do |sect|
        if sect.title == section && in_section(sect).count.zero?
          @sections.delete(sect)
          Doing.logger.info('Removed section:', %("#{section}" removed)) if log
          return
        end
      end

      Doing.logger.error('Not found:', %("#{section}" not found))
    end

    # Get a new Items object containing only items in a
    # specified section
    #
    # @param      section  [String] section title
    #
    # @return     [Items] Array of items
    #
    def in_section(section)
      if section =~ /^all$/i
        dup
      else
        items = Items.new.concat(select { |item| !item.nil? && item.section == section })
        items.add_section(section, log: false)
        items
      end
    end

    ##
    ## Delete an item from the index
    ##
    ## @param      item  The item
    ##
    def delete_item(item, single: false)
      deleted = delete(item)
      Doing.logger.count(:deleted)
      Doing.logger.info('Entry deleted:', deleted.title) if single
      deleted
    end

    ##
    ## Update an item in the index with a modified item
    ##
    ## @param      old_item  The old item
    ## @param      new_item  The new item
    ##
    def update_item(old_item, new_item)
      s_idx = index { |item| item.equal?(old_item) }

      raise ItemNotFound, 'Unable to find item in index, did it mutate?' unless s_idx

      return if fetch(s_idx).equal?(new_item)

      self[s_idx] = new_item
      Doing.logger.count(:updated)
      Doing.logger.info('Entry updated:', self[s_idx].title.trunc(60))
      new_item
    end

    def all_tags
      each_with_object([]) do |entry, tags|
        tags.concat(entry.tags).sort!.uniq!
      end
    end

    ##
    ## Return Items containing items that don't exist in receiver
    ##
    ## @param      items  [Items] Receiver
    ##
    def diff(items)
      diff = Items.new
      each do |item|
        res = items.select { |i| i.equal?(item) }
        diff.push(item) unless res.count.positive?
      end
      diff
    end

    ##
    ## Remove duplicated entries. Duplicate entries must have matching start date, title, note, and section
    ##
    ## @return     [Items] Items array with duplicate entries removed
    ##
    def dedup(match_section: true)
      unique = Items.new
      each do |item|
        unique.push(item) unless unique.include?(item, match_section: match_section)
      end

      unique
    end

    def dedup!(match_section: true)
      replace dedup(match_section: match_section)
    end

    def include?(item, match_section: true)
      includes = false
      each do |other_item|
        if other_item.equal?(item, match_section: match_section)
          includes = true
          break
        end
      end

      includes
    end

    # Output sections and items in Doing file format
    def to_s
      out = []
      @sections.each do |section|
        out.push(section.original)
        items = in_section(section.title).sort_by(&:date)
        items.reverse! if Doing.setting('doing_file_sort').normalize_order == :desc
        items.each { |item| out.push(item.to_s) }
      end

      out.join("\n")
    end

    # @private
    def inspect
      sections = @sections.map { |s| "<Section:#{s.title} #{in_section(s.title).count} items>" }.join(', ')
      "#<Doing::Items #{count} items, #{@sections.count} sections: #{sections}>"
    end
  end
end
