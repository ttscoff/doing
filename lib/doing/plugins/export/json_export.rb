# frozen_string_literal: true

# title: JSON Export
# description: Export JSON-formatted data, including entry durations and tag totals
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class JSONExport
    include Doing::Util

    def self.settings
      {
        trigger: 'json|time(?:line)?'
      }
    end

    def self.render(wwid, items, variables: {})
      return if items.nil?

      opt = variables[:options]
      opt[:output] =  case opt[:output]
                      when /^t/
                        'timeline'
                      else
                        'json'
                      end
      items_out = []
      last_date = items[-1].date + (60 * 60 * 24)
      max = last_date.strftime('%F')
      min = items[0].date.strftime('%F')
      items.each_with_index do |i, index|
        if String.method_defined? :force_encoding
          title = i.title.force_encoding('utf-8')
          note = i.note.map { |line| line.force_encoding('utf-8').strip } if i.note
        else
          title = i.title
          note = i.note.map { |line| line.strip } if i.note
        end

        end_date = i.end_date || ''
        interval = wwid.get_interval(i, formatted: false) || 0
        note ||= ''

        tags = []
        attributes = {}
        skip_tags = %w[meanwhile done cancelled flagged]
        i.title.scan(/@([^(\s]+)(?:\((.*?)\))?/).each do |tag|
          tags.push(tag[0]) unless skip_tags.include?(tag[0])
          attributes[tag[0]] = tag[1] if tag[1]
        end

        if opt[:output] == 'json'

          i = {
            date: i.date,
            end_date: end_date,
            title: title.strip, #+ " #{note}"
            note: note.instance_of?(Array) ? note.to_s : note,
            time: interval.time_string(format: :clock),
            tags: tags
          }

          attributes.each { |attr, val| i[attr.to_sym] = val }

          items_out << i

        elsif opt[:output] == 'timeline'
          new_item = {
            'id' => index + 1,
            'content' => title.strip, #+ " #{note}"
            'title' => title.strip + " (#{interval.time_string(format: :clock)})",
            'start' => i.date.strftime('%F %T'),
            'type' => 'box',
            'style' => 'color:#4c566b;background-color:#d8dee9;'
          }


          if interval && interval.to_i > 0
            new_item['end'] = end_date.strftime('%F %T')
            if interval.to_i > 3600
              new_item['type'] = 'range'
              new_item['style'] = 'color:white;background-color:#a2bf8a;'
            end
          end
          new_item['style'] = 'color:white;background-color:#f7921e;' if i.tags?(wwid.config['marker_tag'])
          items_out.push(new_item)
        end
      end
      if opt[:output] == 'json'
        Doing.logger.debug('JSON Export:', "#{items_out.count} items output to JSON")
        JSON.pretty_generate({
          'section' => variables[:page_title],
          'items' => items_out,
          'timers' => wwid.tag_times(format: :json, sort_by_name: opt[:sort_tags], sort_order: opt[:tag_order])
        })
      elsif opt[:output] == 'timeline'
        template = <<~EOTEMPLATE
                    <!doctype html>
                    <html>
                    <head>
                      <link href="https://unpkg.com/vis-timeline@7.4.9/dist/vis-timeline-graph2d.min.css" rel="stylesheet" type="text/css" />
                      <script src="https://unpkg.com/vis-timeline@7.4.9/dist/vis-timeline-graph2d.min.js"></script>
                    </head>
                    <body>
                      <div id="mytimeline"></div>
          #{'          '}
                      <script type="text/javascript">
                        // DOM element where the Timeline will be attached
                        var container = document.getElementById('mytimeline');
          #{'          '}
                        // Create a DataSet with data (enables two way data binding)
                        var data = new vis.DataSet(#{items_out.to_json});
          #{'          '}
                        // Configuration for the Timeline
                        var options = {
                          width: '100%',
                          height: '800px',
                          margin: {
                            item: 20
                          },
                          stack: true,
                          min: '#{min}',
                          max: '#{max}'
                        };
          #{'          '}
                        // Create a Timeline
                        var timeline = new vis.Timeline(container, data, options);
                      </script>
                    </body>
                    </html>
        EOTEMPLATE
        Doing.logger.debug('Timeline Export:', "#{items_out.count} items output to Timeline")
        template
      end
    end

    Doing::Plugins.register 'json', :export, self
    Doing::Plugins.register 'timeline', :export, self
  end
end

