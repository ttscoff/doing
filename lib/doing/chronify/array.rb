# frozen_string_literal: true

module Doing
  # Chronify array helpers
  module ChronifyArray
    # Convert [d, h, m] to [y, d, h, m]
    def to_years
      d, h, m = self

      if d.zero? && h > 24
        d = (h / 24).floor
        h = h % 24
      end

      if d > 365
        y = (d / 365).floor
        d = d % 365
      else
        y = 0
      end

      [y, d, h, m]
    end

    def to_natural
      y, d, h, m = to_years
      human = []
      human.push(format('%<y>d %<s>s', y: y, s: 'year'.to_p(y))) if y.positive?
      human.push(format('%<d>d %<s>s', d: d, s: 'day'.to_p(d))) if d.positive?
      human.push(format('%<h>d %<s>s', h: h, s: 'hour'.to_p(h))) if h.positive?
      human.push(format('%<m>d %<s>s', m: m, s: 'minute'.to_p(m))) if m.positive?
      human
    end

    def to_abbr(years: false, separator: '')
      if years
        y, d, h, m = to_years
      else
        y = 0
        d, h, m = self

        if d.zero? && h > 24
          d = (h / 24).floor
          h = h % 24
        end
      end

      output = []
      output.push(format('%<y>dy', y: y)) if y.positive?
      output.push(format('%<d>dd', d: d)) if d.positive?
      output.push(format('%<h>dh', h: h)) if h.positive?
      output.push(format('%<m>dm', m: m)) if m.positive?
      output.join(separator)
    end

    ##
    ## Format [d, h, m] as string
    ##
    ## @param      format  [Symbol] The format, :dhm, :hm,
    ##                     :m, :clock, :natural
    ## @return     [String] formatted string
    ##
    def time_string(format: :dhm)
      raise InvalidArgument, 'Invalid array, must be [d,h,m]' unless count == 3

      d, h, m = self
      case format
      when :clock
        if d.zero? && h > 24
          d = (h / 24).floor
          h = h % 24
        end
        format('%<d>02d:%<h>02d:%<m>02d', d: d, h: h, m: m)
      when :hmclock
        h += d * 24 if d.positive?
        format('%<h>02d:%<m>02d', h: h, m: m)
      when :ydhm
        to_abbr(years: true, separator: ' ')
      when :dhm
        to_abbr(years: false, separator: ' ')
      when :hm
        h += d * 24 if d.positive?
        format('%<h> 4dh %<m>02dm', h: h, m: m)
      when :m
        h += d * 24 if d.positive?
        m += h * 60 if h.positive?
        format('%<m> 4dm', m: m)
      when :tight
        to_abbr(years: true, separator: '')
      when :natural
        to_natural.join(', ')
      when :speech
        human = to_natural
        last = human.pop
        case human.count
        when 0
          last
        when 1
          "#{human[0]} and #{last}"
        else
          human.join(', ') + ", and #{last}"
        end
      end
    end
  end
end
