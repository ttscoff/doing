# frozen_string_literal: true

# title: By Day Export
# description: Export a table of items grouped by day with daily totals
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class ByDayExport
    def self.settings
      {
        trigger: 'byday',
        config: {
          'item_width' => 60
        }
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
      width = wwid.config['plugins']['byday']['item_width'].to_i || 60
      divider = "{wd}+{xk}#{'-' *10}{wd}+{xk}#{'-' * width}{wd}+{xk}#{'-' * 8}{wd}+{x}"
      out = []
      out << divider
      out << "{wd}|{xm}date      {wd}|{xbw}item#{' ' * (width - 4)}{wd}|{xy}duration{wd}|{x}"
      out << divider
      days.each do |day, day_items|
        first = day_items.slice!(0, 1)[0]
        interval = wwid.get_interval(first, formatted: true) || '00:00:00'
        out << "{wd}|{xm}#{day}{wd}|{xbw}#{first.title.tag('done', remove: true).trunc(width - 2).ljust(width)}{wd}|{xy}#{interval}{wd}|{x}"
        day_items.each do |item|
          interval = wwid.get_interval(item, formatted: true) || '00:00:00'
          out << "{wd}|          |{xbw}#{item.title.tag('done', remove: true).trunc(width - 2).ljust(width)}{wd}|{xy}#{interval}{wd}|{x}"
        end
        day_total = "Total: #{totals[day].time_string(format: :clock)}"
        out << divider
        out << "{wd}|{xg}#{day_total.rjust(width + 20)}{wd}|{x}"
        out << divider
      end
      all_total = "Grand Total: #{total.time_string(format: :clock)}"
      out << divider
      out << "{wd}|{xrb}#{all_total.rjust(width + 20)}{wd}|{x}"
      out << divider
      Doing::Pager.page Doing::Color.template(out.join("\n"))
    end

    Doing::Plugins.register 'byday', :export, self
  end
end
