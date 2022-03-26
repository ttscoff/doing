# frozen_string_literal: true

# title: JSON Import
# description: Import entries from a Doing JSON export
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  # JSON importer
  class JSONImport
    include Doing::Util

    def self.settings
      {
        trigger: 'json'
      }
    end

    ##
    ## Imports a Timing report
    ##
    ## @param      wwid     [WWID] The wwid object
    ## @param      path     [String] Path to JSON report
    ##                      file
    ## @param      options  [Hash] Additional Options
    ##
    def self.import(wwid, path, options: {})
      exit_now! 'Path to JSON export required' if path.nil?
      options[:no_overlap] ||= false
      options[:autotag] ||= Doing.auto_tag

      exit_now! 'File not found' unless File.exist?(File.expand_path(path))

      updated = 0
      added = 0
      skipped = 0

      data = JSON.parse(IO.read(File.expand_path(path)))
      new_items = []
      new_section = options[:section] || Doing.setting('current_section')

      data['items'].each do |entry|
        title = entry['title']
        date = Time.parse(entry['date'])
        date ||= entry['date'].chronify
        note = Doing::Note.new(entry['note'])
        section = if entry['section'].empty?
                    new_section
                  else
                    entry['section']
                  end
        id = entry.key?('id') ? entry['id'] : nil

        new_item = Doing::Item.new(date, title, section, note, id)

        is_match = true

        if options[:search]
          is_match = new_item.search(options[:search], case_type: options[:case], negate: options[:not])
        end

        if is_match && options[:date_filter]
          is_match = start_time > options[:date_filter][0] && start_time < options[:date_filter][1]
          is_match = options[:not] ? !is_match : is_match
        end

        unless is_match
          skipped += 1
          next

        end

        if wwid.content.find_id(new_item.id)
          old_index = wwid.content.index_for_id(entry['id'])
          old_item = wwid.content[old_index].clone
          wwid.content[old_index] = new_item
          Hooks.trigger :post_entry_updated, self, new_item, old_item
          updated += 1
        else
          Hooks.trigger :pre_entry_add, self, item
          wwid.content << new_entry
          Hooks.trigger :post_entry_added, self, item
          added += 1
        end
      end
      total = new_items.count
      skipped = data.count - total
      Doing.logger.debug('Skipped:', %(#{skipped} items)) if skipped.positive?
      Doing.logger.info('Updated:', %(#{updated} items))
      Doing.logger.info('Imported:', %(#{added} new items to #{new_section}))
    end

    Doing::Plugins.register 'json', :import, self
  end
end
