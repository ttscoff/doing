module Util
  ##
  ## @brief      Get total elapsed time for all tags in
  ##             selection
  ##
  ## @param      format        (String) return format (html,
  ##                           json, or text)
  ## @param      sort_by_name  (Boolean) Sort by name if true, otherwise by time
  ## @param      sort_order    (String) The sort order (asc or desc)
  ##
  def tag_times(format: :text, sort_by_name: false, sort_order: 'asc')
    return '' if $wwid.timers.empty?

    max = $wwid.timers.keys.sort_by { |k| k.length }.reverse[0].length + 1

    total = $wwid.timers.delete('All')

    tags_data = $wwid.timers.delete_if { |_k, v| v == 0 }
    sorted_tags_data = if sort_by_name
                         tags_data.sort_by { |k, _v| k }
                       else
                         tags_data.sort_by { |_k, v| v }
                       end

    sorted_tags_data.reverse! if sort_order =~ /^asc/i
    case format
    when :html

      output = <<EOS
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
EOS
      sorted_tags_data.reverse.each do |k, v|
        if v > 0
          output += "<tr><td style='text-align:left;'>#{k}</td><td style='text-align:left;'>#{'%02d:%02d:%02d' % fmt_time(v)}</td></tr>\n"
        end
      end
      tail = <<EOS
      <tr>
        <td style="text-align:left;" colspan="2"></td>
      </tr>
      </tbody>
      <tfoot>
      <tr>
        <td style="text-align:left;"><strong>Total</strong></td>
        <td style="text-align:left;">#{'%02d:%02d:%02d' % fmt_time(total)}</td>
      </tr>
      </tfoot>
      </table>
EOS
      output + tail
    when :markdown
      pad = sorted_tags_data.map {|k, v| k }.group_by(&:size).max.last[0].length
      output = <<-EOS
| #{' ' * (pad - 7) }project | time     |
| #{'-' * (pad - 1)}: | :------- |
      EOS
      sorted_tags_data.reverse.each do |k, v|
        if v > 0
          output += "| #{' ' * (pad - k.length)}#{k} | #{'%02d:%02d:%02d' % fmt_time(v)} |\n"
        end
      end
      tail = "[Tag Totals]"
      output + tail
    when :json
      output = []
      sorted_tags_data.reverse.each do |k, v|
        output << {
          'tag' => k,
          'seconds' => v,
          'formatted' => '%02d:%02d:%02d' % fmt_time(v)
        }
      end
      output
    else
      output = []
      sorted_tags_data.reverse.each do |k, v|
        spacer = ''
        (max - k.length).times do
          spacer += ' '
        end
        output.push("#{k}:#{spacer}#{'%02d:%02d:%02d' % fmt_time(v)}")
      end

      output = output.empty? ? '' : "\n--- Tag Totals ---\n" + output.join("\n")
      output += "\n\nTotal tracked: #{'%02d:%02d:%02d' % fmt_time(total)}\n"
      output
    end
  end

  ##
  ## @brief      Gets the interval between entry's start date and @done date
  ##
  ## @param      item       (Hash) The entry
  ## @param      formatted  (Bool) Return human readable time (default seconds)
  ##
  def get_interval(item, formatted: true, record: true)
    done = nil
    start = nil

    if $wwid.interval_cache.keys.include? item['title']
      seconds = $wwid.interval_cache[item['title']]
      record_tag_times(item, seconds) if record
      return seconds > 0 ? '%02d:%02d:%02d' % fmt_time(seconds) : false
    end

    if item['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/
      done = Time.parse(Regexp.last_match(1))
    else
      return false
    end

    start = if item['title'] =~ /@start\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/
              Time.parse(Regexp.last_match(1))
            else
              item['date']
            end

    seconds = (done - start).to_i

    if record
      record_tag_times(item, seconds)
    end

    $wwid.interval_cache[item['title']] = seconds

    return seconds > 0 ? seconds : false unless formatted

    seconds > 0 ? '%02d:%02d:%02d' % fmt_time(seconds) : false
  end

  ##
  ## @brief      Format human readable time from seconds
  ##
  ## @param      seconds  The seconds
  ##
  def fmt_time(seconds)
    return [0, 0, 0] if seconds.nil?

    if seconds =~ /(\d+):(\d+):(\d+)/
      h = Regexp.last_match(1)
      m = Regexp.last_match(2)
      s = Regexp.last_match(3)
      seconds = (h.to_i * 60 * 60) + (m.to_i * 60) + s.to_i
    end
    minutes = (seconds / 60).to_i
    hours = (minutes / 60).to_i
    days = (hours / 24).to_i
    hours = (hours % 24).to_i
    minutes = (minutes % 60).to_i
    [days, hours, minutes]
  end

  ##
  ## @brief      Record times for item tags
  ##
  ## @param      item  The item
  ##
  def record_tag_times(item, seconds)
    return if $wwid.recorded_items.include?(item)

    item['title'].scan(/(?mi)@(\S+?)(\(.*\))?(?=\s|$)/).each do |m|
      k = m[0] == 'done' ? 'All' : m[0].downcase
      if $wwid.timers.key?(k)
        $wwid.timers[k] += seconds
      else
        $wwid.timers[k] = seconds
      end
      $wwid.recorded_items.push(item)
    end
  end

  ##
  ## @brief      Test if command line tool is available
  ##
  ## @param      cli   The cli
  ##
  def exec_available(cli)
    if File.exist?(File.expand_path(cli))
      File.executable?(File.expand_path(cli))
    else
      system "which #{cli}", out: File::NULL, err: File::NULL
    end
  end
end
