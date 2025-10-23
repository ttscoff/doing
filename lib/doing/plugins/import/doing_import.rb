# frozen_string_literal: true

# title: Doing Format Import
# description: Import entries from a Doing-formatted file
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class DoingImport
    include Doing::Util

    def self.settings
      {
        trigger: 'doing'
      }
    end

    ##
    ## Imports a Doing file
    ##
    ## @param      wwid     [WWID] WWID object
    ## @param      path     [String] Path to Doing file
    ## @param      options  [Hash] Additional Options
    ##
    ## @return     Nothing
    ##
    def self.import(wwid, path, options: {})
      exit_now! 'Path to Doing file required' if path.nil?

      exit_now! 'File not found' unless File.exist?(File.expand_path(path))

      options[:no_overlap] ||= false

      options[:autotag] ||= Doing.auto_tag

      tags = options[:tag] ? options[:tag].split(/[ ,]+/).map { |t| t.sub(/^@?/, '') } : []
      prefix = options[:prefix] || ''

      @old_items = wwid.content.dup

      new_items = read_doing_file(path)

      total = new_items.count

      options[:count] = 0
      new_items = wwid.filter_items(new_items, opt: options)

      skipped = total - new_items.count
      Doing.logger.debug('Skipped:', %(#{skipped} items that didn't match filter criteria)) if skipped.positive?

      imported = []
      updated = 0

      new_items.each do |item|
        next if duplicate?(item)

        title = "#{prefix} #{item.title}"
        tags.each do |tag|
          if title =~ /\b#{tag}\b/i
            title.sub!(/\b#{tag}\b/i, "@#{tag}")
          else
            title += " @#{tag}"
          end
        end
        title = wwid.autotag(title) if options[:autotag]
        title.gsub!(/ +/, ' ')
        title.strip!
        section = options[:section] || item.section
        section ||= Doing.setting('current_section')

        new_item = Item.new(item.date, title, section, item.note, item.id)

        is_match = true

        if options[:search]
          is_match = new_item.search(options[:search], case_type: options[:case], negate: options[:not])
        end

        if is_match && options[:date_filter]
          is_match = new_item.date > options[:date_filter][0] && new_item.date < options[:date_filter][1]
          is_match = options[:not] ? !is_match : is_match
        end

        if wwid.content.find_id(new_item.id)
          old_index = wwid.content.index_for_id(new_item.id)
          old_item = wwid.content[old_index].clone
          wwid.content[old_index] = new_item
          Hooks.trigger :post_entry_updated, self, new_item, old_item
          updated += 1
        elsif is_match
          imported.push(new_item)
        end
      end

      dups = new_items.count - imported.count
      Doing.logger.info('Skipped:', %(#{dups} duplicate items)) if dups.positive?

      imported = wwid.dedup(imported, no_overlap: options[:no_overlap])
      overlaps = new_items.count - imported.count - dups
      Doing.logger.debug('Skipped:', "#{overlaps} items with overlapping times") if overlaps.positive?

      imported.each do |item|
        wwid.content.add_section(item.section) unless wwid.content.section?(item.section)
        Hooks.trigger :pre_entry_add, self, item
        wwid.content.push(item)
        Hooks.trigger :post_entry_added, self, item
      end

      Doing.logger.info('Updated:', %(#{updated} items))
      Doing.logger.info('Imported:', "#{imported.count} items")
    end

    def self.duplicate?(item)
      @old_items.each do |oi|
        return true if item.equal?(oi)
      end

      false
    end

    def self.read_doing_file(path)
      doing_file = File.expand_path(path)

      return nil unless File.exist?(doing_file) && File.file?(doing_file) && File.stat(doing_file).size.positive?

      input = IO.read(doing_file)
      input = input.force_encoding('utf-8') if input.respond_to? :force_encoding

      lines = input.split(/[\n\r]/)
      current = 0

      items = []
      section = ''

      lines.each do |line|
        next if line =~ /^\s*$/

        case line
        when /^(\S[\S ]+):(\s+@[\w\-_.]+(?= |$))*\s*$/
          section = Regexp.last_match(1)
          current = 0
        when /^\s*- (\d{4}-\d\d-\d\d \d\d:\d\d) \| (.*?)(?: <([a-z0-9]{32})>)? *$/
          date = Regexp.last_match(1).strip
          title = Regexp.last_match(2).strip
          id = Regexp.last_match(3)
          item = Item.new(date, title, section, nil, id)
          items.push(item)
          current += 1
        when /^\S/
          next
        else
          next if current.zero?

          prev_item = items[current - 1]
          prev_item.note = Note.new unless prev_item.note

          prev_item.note.add(line)
          # end
        end
      end

      items
    end

    Doing::Plugins.register 'doing', :import, self
  end
end
