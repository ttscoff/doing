module Doing
  ##
  ## Date helpers
  ##
  class ::Time
    # Format time as a relative date. Dates from today get
    # just a time, from the last week get a time and day,
    # from the last year get a month/day/time, and older
    # entries get month/day/year/time
    #
    # @return     [String] formatted date
    #
    def relative_date
      if self > Date.today.to_time
        strftime(Doing.setting('shortdate_format.today', '%_I:%M%P', exact: true))
      elsif self > (Date.today - 6).to_time
        strftime(Doing.setting('shortdate_format.this_week', '%a %_I:%M%P', exact: true))
      elsif year == Date.today.year || (year + 1 == Date.today.year && month > Date.today.month)
        strftime(Doing.setting('shortdate_format.this_month', '%m/%d %_I:%M%P', exact: true))
      else
        strftime(Doing.setting('shortdate_format.older', '%m/%d/%y %_I:%M%P', exact: true))
      end
    end

    ##
    ## Format seconds as a natural language string
    ##
    ## @param      seconds  [Integer] number of seconds
    ##
    ## @return [String] Date formatted as "X days, X hours, X minutes, X seconds"
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

    ##
    ## Format date as "X hours ago"
    ##
    ## @return     [String] Formatted date
    ##
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
