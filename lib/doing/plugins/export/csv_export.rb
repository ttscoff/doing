# frozen_string_literal: true

# title: CSV Export
# description: Export CSV formatted data with header row
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  ##
  ## CSV Export
  ##
  class CSVExport
    include Doing::Util

    def self.settings
      {
        trigger: 'csv'
      }
    end

    def self.render(wwid, items, variables: {})
      return if items.nil?

      opt = variables[:options]

      output = [CSV.generate_line(%w[start end title note timer section])]
      items.each do |i|
        note = format_note(i.note)
        end_date = i.end_date
        interval = end_date && opt[:times] ? wwid.get_interval(i, formatted: false) : 0
        output.push(CSV.generate_line([i.date, end_date, i.title, note, interval, i.section]))
      end
      Doing.logger.debug('CSV Export:', "#{items.count} items output to CSV")
      output.join('')
    end

    def self.format_note(note)
      out = ''
      if note
        arr = note.map(&:strip).delete_if { |e| e =~ /^\s*$/ }
        out = arr.join("\n") unless arr.empty?
      end

      out
    end

    Doing::Plugins.register 'csv', :export, self
  end
end
