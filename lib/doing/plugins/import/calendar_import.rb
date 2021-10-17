# frozen_string_literal: true

require 'json'

class CalendarImport
  include Doing::Util
  ##
  ## @brief      Imports a Timing report
  ##
  ## @param      path     (String) Path to JSON report file
  ## @param      options      (Hash) Additional Options
  ##
  def import(wwid, path, options: {})

    limit_start = options[:start].to_i
    limit_end = options[:end].to_i

    section = options[:section] || wwid.current_section
    options[:no_overlap] ||= false
    options[:autotag] ||= wwid.auto_tag

    add_section(section) unless wwid.content.has_key?(section)

    tags = options[:tag] ? options[:tag].split(/[ ,]+/).map { |t| t.sub(/^@?/, '@') } : []
    prefix = options[:prefix] ? options[:prefix] : '[Calendar.app]'

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
      new_entry = { 'title' => title, 'date' => start_time, 'section' => section }
      new_entry['note'] = entry['notes'].split(/\n/).map(&:chomp) if entry.key?('notes')
      new_items.push(new_entry)
    end
    total = new_items.count
    new_items = wwid.dedup(new_items, options[:no_overlap])
    dups = total - new_items.count
    wwid.results.push(%(Skipped #{dups} items with overlapping times)) if dups > 0
    wwid.content[section]['items'].concat(new_items)
    wwid.results.push(%(Imported #{new_items.count} items to #{section}))
  end
end

Doing::Plugins.register_plugin({
  name: 'calendar',
  type: :import,
  class: 'CalendarImport',
  trigger: 'cal(?:endar)?'
})
