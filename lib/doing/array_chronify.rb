# frozen_string_literal: true

module Doing
  # Chronify array helpers
  class ::Array
    ##
    ## Format [d, h, m] as string
    ##
    ## @param      time    [Array] Array of [days, hours,
    ##                     minutes]
    ## @param      format  [Symbol] The format, :dhm, :hm, :m, :clock, :natural
    ## @return     [String] formatted string
    ##
    def time_string(format: :dhm)
      raise InvalidArgument, 'Invalid array, must be [d,h,m]' unless count == 3

      d, h, m = self
      case format
      when :clock
        format('%<d>02d:%<h>02d:%<m>02d', d: d, h: h, m: m)
      when :dhm
        output = []
        output.push(format('%<d>2dd', d: d)) if d.positive?
        output.push(format('%<h>2dh', h: h)) if h.positive?
        output.push(format('%<m>2dm', m: m)) if m.positive?
        output.join('')
      when :hm
        h += d * 24 if d.positive?
        format('%<h> 4dh %<m>02dm', h: h, m: m)
      when :m
        h += d * 24 if d.positive?
        m += h * 60 if h.positive?
        format('%<m> 4dm', m: m)
      when :natural
        human = []
        human.push(format('%<d>2d days', d: d)) if d.positive?
        human.push(format('%<h>2d hours', h: h)) if h.positive?
        human.push(format('%<m>2d minutes', m: m)) if m.positive?
        human.join(', ')
      end
    end
  end
end
