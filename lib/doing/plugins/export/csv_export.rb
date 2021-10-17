$wwid.register_plugin({
  name: 'csv',
  type: :export,
  class: 'CSVExport',
  trigger: 'csv'
})

class CSVExport
  include Util

  def render(items, variables: {})
    return if items.nil?

    opt = variables[:options]

    output = [CSV.generate_line(%w[date title note timer section])]
    items.each do |i|
      note = ''
      if i['note']
        arr = i['note'].map { |line| line.strip }.delete_if { |e| e =~ /^\s*$/ }
        note = arr.join("\n") unless arr.nil?
      end
      interval = get_interval(i, formatted: false) if i['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
      interval ||= 0
      output.push(CSV.generate_line([i['date'], i['title'], note, interval, i['section']]))
    end
    output.join('')
  end
end
