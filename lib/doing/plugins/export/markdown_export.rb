# frozen_string_literal: true

# title: Markdown Export
# description: Export GFM-style task list
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  # @private
  class MarkdownRenderer
    attr_accessor :items, :page_title, :totals

    def initialize(page_title, items, totals)
      @page_title = page_title
      @items = items
      @totals = totals
    end

    def get_binding
      binding
    end
  end

  # Markdown Export Plugin
  class MarkdownExport
    include Util

    def self.settings
      {
        trigger: 'markdown|mk?d|gfm',
        templates: [{ name: 'markdown', trigger: 'mk?d|markdown', format: 'erb', filename: 'doing-markdown.erb' }]
      }
    end

    def self.template(_trigger)
      IO.read(File.join(File.dirname(__FILE__), '../../../templates/doing-markdown.erb'))
    end

    def self.render(wwid, items, variables: {})
      return if items.nil?

      opt = variables[:options]

      all_items = []
      items.each do |i|
        if String.method_defined? :force_encoding
          title = i.title.force_encoding('utf-8').link_urls(format: :markdown)
          note = i.note.map { |line| line.force_encoding('utf-8').strip.link_urls(format: :markdown) } if i.note
        else
          title = i.title.link_urls(format: :markdown)
          note = i.note.map { |line| line.strip.link_urls(format: :markdown) } if i.note
        end

        title = "#{title} @section(#{i.section})" unless variables[:is_single]

        if i.title =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
          interval = wwid.get_interval(i,
                                       record: true)
        end
        interval ||= false

        finished = i.title =~ /(?<= |^)@done/ ? true : false
        done = finished ? 'x' : ' '

        all_items << {
          date: i.date.strftime('%a %-I:%M%p'),
          shortdate: i.date.relative_date,
          flagged: i.title =~ /(?<= |^)@#{Doing.setting('marker_tag')}/,
          done: done,
          finished: finished,
          note: note,
          section: i.section,
          time: interval,
          title: title.strip
        }
      end

      template = if Doing.setting('export_templates.markdown') && File.exist?(File.expand_path(Doing.setting('export_templates.markdown')))
                   IO.read(File.expand_path(Doing.setting('export_templates.markdown')))
                 else
                   self.template(nil)
                 end

      totals = if opt[:totals]
                 wwid.tag_times(format: :markdown, sort_by: opt[:sort_tags],
                                sort_order: opt[:tag_order])
               else
                 ''
               end

      mdx = MarkdownRenderer.new(variables[:page_title], all_items, totals)
      Doing.logger.debug('Markdown Export:', "#{all_items.count} items output to Markdown")
      engine = ERB.new(template)
      @out = engine.result(mdx.get_binding)
    end

    Doing::Plugins.register 'markdown', :export, self
  end
end
