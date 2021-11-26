# frozen_string_literal: true

module Doing
  # Items Array
  class Items < Array
    attr_accessor :sections

    def initialize
      super
      @sections = Array.new
    end

    def inspect
      "#<Doing::Items - #{@sections.map { |s| "<Section:#{s.title} #{in_section(s.title).count} items>" }.join(', ')}>"
    end

    def section_titles
      @sections.map { |s| s.title }
    end

    def section?(section)
      has_section = false
      @sections.each do |s|
        if s.title.downcase == section.downcase
          has_section = true
          break
        end
      end
      has_section
    end

    def add_section(section, log: true)
      if section.is_a?(Section)
        unless section?(section.title)
          @sections.push(section)
          Doing.logger.info('New section:', %("#{section}" added)) if log
        end
      else
        unless section?(section)
          @sections.push(Section.new(section.cap_first))
          Doing.logger.info('New section:', %("#{section}" added)) if log
        end
      end
    end

    def in_section(section)
      if section =~ /^all$/i
        dup
      else
        select { |item| item.section == section }
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
