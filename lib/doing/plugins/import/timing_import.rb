# frozen_string_literal: true

# title: Timing.app Import
# description: Import entries from a Timing.app report (JSON)
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class TimingImport
    include Doing::Util

    def self.settings
      {
        trigger: 'tim(?:ing)?'
      }
    end

    ##
    ## @brief      Imports a Timing report
    ##
    ## @param      path     (String) Path to JSON report file
    ## @param      options      (Hash) Additional Options
    ##
    def self.import(wwid, path, options: {})
      exit_now! 'Path to JSON report required' if path.nil?
      section = options[:section] || wwid.current_section
      options[:no_overlap] ||= false
      options[:autotag] ||= wwid.auto_tag
      wwid.add_section(section) unless wwid.content.key?(section)

      add_tags = options[:tag] ? options[:tag].split(/[ ,]+/).map { |t| t.sub(/^@?/, '@') } : []
      prefix = options[:prefix] || '[Timing.app]'
      exit_now! 'File not found' unless File.exist?(File.expand_path(path))

      data = JSON.parse(IO.read(File.expand_path(path)))
      new_items = []
      data.each do |entry|
        # Only process task entries
        next if entry.key?('activityType') && entry['activityType'] != 'Task'
        # Only process entries with a start and end date
        next unless entry.key?('startDate') && entry.key?('endDate')

        # Round down seconds and convert UTC to local time
        start_time = Time.parse(entry['startDate'].sub(/:\d\dZ$/, ':00Z')).getlocal
        end_time = Time.parse(entry['endDate'].sub(/:\d\dZ$/, ':00Z')).getlocal
        next unless start_time && end_time

        tags = entry['project'].split(/ ▸ /).map { |proj| proj.gsub(/[^a-z0-9]+/i, '').downcase }
        tags.concat(add_tags)
        title = "#{prefix} "
        title += entry.key?('activityTitle') && entry['activityTitle'] != '(Untitled Task)' ? entry['activityTitle'] : 'Working on'
        tags.each do |tag|
          if title =~ /\b#{tag}\b/i
            title.sub!(/\b#{tag}\b/i, "@#{tag}")
          else
            title += " @#{tag}"
          end
        end
        title = wwid.autotag(title) if options[:autotag]
        title += " @done(#{end_time.strftime('%Y-%m-%d %H:%M')})"
        title.gsub!(/ +/, ' ')
        title.strip!
        new_entry = { 'title' => title, 'date' => start_time, 'section' => section }
        new_entry['note'] = entry['notes'].split(/\n/).map(&:chomp) if entry.key?('notes')
        new_items.push(new_entry)
      end
      total = new_items.count
      new_items = wwid.dedup(new_items, options[:no_overlap])
      dups = total - new_items.count
      wwid.results.push(%(Skipped #{dups} items with overlapping times)) if dups.positive?
      wwid.content[section]['items'].concat(new_items)
      wwid.results.push(%(Imported #{new_items.count} items to #{section}))
    end

    Doing::Plugins.register 'timing', :import, self
  end
end
