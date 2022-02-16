# frozen_string_literal: true

module Doing
  # A collection of Changes
  class Changes
    attr_reader :changes
    attr_writer :changes_only

    def initialize(lookup: nil, search: nil, changes: false, sort: :desc)
      @changes_only = changes
      changelog = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'CHANGELOG.md'))
      raise 'Error locating changelog' unless File.exist?(changelog)

      @content = IO.read(changelog)
      parse_changes(lookup, search)

      @changes.reverse! if sort == :asc
    end

    def latest
      if @changes_only
        @changes[0].changes_only.force_encoding('utf-8')
      else
        @changes[0].to_s.force_encoding('utf-8')
      end
    end

    def versions
      @changes.select { |change| change.entries&.count > 0 }.map { |change| change.version }
    end

    def interactive
      Doing::Prompt.choose_from(versions,
                                prompt: 'Select a version to see its changelog',
                                sorted: false,
                                fzf_args: [
                                  %(--preview='doing changes --render -l {1}'),
                                  '--disabled',
                                  '--height=50',
                                  '--preview-window="right,70%"'
                                ])
    end

    def to_s
      if @changes_only
        @changes.map(&:changes_only).join().force_encoding('utf-8')
      else
        @changes.map(&:to_s).join("\n\n").force_encoding('utf-8')
      end
    end

    private

    def parse_changes(lookup, search)
      change_rx = /(?<=\n|\A)### (\d+\.\d+\.\d+(?:\w*))(.*?)(?=\n### |\Z)/m
      @changes = @content.scan(change_rx).each_with_object([]) do |m, a|
        next if m[0].nil? || m[1].nil?

        a << Change.new(m[0], m[1].strip)
      end

      lookup(lookup) unless lookup.nil?
      search(search) unless search.nil?
    end

    def lookup(lookup_version)
      range = []

      if lookup_version =~ /([\d.]+) *(?:-|to)+ *([\d.]+)/
        m = Regexp.last_match
        lookup("> #{m[1]}")
        lookup("< #{m[2]}")
      elsif lookup_version.scan(/(?:<=?|prior|before|older|>=?|since|after|newer) *[0-9*?.]+/).count > 1
        params = lookup_version.scan(/(?:<=?|prior|before|older|>=?|since|after|newer) *[0-9*?.]+/)
        params.each { |query| lookup(query) }
      else
        inclusive = lookup_version =~ /=/ ? true : false
        comp = case lookup_version
               when /(<|prior|before|older)/
                 :older
               when /(>|since|after|newer)/
                 :newer
               else
                 :equal
               end
        version = Version.new(lookup_version)

        @changes.select! do |change|
          change.version.compare(version, comp, inclusive: inclusive)
        end
      end
    end

    def search(query)
      @changes.map do |c|
        c.entries = c.search_entries(query)
      end

      @changes.delete_if { |c| c.nil? || c.entries.nil? }
    end
  end
end
