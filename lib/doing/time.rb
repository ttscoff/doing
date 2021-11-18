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
      elsif self.year == Date.today.year
        strftime('%m/%d %_I:%M%P')
      else
        strftime('%m/%d/%Y %_I:%M%P')
      end
    end
  end
end
