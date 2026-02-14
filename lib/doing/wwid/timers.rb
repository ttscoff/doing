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
    def tag_times(format: :text, sort_by: :time, sort_order: :asc)
      return '' if @timers.empty?

      @timers.delete('meanwhile')

      timers_snapshot = @timers.dup

      budgets = Doing.setting('budgets', {}) || {}
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

      max = @timers.keys.sort_by(&:length).reverse[0].length + 1

      total = @timers.delete('All')

      tags_data = @timers.delete_if { |_k, v| v.zero? }
      sorted_tags_data = if sort_by.normalize_tag_sort == :name
                           tags_data.sort_by { |k, _v| k }
                         else
                           tags_data.sort_by { |_k, v| v }
                         end

      sorted_tags_data.reverse! if sort_order.normalize_order == :asc
      case format
      when :html

        output = <<EOHEAD
          <table>
          <caption id="tagtotals">Tag Totals</caption>
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
        sorted_tags_data.reverse.each do |k, v|
          next unless v.positive?

          budget_str = ''
          if remaining_map.key?(k) && remaining_map[k].positive?
            budget_str = " (budget left #{budget_fmt.call(remaining_map[k])})"
          end
          output += "<tr><td style='text-align:left;'>#{k}</td><td style='text-align:left;'>#{v.time_string(format: :clock)}#{budget_str}</td></tr>\n"
        end
        tail = <<EOTAIL
        <tr>
          <td style="text-align:left;" colspan="2"></td>
        </tr>
        </tbody>
        <tfoot>
        <tr>
          <td style="text-align:left;"><strong>Total</strong></td>
          <td style="text-align:left;">#{total.time_string(format: :clock)}#{" (total budgets left #{budget_fmt.call(budgets_total)})" if budgets_total.positive?}</td>
        </tr>
        </tfoot>
        </table>
EOTAIL
        output + tail
      when :markdown
        pad = sorted_tags_data.map { |k, _| k }.group_by(&:size).max.last[0].length
        pad = 7 if pad < 7
        output = <<~EOHEADER
          | #{' ' * (pad - 7)}project | time     |
          | #{'-' * (pad - 1)}: | :------- |
        EOHEADER
        sorted_tags_data.reverse.each do |k, v|
          next unless v.positive?

          budget_str = ''
          if remaining_map.key?(k) && remaining_map[k].positive?
            budget_str = " (budget left #{budget_fmt.call(remaining_map[k])})"
          end
          output += "| #{' ' * (pad - k.length)}#{k} | #{v.time_string(format: :clock)}#{budget_str} |\n"
        end
        tail = '[Tag Totals]'
        output + tail
      when :json
        output = []
        sorted_tags_data.reverse.each do |k, v|
          output << {
            'tag' => k,
            'seconds' => v,
            'formatted' => v.time_string(format: :clock),
            'budget' => budgets[k],
            'remaining' => remaining_map[k],
            'remaining_formatted' => (remaining_map[k] && remaining_map[k].positive? ? budget_fmt.call(remaining_map[k]) : nil)
          }
        end
        output
      when :human
        output = []
        sorted_tags_data.reverse.each do |k, v|
          spacer = ''
          (max - k.length).times do
            spacer += ' '
          end
          line = "┃ #{spacer}#{k}:#{v.time_string(format: :hm)}"
          if remaining_map.key?(k) && remaining_map[k].positive?
            line += " (budget left #{budget_fmt.call(remaining_map[k])})"
          end
          line += ' ┃'
          output.push(line)
        end

        total_content = "┃ #{' ' * (max - 6)}total: #{total.time_string(format: :hm)}"
        total_content += " (total budgets left #{budget_fmt.call(budgets_total)})" if budgets_total.positive?
        total_content += ' ┃'
        max_line_len = (output + [total_content]).map(&:length).max

        pad_line = lambda do |line|
          pad = max_line_len - line.length
          pad.positive? ? "#{line[0..-3]} #{' ' * pad}┃" : line
        end
        output = output.map { |l| pad_line.call(l) }

        header = '┏━━ Tag Totals '
        [(max_line_len - 16), 0].max.times { header += '━' }
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
        total_line += " (total budgets left #{budget_fmt.call(budgets_total)})" if budgets_total.positive?
        total_line += ' ┃'
        total_line = pad_line.call(total_line)
        output += "\n#{total_line}"
        output += "\n#{footer}"
        output
      else
        output = []
        sorted_tags_data.reverse.each do |k, v|
          spacer = ''
          (max - k.length).times do
            spacer += ' '
          end
          line = "#{k}:#{spacer}#{v.time_string(format: :clock)}"
          if remaining_map.key?(k) && remaining_map[k].positive?
            line += " (budget left #{budget_fmt.call(remaining_map[k])})"
          end
          output.push(line)
        end

        output = output.empty? ? '' : "\n--- Tag Totals ---\n#{output.join("\n")}"
        output += "\n\nTotal tracked: #{total.time_string(format: :clock)}"
        if budgets_total.positive?
          output += " (total budgets left #{budget_fmt.call(budgets_total)})"
        end
        output += "\n"
        output
      end
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
  end
end
