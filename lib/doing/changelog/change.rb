# frozen_string_literal: true

module Doing
  # A single version's entries
  class Change
    attr_reader :version, :content

    attr_accessor :entries, :change_date

    attr_writer :prefix

    def initialize(version, content, prefix: false, only: %i[changed new improved fixed])
      @version = Version.new(version)
      @content = content
      @prefix = prefix
      @only = only
      parse_entries
    end

    def parse_entries
      date = @content.match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/)
      @change_date = Time.parse(date[0]) if date

      @entries = []
      types = @content.scan(/(?<=\n|\A)#### (CHANGED|NEW|IMPROVED|FIXED)(.*?)(?=\n####|\Z)/m)
      types.each do |type|
        type[1].scan(/\s*- +(.*?)$/).each do |entry|
          @entries << Entry.new(entry[0].strip, type[0], prefix: @prefix)
        end
      end
    end

    def search_entries(search_string)
      case_type = :ignore

      matches = []

      if search_string.rx?
        matches = @entries.select { |e| e.string =~ search_string.to_rx(distance: 2, case_type: case_type) }
      else
        query = search_string.gsub(/(-)?--/, '\1]]').to_phrase_query

        if query[:must].nil? && query[:must_not].nil?
          query[:must] = query[:should]
          query[:should] = []
        end

        @entries.each do |entry|
          m = no_searches?(entry.string, query[:must_not])
          m &&= all_searches?(entry.string, query[:must])
          m &&= any_searches?(entry.string, query[:should])
          matches << entry if m
        end
      end

      @entries = matches.count.positive? ? matches : nil
    end

    def to_h
      { version: @version, content: @content }
    end

    def split_items
      items = { changed: [], new: [], improved: [], fixed: [], other: [] }

      @entries.each do |e|
        type = e.type.downcase.to_sym
        if items.key?(type)
          items[type] << e
        else
          items[:other] << e
        end
      end

      items
    end

    def to_s
      date = @change_date.nil? ? '' : " _(#{@change_date.strftime('%F')})_"
      out = ["### __#{@version}__#{date}"]

      split_items.each do |type, members|
        next unless @only.include?(type)

        if members.count.positive?
          out << "#### #{type.to_s.capitalize}"
          out << members.map(&:to_s).join("\n")
        end
      end

      out.join("\n\n")
    end

    def changes_only
      out = []

      split_items.each do |type, members|
        next unless @only.include?(type)

        out << members.map(&:to_s).join("\n")
      end

      out.join("\n")
    end

    private

    def all_searches?(text, searches)
      return true if searches.nil? || searches.empty?

      searches.each do |s|
        rx = Regexp.new(s.wildcard_to_rx, true)
        return false unless text =~ rx
      end
      true
    end

    def no_searches?(text, searches)
      return true if searches.nil? || searches.empty?

      searches.each do |s|
        rx = Regexp.new(s.wildcard_to_rx, true)
        return false if text =~ rx
      end
      true
    end

    def any_searches?(text, searches)
      return true if searches.nil? || searches.empty?

      searches.each do |s|
        rx = Regexp.new(s.wildcard_to_rx, true)
        return true if text =~ rx
      end
      false
    end
  end
end
