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
        output.push(format('%<d>dd', d: d)) if d.positive?
        output.push(format('%<h>dh', h: h)) if h.positive?
        output.push(format('%<m>dm', m: m)) if m.positive?
        output.join(' ')
      when :hm
        h += d * 24 if d.positive?
        format('%<h> 4dh %<m>02dm', h: h, m: m)
      when :m
        h += d * 24 if d.positive?
        m += h * 60 if h.positive?
        format('%<m> 4dm', m: m)
      when :natural
        human = []
        human.push(format('%<d>d %<s>s', d: d, s: 'day'.to_p(d))) if d.positive?
        human.push(format('%<h>d %<s>s', h: h, s: 'hour'.to_p(h))) if h.positive?
        human.push(format('%<m>d %<s>s', m: m, s: 'minute'.to_p(m))) if m.positive?
        human.join(', ')
      when :speech
        human = []
        human.push(format('%<d>d %<s>s', d: d, s: 'day'.to_p(d))) if d.positive?
        human.push(format('%<h>d %<s>s', h: h, s: 'hour'.to_p(h))) if h.positive?
        human.push(format('%<m>d %<s>s', m: m, s: 'minute'.to_p(m))) if m.positive?
        last = human.pop
        case human.count
        when 2
          human.join(', ') + ", and #{last}"
        when 1
          "#{human[0]} and #{last}"
        when 0
          last
        end
      end
    end
  end
end
