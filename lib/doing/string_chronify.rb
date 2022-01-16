# frozen_string_literal: true

module Doing
  # Chronify methods for strings
  class ::String
    ##
    ## Converts input string into a Time object when input
    ## takes on the following formats:
    ##             - interval format e.g. '1d2h30m', '45m'
    ##               etc.
    ##             - a semantic phrase e.g. 'yesterday
    ##               5:30pm'
    ##             - a strftime e.g. '2016-03-15 15:32:04
    ##               PDT'
    ##
    ## @param      options  Additional options
    ##
    ## @option options :future [Boolean] assume future date
    ##                                   (default: false)
    ##
    ## @option options :guess  [Symbol] :begin or :end to
    ##                                   assume beginning or end of
    ##                                   arbitrary time range
    ##
    ## @return     [DateTime] result
    ##
    def chronify(**options)
      now = Time.now
      raise InvalidTimeExpression, "Invalid time expression #{inspect}" if to_s.strip == ''

      secs_ago = if match(/^(\d+)$/)
                   # plain number, assume minutes
                   Regexp.last_match(1).to_i * 60
                 elsif (m = match(/^(?:(?<day>\d+)d)?(?:(?<hour>\d+)h)?(?:(?<min>\d+)m)?$/i))
                   # day/hour/minute format e.g. 1d2h30m
                   [[m['day'], 24 * 3600],
                    [m['hour'], 3600],
                    [m['min'], 60]].map { |qty, secs| qty ? (qty.to_i * secs) : 0 }.reduce(0, :+)
                 end

      if secs_ago
        now - secs_ago
      else
        Chronic.parse(self, {
                        guess: options.fetch(:guess, :begin),
                        context: options.fetch(:future, false) ? :future : :past,
                        ambiguous_time_range: 8
                      })
      end
    end

    ##
    ## Converts simple strings into seconds that can be
    ## added to a Time object
    ##
    ## Input string can be HH:MM or XX[dhm][[XXhm][XXm]]
    ## (1d2h30m, 45m, 1.5d, 1h20m, etc.)
    ##
    ## @return     [Integer] seconds
    ##
    def chronify_qty
      minutes = 0
      case self.strip
      when /^(\d+):(\d\d)$/
        minutes += Regexp.last_match(1).to_i * 60
        minutes += Regexp.last_match(2).to_i
      when /^(\d+(?:\.\d+)?)([hmd])?/
        scan(/(\d+(?:\.\d+)?)([hmd])?/).each do |m|
          amt = m[0]
          type = m[1].nil? ? 'm' : m[1]

          minutes += case type.downcase
                     when 'm'
                       amt.to_i
                     when 'h'
                       (amt.to_f * 60).round
                     when 'd'
                       (amt.to_f * 60 * 24).round
                     else
                       0
                     end
        end
      end
      minutes * 60
    end
  end
end
