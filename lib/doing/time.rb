module Doing
  ##
  ## Date helpers
  ##
  class ::Time
    def relative_date
      if self > Date.today.to_time
        strftime('%_I:%M%P')
      elsif self > (Date.today - 6).to_time
        strftime('%a %_I:%M%P')
      elsif self.year == Date.today.year || (self.year + 1 == Date.today.year && self.month > Date.today.month)
        strftime('%m/%d %_I:%M%P')
      else
        strftime('%m/%d/%y %_I:%M%P')
      end
    end

    def humanize(seconds)
      s = seconds
      m = (s / 60).floor
      s = (s % 60).floor
      h = (m / 60).floor
      m = (m % 60).floor
      d = (h / 24).floor
      h = h % 24

      output = []
      output.push("#{d} #{'day'.to_p(d)}") if d.positive?
      output.push("#{h} #{'hour'.to_p(h)}") if h.positive?
      output.push("#{m} #{'minute'.to_p(m)}") if m.positive?
      output.push("#{s} #{'second'.to_p(s)}") if s.positive?
      output.join(', ')
    end

    def time_ago
      if self > Date.today.to_time
        output = humanize(Time.now - self)
        "#{output} ago"
      elsif self > (Date.today - 1).to_time
        "Yesterday at #{strftime('%_I:%M:%S%P')}"
      elsif self > (Date.today - 6).to_time
        strftime('%a %I:%M:%S%P')
      elsif self.year == Date.today.year
        strftime('%m/%d %I:%M:%S%P')
      else
        strftime('%m/%d/%Y %I:%M:%S%P')
      end
    end
  end
end
