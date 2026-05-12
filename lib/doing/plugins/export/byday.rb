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
      tag_totals = Hash.new(0)

      days.each do |day, day_items|
        day_items.each do |item|
          totals[day] ||= 0
          duration = item.interval || 0
          totals[day] += duration
          total += duration

          item.title.scan(/(?mi)@(\S+?)(\(.*\))?(?=\s|$)/).each do |m|
            tag = m[0].downcase
            next if tag == 'done'

            tag_totals[tag] += duration
          end
        end
      end

      budgets = Doing.setting('budgets') || {}
      budgets = budgets.transform_keys { |k| k.to_s.downcase }
      budgets_total = 0

      budget_fmt = lambda do |secs|
        secs = secs.to_i
        return '0h' if secs <= 0

        minutes = (secs / 60).to_i
        hours = (minutes / 60).to_i
        mins = (minutes % 60).to_i
        return format('%<h>dh', h: hours) if mins.zero?
        return format('%<m>dm', m: mins) if hours.zero?

        format('%<h>dh%<m>dm', h: hours, m: mins)
      end

      budgets.each do |tag, budget_secs|
        used = tag_totals[tag].to_i
        remaining = budget_secs.to_i - used
        remaining = 0 if remaining.negative?
        budgets_total += remaining
      end

      width = wwid.config['plugins']['byday']['item_width'].to_i || 60
      divider = "{wd}+{xk}#{'-' * 10}{wd}+{xk}#{'-' * width}{wd}+{xk}#{'-' * 8}{wd}+{x}"
      out = []
      out << divider
      out << "{wd}|{xm}date      {wd}|{xbw}item#{' ' * (width - 4)}{wd}|{xy}duration{wd}|{x}"
      out << divider
      days.each do |day, day_items|
        first = day_items.slice!(0, 1)[0]
        interval = wwid.get_interval(first, formatted: true) || '00:00:00'
        title = first.title.tag('done', remove: true).trunc(width - 2).ljust(width)
        out << "{wd}|{xm}#{day}{wd}|{xbw}#{title}{wd}|{xy}#{interval}{wd}|{x}"
        day_items.each do |item|
          interval = wwid.get_interval(item, formatted: true) || '00:00:00'
          title = item.title.tag('done', remove: true).trunc(width - 2).ljust(width)
          out << "{wd}|          |{xbw}#{title}{wd}|{xy}#{interval}{wd}|{x}"
        end
        day_total = "Total: #{totals[day].time_string(format: :clock)}"
        if budgets_total.positive?
          day_total += " (total budgets left #{budget_fmt.call(budgets_total)})"
        end
        out << divider
        out << "{wd}|{xg}#{day_total.rjust(width + 20)}{wd}|{x}"
        out << divider
      end
      all_total = "Grand Total: #{total.time_string(format: :clock)}"
      if budgets_total.positive?
        all_total += " (total budgets left #{budget_fmt.call(budgets_total)})"
      end
      out << "{wd}|{xrb}#{all_total.rjust(width + 20)}{wd}|{x}"
      out << divider
      Doing::Color.template(out.join("\n"))
    end

    Doing::Plugins.register 'byday', :export, self
  end
end
