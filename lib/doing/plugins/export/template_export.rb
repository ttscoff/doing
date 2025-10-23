# frozen_string_literal: true

# title: Template Export
# description: Default export option using configured template placeholders
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  # Template Export
  class TemplateExport
    include Doing::Color
    include Doing::Util

    def self.settings
      {
        trigger: 'template'
      }
    end

    def self.render(wwid, items, variables: {})
      Doing.logger.measure(:template_render) do
        return if items.nil?

        opt = variables[:options]

        out = ''
        items.each do |item|
          if opt[:highlight] && item.title =~ /@#{Doing.setting('marker_tag')}\b/i
            flag = Doing::Color.send(Doing.setting('marker_color'))
            reset = Doing::Color.reset + Doing::Color.default
          else
            flag = ''
            reset = ''
          end

          placeholders = {}

          if !item.note.empty? && Doing.setting('include_notes')
            note = item.note.map(&:strip).delete_if(&:empty?)
            note.map! { |line| "#{line.sub(/^\t*/, '')}  " }

            if opt[:wrap_width]&.positive?
              width = opt[:wrap_width]
              note.map! do |line|
                line.simple_wrap(width)
                # line.chomp.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
              end
              note.delete_if(&:empty?)
            end
          else
            note = []
          end

          placeholders['id'] = item.id

          placeholders['tags'] = item.tags

          placeholders['date'] = item.date.strftime(opt[:format])

          interval = wwid.get_interval(item, record: true, formatted: false) if opt[:times]
          if interval
            interval = case opt[:interval_format].to_sym
                       when :human
                         interval.time_string(format: :hm)
                       when :text
                         interval.time_string(format: :clock)
                       else
                         interval.time_string(format: opt[:interval_format].to_sym)
                       end
          end

          interval ||= ''
          placeholders['interval'] = interval

          duration = item.duration if opt[:duration]
          if duration
            duration = case opt[:interval_format].to_sym
                       when :human
                         duration.time_string(format: :hm)
                       when :text
                         duration.time_string(format: :clock)
                       else
                         duration.time_string(format: opt[:interval_format].to_sym)
                       end
          end
          duration ||= ''
          placeholders['duration'] = duration

          placeholders['shortdate'] = format('%13s', item.date.relative_date)
          placeholders['section'] = item.section || ''
          placeholders['title'] = item.title
          placeholders['note'] = note
          placeholders['idnote'] = note.empty? ? '' : "\n#{note.map { |l| "\t\t#{l.strip}  " }.join("\n")}"
          placeholders['odnote'] = note.empty? ? '' : "\n#{note.map { |l| "#{l.strip}  " }.join("\n")}"

          chompnote = []
          unless note.empty?
            chompnote = note.map do |l|
              l.gsub(/\n+/, ' ').gsub(/(^\s*|\s*$)/, '').gsub(/\s+/, ' ')
            end
          end
          placeholders['chompnote'] = chompnote.join(' ')

          template = opt[:template].dup
          note_rx = /(?i-m)(?x:^([\s\S]*?)
                      (%(?:[io]d|(?:\^[\s\S])?
                      (?:(?:[ _t]|[^a-z0-9])?\d+)?
                      (?:[\s\S][ _t]?)?)?note)
                      ([\s\S]*?)$)/
          template.sub!(note_rx, '\1\3\2')
          output = Doing::TemplateString.new(template,
                                             color: flag,
                                             placeholders: placeholders,
                                             reset: reset,
                                             tags_color: opt[:tags_color],
                                             wrap_width: opt[:wrap_width],
                                             disable_color: opt[:disable_color]).colored

          output.gsub!(/(?<!\\)%(\S)?hr(_under)?/) do
            o = ''
            TTY::Screen.columns.to_i.times do
              char = Regexp.last_match(2).nil? ? '-' : '_'
              char = Regexp.last_match(1).nil? ? char : Regexp.last_match(1)
              o += char
            end
            o
          end
          output.gsub!(/(?<!\\)%n/, "\n")
          output.gsub!(/(?<!\\)%t/, "\t")

          output.gsub!(/\\%/, '%')

          if opt[:output] =~ /^temp/ && opt[:search] && !opt[:not] && opt[:hilite]
            output.highlight_search!(opt[:search])
          end

          out += "#{output}\n"
        end

        # Doing.logger.debug('Template Export:', "#{items.count} items output to template #{opt[:output]}")
        if opt[:totals]
          out += wwid.tag_times(format: Doing.setting('timer_format').to_sym,
                                sort_by: opt[:sort_tags],
                                sort_order: opt[:tag_order])
        end
        out
      end
    end

    Doing::Plugins.register 'template', :export, self
  end
end
