# frozen_string_literal: true

# title: Calendar.app Import
# description: Import entries from a Calendar.app calendar
# author: Brett Terpstra
# url: https://brettterpstra.com
require 'json'

module Doing
  ##
  ## Plugin for importing from Calendar.app on macOS
  ##
  class CalendarImport
    include Doing::Util

    def self.settings
      {
        trigger: 'i?cal(?:endar)?'
      }
    end

    def self.import(wwid, _path, options: {})
      limit_start = options[:start].to_i
      limit_end = options[:end].to_i

      section = options[:section] || Doing.setting('current_section')
      options[:no_overlap] ||= false
      options[:autotag] ||= Doing.auto_tag

      wwid.content.add_section(section) unless wwid.content.section?(section)

      tags = options[:tag] ? options[:tag].split(/[ ,]+/).map { |t| t.sub(/^@?/, '') } : []
      prefix = options[:prefix] || '[Calendar.app]'

      script = File.join(File.dirname(__FILE__), 'cal_to_json.scpt')
      res = `/usr/bin/osascript "#{script}" #{limit_start} #{limit_end}`.strip
      data = JSON.parse(res)

      new_items = []
      data.each do |entry|
        # Only process entries with a start and end date
        next unless entry.key?('start') && entry.key?('end')

        # Round down seconds and convert UTC to local time
        start_time = Time.parse(entry['start']).getlocal
        end_time = Time.parse(entry['end']).getlocal
        next unless start_time && end_time

        title = "#{prefix} "
        title += entry['name']
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
        new_entry = Item.new(start_time, title, section)
        new_entry.note = entry['notes'].split(/\n/).map(&:chomp) if entry.key?('notes')

        is_match = true

        if options[:search]
          is_match = new_entry.search(options[:search], case_type: options[:date], negate: options[:not])
        end

        if is_match && options[:date_filter]
          is_match = start_time > options[:date_filter][0] && start_time < options[:date_filter][1]
          is_match = options[:not] ? !is_match : is_match
        end

        new_items.push(new_entry) if is_match
      end
      total = new_items.count

      new_items = wwid.filter_items(new_items, opt: options)
      filtered = total - new_items.count
      Doing.logger.debug('Skipped:', %(#{filtered} items that didn't match filter criteria)) if filtered.positive?

      new_items = wwid.dedup(new_items, no_overlap: options[:no_overlap])
      dups = filtered - new_items.count
      Doing.logger.info(%(Skipped #{dups} items with overlapping times)) if dups.positive?

      new_items.map { |item| Hooks.trigger :pre_entry_add, self, item }

      wwid.content.concat(new_items)

      new_items.map { |item| Hooks.trigger :post_entry_added, self, item }

      Doing.logger.info(%(Imported #{new_items.count} items to #{section}))
    end

    Doing::Plugins.register 'calendar', :import, self
  end
end
