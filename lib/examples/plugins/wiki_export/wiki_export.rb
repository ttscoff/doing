# frozen_string_literal: true

# title: HTML Export
# description: Export styled HTML view of data
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class WikiExport
    def self.settings
      {
        trigger: 'wiki',
        templates: [
          { name: 'wiki_page', trigger: 'wiki.?page', format: 'haml', filename: 'wiki.haml' },
          { name: 'wiki_index', trigger: 'wiki.?index', format: 'haml', filename: 'wiki_index.haml' },
          { name: 'wiki_css', trigger: 'wiki.?css', format: 'css', filename: 'wiki.css' }
        ]
      }
    end

    def self.template(trigger)
      if trigger =~ /css/
        IO.read(File.join(File.dirname(__FILE__), 'templates/wiki.css'))
      elsif trigger =~ /index/
        IO.read(File.join(File.dirname(__FILE__), 'templates/wiki_index.haml'))
      else
        IO.read(File.join(File.dirname(__FILE__), 'templates/wiki.haml'))
      end
    end

    def self.render(wwid, items, variables: {})
      return if items.nil?

      opt = variables[:options]

      items_out = []
      items.each do |i|
        # if i.has_key?('note')
        #   note = '<span class="note">' + i.note.map{|n| n.strip }.join('<br>') + '</span>'
        # else
        #   note = ''
        # end
        if String.method_defined? :force_encoding
          title = i.title.force_encoding('utf-8').link_urls
          note = i.note.map { |line| line.force_encoding('utf-8').strip.link_urls } if i.note
        else
          title = i.title.link_urls
          note = i.note.map { |line| line.strip.link_urls } if i.note
        end

        interval = wwid.get_interval(i) if i.title =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
        interval ||= false

        title.gsub!(/(@([^ (]+)(\(.*?\))?)/im, '<a class="tag" href="\2.html">\1</a>').strip

        items_out << {
          date: i.date.strftime('%a %-I:%M%p'),
          title: title, # + " #{note}"
          note: note,
          time: interval,
          section: i.section
        }
      end

      template = if wwid.config['export_templates']['wiki_page'] && File.exist?(File.expand_path(wwid.config['export_templates']['wiki_haml']))
                   IO.read(File.expand_path(wwid.config['export_templates']['wiki_page']))
                 else
                   self.template('wiki_html')
                 end

      style = if wwid.config['export_templates']['wiki_css'] && File.exist?(File.expand_path(wwid.config['export_templates']['wiki_css']))
                IO.read(File.expand_path(wwid.config['export_templates']['wiki_css']))
              else
                self.template('wiki_css')
              end

      totals = opt[:totals] ? wwid.tag_times(format: :html, sort_by: opt[:sort_tags], sort_order: opt[:tag_order]) : ''
      engine = Haml::Engine.new(template)
      Doing.logger.debug('Wiki Export:', "#{items_out.count} items output to #{variables[:page_title]} wiki page")
      @out = engine.render(Object.new,
                           { :@items => items_out, :@page_title => variables[:page_title], :@style => style,
                             :@totals => totals })
    end

    Doing::Plugins.register 'wiki', :export, self
  end
end
