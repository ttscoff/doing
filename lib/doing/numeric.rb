# frozen_string_literal: true

module Doing
  ##
  ## Number helpers
  ##
  class ::Numeric
    ##
    ## Format human readable time from seconds
    ##
    ## @param      seconds  [Integer] Seconds
    ##
    def format_time(human: false)
      return [0, 0, 0] if nil?

      seconds = dup.to_i
      minutes = (seconds / 60).to_i
      hours = (minutes / 60).to_i
      if human
        minutes = (minutes % 60).to_i
        [0, hours, minutes]
      else
        days = (hours / 24).to_i
        hours = (hours % 24).to_i
        minutes = (minutes % 60).to_i
        [days, hours, minutes]
      end
    end

    def time_string(format: :dhm)
      format_time(human: true).time_string(format: format)
    end
  end
end
