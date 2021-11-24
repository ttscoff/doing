# frozen_string_literal: true

# title: Capture Thing Import
# description: Import entries from a Capture Thing folder
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class CaptureThingImport
    require 'time'
    include Doing::Util
    include Doing::Errors

    def self.settings
      {
        trigger: '^cap(?:ture)?(:?thing)?'
      }
    end

    ##
    ## Imports a Capture Thing folder
    ##
    ## @param      wwid     [WWID] WWID object
    ## @param      path     [String] Path to Capture Thing folder
    ## @param      options  [Hash] Additional Options
    ##
    def self.import(wwid, path, options: {})
      raise InvalidArgument, 'Path to Capture Thing folder required' if path.nil?

      path = File.expand_path(path)

      raise InvalidArgument, 'File not found' unless File.exist?(path)

      raise InvalidArgument, 'Path is not a directory' unless File.directory?(path)

      options[:no_overlap] ||= false
      options[:autotag] ||= wwid.auto_tag

      tags = options[:tag] ? options[:tag].split(/[ ,]+/).map { |t| t.sub(/^@?/, '') } : []
      options[:tag] = nil
      prefix = options[:prefix] || ''

      @old_items = []

      wwid.content.each { |_, v| @old_items.concat(v[:items]) }

      new_items = read_capture_folder(path)

      total = new_items.count

      options[:count] = 0

      new_items = wwid.filter_items(new_items, opt: options)

      skipped = total - new_items.count
      Doing.logger.debug('Skipped:' , %(#{skipped} items that didn't match filter criteria)) if skipped.positive?

      imported = []

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
        section ||= wwid.config['current_section']

        new_item = Item.new(item.date, title, section)
        new_item.note = item.note

        imported.push(new_item)
      end

      dups = new_items.count - imported.count
      Doing.logger.info('Skipped:', %(#{dups} duplicate items)) if dups.positive?

      imported = wwid.dedup(imported, !options[:overlap])
      overlaps = new_items.count - imported.count - dups
      Doing.logger.debug('Skipped:', "#{overlaps} items with overlapping times") if overlaps.positive?

      imported.each do |item|
        wwid.add_section(item.section) unless wwid.content.key?(item.section)
        wwid.content[item.section][:items].push(item)
      end

      Doing.logger.info('Imported:', "#{imported.count} items")
    end

    def self.duplicate?(item)
      @old_items.each do |oi|
        return true if item.equal?(oi)
      end

      false
    end

    def self.parse_entry(date, entry)
      lines = entry.strip.split(/\n/)

      return nil if lines.nil?

      time_line = lines.shift

      return nil unless time_line =~ /^# (\d+:\d{2} [AP]M)/

      m = time_line.match(/^# (\d+:\d{2} [AP]M)/)

      unless m
        Doing.logger.debug("Error parsing time #{time_line}")
        return nil
      end

      time = m[1]
      entry_date = Time.parse("#{date} #{time}")

      title = ''
      note = Note.new
      lines.each_with_index do |l, i|
        if l =~ /^-{4,}/
          note.add(lines.slice(i + 1, lines.count - i))
          break
        else
          title += l
        end
      end

      Item.new(entry_date, title, nil, note)
    end

    def self.read_capture_folder(path)
      folder = File.expand_path(path)

      return nil unless File.exist?(folder) && File.directory?(folder)

      items = []

      files = Dir.glob('**/*.md', base: folder)

      files.each do |file|
        date = File.basename(file, '.md').match(/^(\d{4}-\d{2}-\d{2})/)[1]
        input = IO.read(File.join(folder, file))
        input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
        entries = input.split(/^\* \* \* \* \*$/).map(&:strip).delete_if(&:empty?)

        entries.each do |entry|
          new_entry = parse_entry(date, entry)
          items << new_entry if new_entry
        end
      end

      items
    end

    Doing::Plugins.register 'capturething', :import, self
  end
end
