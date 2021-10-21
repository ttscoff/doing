# frozen_string_literal: true

# title: Doing Format Import
# description: Import entries from a Doing-formatted file
# author: Brett Terpstra
# url: https://brettterpstra.com
# module Doing
#   class DoingImport
#     include Doing::Util

#     def self.settings
#       {
#         trigger: 'doing'
#       }
#     end

#     ##
#     ## @brief      Imports a Doing file
#     ##
#     ## @param      wwid     WWID object
#     ## @param      path     (String) Path to Doing file
#     ## @param      options  (Hash) Additional Options
#     ##
#     ## @return     Nothing
#     ##
#     def self.import(wwid, path, options: {})
#       exit_now! 'Path to Doing file required' if path.nil?
#       section = options[:section] || wwid.current_section
#       options[:no_overlap] ||= false
#       options[:autotag] ||= wwid.auto_tag
#       wwid.add_section(section) unless wwid.content.key?(section)

#       add_tags = options[:tag] ? options[:tag].split(/[ ,]+/).map { |t| t.sub(/^@?/, '@') } : []
#       prefix = options[:prefix] || ''
#       exit_now! 'File not found' unless File.exist?(File.expand_path(path))

#       old_content = wwid.content
#       wwid.init_doing_file(File.expand_path(path))

#       new_items = wwid.content['items']
#       new_items.each do |entry|

#         start_time = item.date
#         end_time =
#         next unless start_time && end_time

#         tags = entry['project'].split(/ ▸ /).map { |proj| proj.gsub(/[^a-z0-9]+/i, '').downcase }
#         tags.concat(add_tags)
#         title = "#{prefix} "
#         title += entry.key?('activityTitle') && entry['activityTitle'] != '(Untitled Task)' ? entry['activityTitle'] : 'Working on'
#         tags.each do |tag|
#           if title =~ /\b#{tag}\b/i
#             title.sub!(/\b#{tag}\b/i, "@#{tag}")
#           else
#             title += " @#{tag}"
#           end
#         end
#         title = wwid.autotag(title) if options[:autotag]
#         title += " @done(#{end_time.strftime('%Y-%m-%d %H:%M')})"
#         title.gsub!(/ +/, ' ')
#         title.strip!
#         new_item = Item.new(start_time, title, section)
#         new_item.note.append_string(entry['notes']) if entry.key?('notes')
#         new_items.push(new_item)
#       end
#       total = new_items.count
#       new_items = wwid.dedup(new_items, options[:no_overlap])
#       dups = total - new_items.count
#       wwid.results.push(%(Skipped #{dups} items with overlapping times)) if dups.positive?
#       wwid.content[section]['items'].concat(new_items)
#       wwid.results.push(%(Imported #{new_items.count} items to #{section}))
#     end

#     Doing::Plugins.register 'doing', :import, self
#   end
# end
