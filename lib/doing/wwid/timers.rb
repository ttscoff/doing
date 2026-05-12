# frozen_string_literal: true

module Doing
  class WWID
    ##
    ## Get total elapsed time for all tags in
    ##             selection
    ##
    ## @param      format        [String] return format (html,
    ##                           json, or text)
    ## @param      sort_by       [Symbol] Sort by :name or :time
    ## @param      sort_order    [Symbol] The sort order (:asc or :desc)
    ##
    def tag_times(format: :text, sort_by: :time, sort_order: :asc, by: nil, totals_format: nil, items: nil)
      groupings = normalize_totals_groupings(by)
      totals = collect_totals(groupings)
      return '' if totals.empty?
      totals_format = normalize_totals_format(totals_format)

      timers_snapshot = totals[:tags] || {}

      budgets = Doing.setting('budgets') || {}
      budgets = budgets.transform_keys { |k| k.to_s.downcase }
      remaining_map = {}
      budgets_total = 0

      budget_fmt = lambda do |secs|
        secs = secs.to_i
        return '0h' if secs <= 0

        minutes = (secs / 60).to_i
        hours = (minutes / 60).to_i
        mins = (minutes % 60).to_i
        return format('%dh', hours) if mins.zero?
        return format('%dm', mins) if hours.zero?

        format('%dh%dm', hours, mins)
      end

      budgets.each do |tag, budget_secs|
        used = timers_snapshot[tag].to_i
        remaining = budget_secs.to_i - used
        remaining = 0 if remaining.negative?
        remaining_map[tag] = remaining
        budgets_total += remaining
      end

      outputs = groupings.map do |group|
        timer_data = totals[group]
        next nil unless timer_data

        render_totals_group(
          format: format,
          group: group,
          timer_data: timer_data,
          sort_by: sort_by,
          sort_order: sort_order,
          totals_format: totals_format,
          items: items,
          remaining_map: remaining_map,
          budgets: budgets,
          budgets_total: budgets_total,
          budget_fmt: budget_fmt
        )
      end.compact

      return '' if outputs.empty?
      return outputs.first if format == :json && outputs.length == 1

      format == :json ? outputs.to_h : outputs.join(format == :human ? "\n" : '')
    end

    ##
    ## Gets the interval between entry's start
    ##             date and @done date
    ##
    ## @param      item       [Item] The entry
    ## @param      formatted  [Boolean] Return human readable
    ##                        time (default seconds)
    ## @param      record     [Boolean] Add the interval to the
    ##                        total for each tag
    ##
    ## @return     Interval in seconds, or [d, h, m] array if
    ##             formatted is true. False if no end date or
    ##             interval is 0
    ##
    def get_interval(item, formatted: true, record: true)
      if item.interval
        seconds = item.interval
        record_tag_times(item, seconds) if record
        return seconds.positive? ? seconds : false unless formatted

        return seconds.positive? ? seconds.time_string(format: :clock) : false
      end

      false
    end

    private

    ##
    ## Record times for item tags
    ##
    ## @param      item  [Item] The item to record
    ##
    def record_tag_times(item, seconds)
      item_hash = "#{item.date.strftime('%s')}#{item.title}#{item.section}"
      return if @recorded_items.include?(item_hash)

      @section_timers ||= {}
      section = item.section.to_s.strip
      section = 'Unknown' if section.empty?
      @section_timers['All'] = @section_timers.fetch('All', 0) + seconds
      @section_timers[section] = @section_timers.fetch(section, 0) + seconds

      item.title.scan(/(?mi)@(\S+?)(\(.*\))?(?=\s|$)/).each do |m|
        k = m[0] == 'done' ? 'All' : m[0].downcase
        if @timers.key?(k)
          @timers[k] += seconds
        else
          @timers[k] = seconds
        end
        @recorded_items.push(item_hash)
      end
    end

    def normalize_totals_groupings(by)
      return [:tags] if by.nil? || (by.respond_to?(:empty?) && by.empty?)

      Array(by).map { |v| v.normalize_totals_by(:tags) }.uniq
    end

    def collect_totals(groupings)
      totals = {}
      totals[:tags] = @timers.dup if groupings.include?(:tags) && @timers.good?
      totals[:section] = (@section_timers || {}).dup if groupings.include?(:section) && @section_timers.good?
      totals
    end

    def sort_totals_data(data, sort_by:, sort_order:)
      sorted = if sort_by.normalize_tag_sort == :name
                 data.sort_by { |k, _v| k }
               else
                 data.sort_by { |_k, v| v }
               end
      sorted.reverse! if sort_order.normalize_order == :asc
      sorted
    end

    def render_totals_group(format:, group:, timer_data:, sort_by:, sort_order:, totals_format:, items:, remaining_map:, budgets:, budgets_total:, budget_fmt:)
      timer_data = timer_data.dup
      timer_data.delete('meanwhile')

      max = timer_data.keys.sort_by(&:length).reverse[0].length + 1
      total = timer_data.delete('All').to_i
      group_data = timer_data.delete_if { |_k, v| v.zero? }
      sorted_data = sort_totals_data(group_data, sort_by: sort_by, sort_order: sort_order)

      title = group == :section ? 'Section Totals' : 'Tag Totals'
      label = group == :section ? 'section' : 'tag'
      line_format = totals_format == :averages ? :hmclock : totals_format

      case format
      when :html
        output = <<EOHEAD
          <table>
          <caption id="#{group}totals">#{title}</caption>
          <colgroup>
          <col style="text-align:left;"/>
          <col style="text-align:left;"/>
          </colgroup>
          <thead>
          <tr>
            <th style="text-align:left;">project</th>
            <th style="text-align:left;">time</th>
          </tr>
          </thead>
          <tbody>
EOHEAD
        sorted_data.reverse.each do |k, v|
          next unless v.positive?

          budget_str = ''
          if group == :tags && remaining_map.key?(k) && remaining_map[k].positive?
            budget_str = " (budget left #{budget_fmt.call(remaining_map[k])})"
          end
          output += "<tr><td style='text-align:left;'>#{k}</td><td style='text-align:left;'>#{v.time_string(format: line_format)}#{budget_str}</td></tr>\n"
        end
        output += <<EOTAIL
        <tr>
          <td style="text-align:left;" colspan="2"></td>
        </tr>
        </tbody>
        <tfoot>
        <tr>
          <td style="text-align:left;"><strong>Total</strong></td>
          <td style="text-align:left;">#{total.time_string(format: line_format)}#{group == :tags && budgets_total.positive? ? " (total budgets left #{budget_fmt.call(budgets_total)})" : ''}</td>
        </tr>
        </tfoot>
        </table>
EOTAIL
        output
      when :markdown
        pad = sorted_data.map { |k, _| k }.group_by(&:size).max.last[0].length
        pad = 7 if pad < 7
        output = <<~EOHEADER
          | #{' ' * (pad - 7)}project | time     |
          | #{'-' * (pad - 1)}: | :------- |
        EOHEADER
        sorted_data.reverse.each do |k, v|
          next unless v.positive?

          budget_str = ''
          if group == :tags && remaining_map.key?(k) && remaining_map[k].positive?
            budget_str = " (budget left #{budget_fmt.call(remaining_map[k])})"
          end
          output += "| #{' ' * (pad - k.length)}#{k} | #{v.time_string(format: line_format)}#{budget_str} |\n"
        end
        output + "[#{title}]"
      when :json
        output = []
        sorted_data.reverse.each do |k, v|
          row = {
            label => k,
            'seconds' => v,
            'formatted' => v.time_string(format: line_format)
          }
          if group == :tags
            row['budget'] = budgets[k]
            row['remaining'] = remaining_map[k]
            row['remaining_formatted'] = (remaining_map[k] && remaining_map[k].positive? ? budget_fmt.call(remaining_map[k]) : nil)
          end
          output << row
        end
        [group, output]
      when :human
        output = []
        sorted_data.reverse.each do |k, v|
          spacer = ''
          (max - k.length).times do
            spacer += ' '
          end
          line = "┃ #{spacer}#{k}:#{v.time_string(format: :hm)}"
          if group == :tags && remaining_map.key?(k) && remaining_map[k].positive?
            line += " (budget left #{budget_fmt.call(remaining_map[k])})"
          end
          line += ' ┃'
          output.push(line)
        end

        total_content = "┃ #{' ' * (max - 6)}total: #{total.time_string(format: :hm)}"
        total_content += " (total budgets left #{budget_fmt.call(budgets_total)})" if group == :tags && budgets_total.positive?
        total_content += ' ┃'
        max_line_len = (output + [total_content]).map(&:length).max

        pad_line = lambda do |line|
          pad = max_line_len - line.length
          pad.positive? ? "#{line[0..-3]} #{' ' * pad}┃" : line
        end
        output = output.map { |l| pad_line.call(l) }

        header = "┏━━ #{title} "
        # Keep top border width aligned with body/footer width.
        [(max_line_len - title.length - 6), 0].max.times { header += '━' }
        header += '┓'
        footer = '┗'
        [(max_line_len - 2), 0].max.times { footer += '━' }
        footer += '┛'
        divider = '┣'
        [(max_line_len - 2), 0].max.times { divider += '━' }
        divider += '┫'
        output = output.empty? ? '' : "\n#{header}\n#{output.join("\n")}"
        output += "\n#{divider}"
        spacer = ''
        (max - 6).times do
          spacer += ' '
        end
        total_time = total.time_string(format: :hm)
        total_line = "┃ #{spacer}total: "
        total_line += total_time
        total_line += " (total budgets left #{budget_fmt.call(budgets_total)})" if group == :tags && budgets_total.positive?
        total_line += ' ┃'
        total_line = pad_line.call(total_line)
        output += "\n#{total_line}"
        output += "\n#{footer}"
        output
      else
        output = []
        sorted_data.reverse.each do |k, v|
          spacer = ''
          (max - k.length).times do
            spacer += ' '
          end
          line = "#{k}:#{spacer}#{v.time_string(format: line_format)}"
          if group == :tags && remaining_map.key?(k) && remaining_map[k].positive?
            line += " (budget left #{budget_fmt.call(remaining_map[k])})"
          end
          output.push(line)
        end

        output = output.empty? ? '' : "\n--- #{title} ---\n#{output.join("\n")}"
        output += "\n\nTotal tracked: #{total.time_string(format: line_format)}"
        output += totals_average_suffix(total, items) if totals_format == :averages
        output += " (total budgets left #{budget_fmt.call(budgets_total)})" if group == :tags && budgets_total.positive?
        output += "\n"
        output
      end
    end

    def normalize_totals_format(value)
      format = (value || Doing.setting('totals_format') || 'clock').to_s.downcase
      format = 'clock' if format.empty?
      return :averages if format == 'averages'

      format.to_sym
    end

    def totals_average_suffix(total_seconds, items)
      return '' unless items.respond_to?(:empty?) && !items.empty?

      total_hours = total_seconds.to_f / 3600
      total_hours_floor = total_hours.floor
      total_minutes = ((total_hours - total_hours_floor) * 60).round
      if total_minutes == 60
        total_hours_floor += 1
        total_minutes = 0
      end

      dates = items.map { |item| item.date.to_date }.compact
      return '' if dates.empty?

      start_date = dates.min
      end_date = dates.max
      time_span_in_days = [(end_date - start_date).to_i + 1, 1].max
      avg_hours_per_day = total_hours / time_span_in_days

      format(' (%<hours>dh %<minutes>d min, %<avg>.2fh/day)',
             hours: total_hours_floor,
             minutes: total_minutes,
             avg: avg_hours_per_day)
    end
  end
end
