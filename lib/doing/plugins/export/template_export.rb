# frozen_string_literal: true

# title: Template Export
# description: Default export option using configured template placeholders
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class TemplateExport
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
          flag = wwid.colors[wwid.config['marker_color']]
          reset = wwid.colors['default']
        else
          flag = ''
          reset = ''
        end

        if (!item.note.empty?) && wwid.config[:include_notes]
          note = item.note.map(&:strip).delete_if(&:empty?)
          note.map! { |line| "#{line.sub(/^\t*/, '')}  " }

          if opt[:wrap_width]&.positive?
            width = opt[:wrap_width]
            note.map! { |line| line.chomp.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n") }
            note = note.join("\n").split(/\n/).delete_if(&:empty?)
          end
        else
          note = []
        end
        output = opt[:template].dup

        output.gsub!(/%[a-z]+/) do |m|
          if wwid.colors.key?(m.sub(/^%/, ''))
            wwid.colors[m.sub(/^%/, '')]
          else
            m
          end
        end

        output.sub!(/%(\d+)?date/) do
          pad = Regexp.last_match(1).to_i
          format("%#{pad}s", item.date.strftime(opt[:format]))
        end

        interval = wwid.get_interval(item, record: true) if opt[:times]
        interval ||= ''
        output.sub!(/%interval/, interval)

        output.sub!(/%(\d+)?shortdate/) do
          pad = Regexp.last_match(1) || 13
          format("%#{pad}s", item.date.relative_date)
        end

        output.sub!(/%section/, item.section) if item.section

        title_offset = output.uncolor.match(/%(-?\d+)?([ _t]\d+)?title/).begin(0)
        output.sub!(/%(-?\d+)?(([ _t])(\d+))?title(.*?)$/) do
          m = Regexp.last_match
          pad = m[1].to_i
          indent = ''
          if m[2]
            char = m[3] =~ /t/ ? "\t" : " "
            indent = char * m[4].to_i
          end
          after = m[5]
          if opt[:wrap_width]&.positive? || pad.positive?
            width = pad.positive? ? pad : opt[:wrap_width]
            item.title.wrap(width, pad: pad, indent: indent, offset: title_offset, prefix: flag, after: after, reset: reset)
            # flag + item.title.gsub(/(.{#{opt[:wrap_width]}})(?=\s+|\Z)/, "\\1\n ").sub(/\s*$/, '') + reset
          else
            format("%s%#{pad}s%s%s", flag, item.title.sub(/\s*$/, ''), reset, after)
          end
        end

        # output.sub!(/(?i-m)^([\s\S]*?)(%(?:[io]d|(?:\^[\s\S])?(?:(?:[ _t]|[^a-z0-9])?\d+)?(?:[\s\S][ _t]?)?)?note)([\s\S]*?)$/, '\1\3\2')
        if opt[:tags_color]
          escapes = output.scan(/(\e\[[\d;]+m)[^\e]+@/)
          last_color = if !escapes.empty?
                         escapes[-1][0]
                       else
                         wwid.colors['default']
                       end
          output.gsub!(/(\s|m)(@[^ (]+)/, "\\1#{wwid.colors[opt[:tags_color]]}\\2#{last_color}")
        end

        if note.empty?
          output.gsub!(/%([io]d|(\^.)?(([ _t]|[^a-z0-9])?\d+)?(.[ _t]?)?)?note/, '')
        else
          output.sub!(/%note/, "\n#{note.map { |l| "\t#{l.strip}  " }.join("\n")}")
          output.sub!(/%idnote/, "\n#{note.map { |l| "\t\t#{l.strip}  " }.join("\n")}")
          output.sub!(/%odnote/, "\n#{note.map { |l| "#{l.strip}  " }.join("\n")}")
          output.sub!(/(?mi)%(?:\^(?<mchar>.))?(?:(?<ichar>[ _t]|[^a-z0-9])?(?<icount>\d+))?(?<prefix>.[ _t]?)?note/) do
            m = Regexp.last_match
            mark = m['mchar'] || ''
            indent = if m['ichar']
                       char = m['ichar'] =~ /t/ ? "\t" : ' '
                       char * m['icount'].to_i
                     else
                       ''
                     end
            prefix = m['prefix'] || ''
            "\n#{note.map { |l| "#{mark}#{indent}#{prefix}#{l.strip}  " }.join("\n")}"
          end
          output.sub!(/%chompnote/) do |_m|
            chomp_note = note.map do |l|
              l.gsub(/\n+/, ' ').gsub(/(^\s*|\s*$)/, '').gsub(/\s+/, ' ')
            end
            chomp_note.join(' ')
          end
        end

        output.gsub!(/%hr(_under)?/) do |_m|
          o = ''
          `tput cols`.to_i.times do
            o += Regexp.last_match(1).nil? ? '-' : '_'
          end
          o
        end
        output.gsub!(/%n/, "\n")
        output.gsub!(/%t/, "\t")

        out += "#{output}\n"
      end
      out += wwid.tag_times(format: :text, sort_by_name: opt[:sort_tags], sort_order: opt[:tag_order]) if opt[:totals]
      out
    end

    Doing::Plugins.register ['template', 'doing'], :export, self
  end
end
