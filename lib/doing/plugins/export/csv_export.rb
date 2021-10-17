module Doing
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

      output = [CSV.generate_line(%w[date title note timer section])]
      items.each do |i|
        note = ''
        if i['note']
          arr = i['note'].map { |line| line.strip }.delete_if { |e| e =~ /^\s*$/ }
          note = arr.join("\n") unless arr.nil?
        end
        interval = wwid.get_interval(i, formatted: false) if i['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
        interval ||= 0
        output.push(CSV.generate_line([i['date'], i['title'], note, interval, i['section']]))
      end
      output.join('')
    end

    Doing::Plugins.register 'csv', :export, self
  end
end
