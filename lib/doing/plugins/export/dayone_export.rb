# frozen_string_literal: true

require 'securerandom'

# title: Day One Export
# description: Export entries to Day One plist for auto import
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class DayOneRenderer
    attr_accessor :items, :page_title, :totals

    def initialize(page_title, items, totals)
      @page_title = page_title
      @items = items
      @totals = totals
    end

    def get_binding
      binding()
    end
  end

  class DayoneExport
    include Doing::Util

    def self.settings
      {
        trigger: 'day(?:one)?(?:-(?:days?|entries))?',
        templates: [
          { name: 'dayone', trigger: 'day(?:one)?$', format: 'erb', filename: 'dayone.erb' },
          { name: 'dayone_entry', trigger: 'day(?:one)-entr(?:y|ies)?$', format: 'erb', filename: 'dayone-entry.erb' }
        ]
      }
    end

    def self.template(trigger)
      case trigger
      when /day(?:one)-entr(?:y|ies)?$/
        IO.read(File.join(File.dirname(__FILE__), '../../../templates/doing-dayone-entry.erb'))
      else
        IO.read(File.join(File.dirname(__FILE__), '../../../templates/doing-dayone.erb'))
      end
    end

    def self.render(wwid, items, variables: {})

      return if items.nil?

      opt = variables[:options]
      trigger = opt[:output]
      digest = case trigger
               when /-days?$/
                 :day
               when /-entries$/
                 :entries
               else
                 :digest
               end

      all_items = []
      days = {}
      flagged = false
      tags = []

      items.each do |i|
        day_flagged = false
        date_key = i.date.strftime('%Y-%m-%d')

        if String.method_defined? :force_encoding
          title = i.title.force_encoding('utf-8').link_urls(format: :markdown)
          note = i.note.map { |line| line.force_encoding('utf-8').strip.link_urls(format: :markdown) } if i.note
        else
          title = i.title.link_urls(format: :markdown)
          note = i.note.map { |line| line.strip.link_urls(format: :markdown) } if i.note
        end

        title = "#{title} @section(#{i.section})" unless variables[:is_single]

        tags.concat(i.tag_array).sort!.uniq!
        flagged = day_flagged = true if i.tags?(wwid.config['marker_tag'])

        interval = wwid.get_interval(i, record: true) if i.title =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
        interval ||= false
        human_time = false
        if interval
          d, h, m = wwid.get_interval(i, formatted: false).format_time
          human_times = []
          human_times << format('%<d>d day%<p>s', d: d, p: d == 1 ? '' : 's') if d > 0
          human_times << format('%<h>d hour%<p>s', h: h, p: h == 1 ? '' : 's') if h > 0
          human_times << format('%<m>d minute%<p>s', m: m, p: m == 1 ? '' : 's') if m > 0
          human_time = human_times.join(', ')
        end

        done = i.tags?('done') ? ' ' : ' '

        item = {
          date_object: i.date,
          date: i.date.strftime('%a %-I:%M%p'),
          shortdate: i.date.relative_date,
          done: done,
          note: note,
          section: i.section,
          time: interval,
          human_time: human_time,
          title: title.strip,
          starred: day_flagged,
          tags: i.tag_array
        }
        all_items << item


        if days.key?(date_key)
          days[date_key][:starred] = true if day_flagged
          days[date_key][:tags] = days[date_key][:tags].concat(i.tag_array).sort.uniq
          days[date_key][:entries].push(item)
        else
          days[date_key] ||= { tags: [], entries: [], starred: false }
          days[date_key][:starred] = true if day_flagged
          days[date_key][:tags] = days[date_key][:tags].concat(i.tag_array).sort.uniq
          days[date_key][:entries].push(item)
        end
      end


      template = if wwid.config['export_templates']['dayone'] && File.exist?(File.expand_path(wwid.config['export_templates']['dayone']))
                   IO.read(File.expand_path(wwid.config['export_templates']['dayone']))
                 else
                   self.template('dayone')
                 end

      totals = opt[:totals] ? wwid.tag_times(format: :markdown, sort_by_name: opt[:sort_tags], sort_order: opt[:tag_order]) : ''

      case digest
      when :day
        days.each do |k, hsh|
          title = "#{k}: #{variables[:page_title]}"
          to_dayone(template: template,
                    title: title,
                    items: hsh[:entries],
                    totals: '',
                    date: Time.parse(k),
                    tags: tags,
                    starred: hsh[:starred])
        end
      when :entries
        entry_template = if wwid.config['export_templates']['dayone_entry'] && File.exist?(File.expand_path(wwid.config['export_templates']['dayone_entry']))
                           IO.read(File.expand_path(wwid.config['export_templates']['dayone_entry']))
                         else
                           self.template('dayone-entry')
                         end
        all_items.each do |item|
          to_dayone(template: entry_template,
                    title: '',
                    items: [item],
                    totals: '',
                    date: item[:date_object],
                    tags: item[:tags],
                    starred: item[:starred])
        end
      else
        to_dayone(template: template,
                    title: variables[:page_title],
                    items: all_items,
                    totals: totals,
                    date: Time.now,
                    tags: tags,
                    starred: flagged)
      end

      @out = ''
    end

    def self.to_dayone(template: self.template(nil), title: 'doing', items: [], totals: '', date: Time.now, tags: [], starred: false)
      mdx = DayOneRenderer.new(title, items, totals)

      engine = ERB.new(template)
      content = engine.result(mdx.get_binding)

      uuid = SecureRandom.uuid
      # uuid = `uuidgen`.strip

      plist = {
        'Creation Date' => date,
        'Creator' => { 'Software Agent' => 'Doing/2.0.0' },
        'Entry Text' => content,
        'Starred' => starred,
        'Tags' => tags.sort.uniq.delete_if { |t| t =~ /(done|cancell?ed|from)/ },
        'UUID' => uuid
      }

      container = File.expand_path('~/Library/Group Containers/')
      dayone_dir = Dir.glob('*.dayoneapp2', base: container).first
      import_dir = File.join(container, dayone_dir, 'Data', 'Auto Import', 'Default Journal.dayone', 'entries')
      FileUtils.mkdir_p(import_dir) unless File.exist?(import_dir)
      entry_file = File.join(import_dir, "#{uuid}.doentry")
      Doing.logger.debug('Day One Export:', "Exporting to #{entry_file}")
      File.open(entry_file, 'w') do |f|
        f.puts plist.to_plist
      end

      Doing.logger.count(:exported, level: :info, count: items.count, message: '%count %items exported to Day One import folder')
    end

    Doing::Plugins.register 'dayone', :export, self
    Doing::Plugins.register 'dayone-days', :export, self
    Doing::Plugins.register 'dayone-entries', :export, self
  end
end
