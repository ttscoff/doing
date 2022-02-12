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
      raise Errors::InvalidTimeExpression, "Invalid time expression #{inspect}" if to_s.strip == ''

      secs_ago = if match(/^(\d+)$/)
                   # plain number, assume minutes
                   Regexp.last_match(1).to_i * 60
                 elsif (m = match(/^(?:(?<day>\d+)d)? *(?:(?<hour>\d+)h)? *(?:(?<min>\d+)m)?$/i))
                   # day/hour/minute format e.g. 1d2h30m
                   [[m['day'], 24 * 3600],
                    [m['hour'], 3600],
                    [m['min'], 60]].map { |qty, secs| qty ? (qty.to_i * secs) : 0 }.reduce(0, :+)
                 end

      if secs_ago
        res = now - secs_ago
        Doing.logger.debug('Parser:', %(date/time string "#{self}" interpreted as #{res} (#{secs_ago} seconds ago)))
      else
        date_string = dup
        date_string = 'today' if date_string.match(REGEX_DAY) && now.strftime('%a') =~ /^#{Regexp.last_match(1)}/i
        date_string = "#{options[:context].to_s} #{date_string}" if date_string =~ REGEX_TIME && options[:context]

        res = Chronic.parse(date_string, {
                              guess: options.fetch(:guess, :begin),
                              context: options.fetch(:future, false) ? :future : :past,
                              ambiguous_time_range: 8
                            })

        Doing.logger.debug('Parser:', %(date/time string "#{self}" interpreted as #{res}))
      end

      res
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

    ##
    ## Convert DD:HH:MM to seconds
    ##
    ## @return     [Integer] rounded number of seconds
    ##
    def to_seconds
      mtch = match(/(\d+):(\d+):(\d+)/)

      raise Errors::DoingRuntimeError, "Invalid time string: #{self}" unless mtch

      h = mtch[1]
      m = mtch[2]
      s = mtch[3]
      (h.to_i * 60 * 60) + (m.to_i * 60) + s.to_i
    end

    ##
    ## Convert DD:HH:MM to a natural language string
    ##
    ## @param      format  [Symbol] The format to output (:dhm, :hm, :m, :clock, :natural)
    ##
    def time_string(format: :dhm)
      to_seconds.time_string(format: format)
    end

    ##
    ## Convert (chronify) natural language dates
    ## within configured date tags (tags whose value is
    ## expected to be a date). Modifies string in place.
    ##
    ## @param      additional_tags  [Array] An array of
    ##                              additional tags to
    ##                              consider date_tags
    ##
    def expand_date_tags(additional_tags = nil)
      iso_rx = /\d{4}-\d\d-\d\d \d\d:\d\d/

      watch_tags = [
        'start(?:ed)?',
        'beg[ia]n',
        'done',
        'finished',
        'completed?',
        'waiting',
        'defer(?:red)?'
      ]

      if additional_tags
        date_tags = additional_tags
        date_tags = date_tags.split(/ *, */) if date_tags.is_a?(String)
        date_tags.map! do |tag|
          tag.sub(/^@/, '').gsub(/\((?!\?:)(.*?)\)/, '(?:\1)').strip
        end
        watch_tags.concat(date_tags).uniq!
      end

      done_rx = /(?<=^| )@(?<tag>#{watch_tags.join('|')})\((?<date>.*?)\)/i

      gsub!(done_rx) do
        m = Regexp.last_match
        t = m['tag']
        d = m['date']
        future = t =~ /^(done|complete)/ ? false : true
        parsed_date = d =~ iso_rx ? Time.parse(d) : d.chronify(guess: :begin, future: future)
        parsed_date.nil? ? m[0] : "@#{t}(#{parsed_date.strftime('%F %R')})"
      end
    end

    def is_range?
      self =~ / (to|through|thru|(un)?til|-+) /
    end

    ##
    ## Splits a range string and returns an array of
    ## DateTime objects as [start, end]. If only one date is
    ## given, end time is nil.
    ##
    ## @return     [Array<DateTime>] Start and end dates as
    ##             array
    ## @example    Process a natural language date range
    ##   "mon 3pm to mon 5pm".split_date_range
    ##
    def split_date_range
      time_rx = /^(\d{1,2}+(:\d{1,2}+)?( *(am|pm))?|midnight|noon)$/
      range_rx = / (to|through|thru|(?:un)?til|-+) /

      date_string = dup

      if date_string.is_range?
        # Do we want to differentiate between "to" and "through"?
        # inclusive = date_string =~ / (through|thru|-+) / ? true : false
        inclusive = true

        dates = date_string.split(range_rx)
        if dates[0].strip =~ time_rx && dates[-1].strip =~ time_rx
          start = dates[0].strip
          finish = dates[-1].strip
        else
          start = dates[0].chronify(guess: :begin, future: false)
          finish = dates[-1].chronify(guess: inclusive ? :end : :begin, future: false)
        end

        raise Errors::InvalidTimeExpression, 'Unrecognized date string' if start.nil? || finish.nil?

      else
        if date_string.strip =~ time_rx
          start = date_string.strip
          finish = nil
        else
          start = date_string.strip.chronify(guess: :begin, future: false)
          finish = date_string.strip.chronify(guess: :end)
        end
        raise Errors::InvalidTimeExpression, 'Unrecognized date string' unless start

      end


      if start.is_a? String
        Doing.logger.debug('Parser:', "--from string interpreted as time span, from #{start || '12am'} to #{finish || '11:59pm'}")
      else
        Doing.logger.debug('Parser:', "date range interpreted as #{start.strftime('%F %R')} -- #{finish ? finish.strftime('%F %R') : 'now'}")
      end
      [start, finish]
    end
  end
end
