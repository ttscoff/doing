# frozen_string_literal: true

# title: Template Export
# description: Default export option using configured template placeholders
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class TemplateExport
    include Doing::Color
    include Doing::Util

    def self.settings
      {
        trigger: 'template|doing'
      }
    end

    def self.render(wwid, items, variables: {})
      return if items.nil?

      opt = variables[:options]

      out = ''
      items.each do |item|
        if opt[:highlight] && item.title =~ /@#{wwid.config['marker_tag']}\b/i
          flag = Doing::Color.send(wwid.config['marker_color'])
          reset = Doing::Color.reset + Doing::Color.default
        else
          flag = ''
          reset = ''
        end

        placeholders = {}

        if (!item.note.empty?) && wwid.config['include_notes']
          note = item.note.map(&:strip).delete_if(&:empty?)
          note.map! { |line| "#{line.sub(/^\t*/, '')}  " }

          if opt[:wrap_width]&.positive?
            width = opt[:wrap_width]
            note.map! do |line|
              line.simple_wrap(width)
              # line.chomp.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
            end
            note = note.delete_if(&:empty?)
          end
        else
          note = []
        end

        # output.sub!(/%(\d+)?date/) do
        #   pad = Regexp.last_match(1).to_i
        #   format("%#{pad}s", item.date.strftime(opt[:format]))
        # end
        placeholders['date'] = item.date.strftime(opt[:format])

        interval = wwid.get_interval(item, record: true, formatted: false) if opt[:times]
        if interval
          case opt[:interval_format].to_sym
          when :human
            interval = interval.time_string(format: :hm)
          else
            interval = interval.time_string(format: :clock)
          end
        end

        interval ||= ''
        # output.sub!(/%interval/, interval)
        placeholders['interval'] = interval

        duration = item.duration if opt[:duration]
        if duration
          case opt[:interval_format].to_sym
          when :human
            duration = duration.time_string(format: :hm)
          else
            duration = duration.time_string(format: :clock)
          end
        end
        duration ||= ''
        # output.sub!(/%duration/, duration)
        placeholders['duration'] = duration

        # output.sub!(/%(\d+)?shortdate/) do
        #   pad = Regexp.last_match(1) || 13
        #   format("%#{pad}s", item.date.relative_date)
        # end
        placeholders['shortdate'] = format("%13s", item.date.relative_date)
        # output.sub!(/%section/, item.section) if item.section
        placeholders['section'] = item.section || ''
        placeholders['title'] = item.title

        # title_rx = /(?mi)%(?<width>-?\d+)?(?:(?<ichar>[ _t])(?<icount>\d+))?(?<prefix>.[ _t]?)?title(?<after>.*?)$/
        # title_color = Doing::Color.reset + output.match(/(?mi)^(.*?)(%.*?title)/)[1].last_color

        # title_offset = Doing::Color.uncolor(output).match(title_rx).begin(0)

        # output.sub!(title_rx) do
        #   m = Regexp.last_match

        #   after = m['after']
        #   pad = m['width'].to_i
        #   indent = ''
        #   if m['ichar']
        #     char = m['ichar'] =~ /t/ ? "\t" : ' '
        #     indent = char * m['icount'].to_i
        #   end
        #   prefix = m['prefix']
        #   if opt[:wrap_width]&.positive? || pad.positive?
        #     width = pad.positive? ? pad : opt[:wrap_width]
        #     item.title.wrap(width, pad: pad, indent: indent, offset: title_offset, prefix: prefix, color: title_color, after: after, reset: reset)
        #     # flag + item.title.gsub(/(.{#{opt[:wrap_width]}})(?=\s+|\Z)/, "\\1\n ").sub(/\s*$/, '') + reset
        #   else
        #     format("%s%#{pad}s%s", prefix, item.title.sub(/\s*$/, ''), after)
        #   end
        # end



        placeholders['note'] = note
        placeholders['idnote'] = note.empty? ? '' : "\n#{note.map { |l| "\t\t#{l.strip}  " }.join("\n")}"
        placeholders['odnote'] = note.empty? ? '' : "\n#{note.map { |l| "#{l.strip}  " }.join("\n")}"
        placeholders['chompnote'] = note.empty? ? '' : note.map { |l| l.gsub(/\n+/, ' ').gsub(/(^\s*|\s*$)/, '').gsub(/\s+/, ' ') }.join(' ')

        # if note.empty?
        #   output.gsub!(/%(chomp|[io]d|(\^.)?(([ _t]|[^a-z0-9])?\d+)?(.[ _t]?)?)?note/, '')
        # else
        #   output.sub!(/%note/, "\n#{note.map { |l| "\t#{l.strip}  " }.join("\n")}")
        #   output.sub!(/%idnote/, "\n#{note.map { |l| "\t\t#{l.strip}  " }.join("\n")}")
        #   output.sub!(/%odnote/, "\n#{note.map { |l| "#{l.strip}  " }.join("\n")}")
        #   output.sub!(/(?mi)%(?:\^(?<mchar>.))?(?:(?<ichar>[ _t]|[^a-z0-9])?(?<icount>\d+))?(?<prefix>.[ _t]?)?note/) do
        #     m = Regexp.last_match
        #     mark = m['mchar'] || ''
        #     indent = if m['ichar']
        #                char = m['ichar'] =~ /t/ ? "\t" : ' '
        #                char * m['icount'].to_i
        #              else
        #                ''
        #              end
        #     prefix = m['prefix'] || ''
        #     "\n#{note.map { |l| "#{mark}#{indent}#{prefix}#{l.strip}  " }.join("\n")}"
        #   end

        #   output.sub!(/%chompnote/) do
        #     note.map { |l| l.gsub(/\n+/, ' ').gsub(/(^\s*|\s*$)/, '').gsub(/\s+/, ' ') }.join(' ')
        #   end
        # end

        template = opt[:template].dup
        template.sub!(/(?i-m)^([\s\S]*?)(%(?:[io]d|(?:\^[\s\S])?(?:(?:[ _t]|[^a-z0-9])?\d+)?(?:[\s\S][ _t]?)?)?note)([\s\S]*?)$/, '\1\3\2')
        output = Doing::TemplateString.new(template, placeholders: placeholders, wrap_width: opt[:wrap_width], color: flag, tags_color: opt[:tags_color], reset: reset).colored

        output.gsub!(/(?<!\\)%hr(_under)?/) do
          o = ''
          `tput cols`.to_i.times do
            o += Regexp.last_match(1).nil? ? '-' : '_'
          end
          o
        end
        output.gsub!(/(?<!\\)%n/, "\n")
        output.gsub!(/(?<!\\)%t/, "\t")

        output.gsub!(/\\%/, '%')

        out += "#{output}\n"
      end

      # Doing.logger.debug('Template Export:', "#{items.count} items output to template #{opt[:template]}")
      out += wwid.tag_times(format: wwid.config['timer_format'].to_sym, sort_by_name: opt[:sort_tags], sort_order: opt[:tag_order]) if opt[:totals]
      out
    end

    Doing::Plugins.register ['template', 'doing'], :export, self
  end
end
