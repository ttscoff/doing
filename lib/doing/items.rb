# frozen_string_literal: true

module Doing
  # Items Array
  class Items < Array
    attr_accessor :sections

    def initialize
      super
      @sections = []
    end

    def inspect
      "#<Doing::Items #{count} items, #{@sections.count} sections: #{@sections.map { |s| "<Section:#{s.title} #{in_section(s.title).count} items>" }.join(', ')}>"
    end

    def section_titles
      @sections.map(&:title)
    end

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

    def add_section(section, log: false)
      section = section.is_a?(Section) ? section : Section.new(section.cap_first)

      return if section?(section)

      @sections.push(section)
      Doing.logger.info('New section:', %("#{section}" added)) if log
    end

    def in_section(section)
      if section =~ /^all$/i
        dup
      else
        items = Items.new.concat(select { |item| item.section == section })
        items.add_section(section, log: false)
        items
      end
    end

    def to_s
      out = []
      @sections.each do |section|
        out.push(section.original)
        in_section(section.title).each { |item| out.push(item.to_s)}
      end

      out.join("\n")
    end
  end
end
