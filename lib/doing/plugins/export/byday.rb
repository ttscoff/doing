# frozen_string_literal: true

# title: Doing File Export
# description: Export Doing format data
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class ByDayExport
    def self.settings
      {
        trigger: 'byday'
      }
    end

    def self.render(wwid, items, variables: {})
      return if items.nil?

      days = {}

      items.each do |item|
        date = item.date.strftime('%Y-%m-%d')
        days[date] ||= []
        days[date].push(item)
      end

      totals = {}
      total = 0

      days.each do |day, day_items|
        day_items.each do |item|
          totals[day] ||= 0
          duration = item.interval || 0
          totals[day] += duration
          total += duration
        end
      end

      divider = "+----------+------------------------------------------------------------------------------------------------+--------+"
      out = []
      out << divider
      days.each do |day, day_items|
        first = day_items.slice!(0, 1)[0]
        interval = wwid.get_interval(first, formatted: true) || '00:00:00'
        out << "|#{day}|#{first.title.trunc(94).ljust(96)}|#{interval}|"
        day_items.each do |item|
          interval = wwid.get_interval(item, formatted: true) || '00:00:00'
          out << "|          |#{item.title.trunc(94).ljust(96)}|#{interval}|"
        end
        day_total = "Total: #{totals[day].time_string(format: :clock)}"
        out << divider
        out << "|#{day_total.rjust(116)}|"
        out << divider
      end
      all_total = "Grand Total: #{total.time_string(format: :clock)}"
      out << divider
      out << "|#{all_total.rjust(116)}|"
      out << divider
      Doing::Pager.page out.join("\n")
    end

    Doing::Plugins.register 'byday', :export, self
  end
end
