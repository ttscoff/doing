# frozen_string_literal: true

module Doing
  ##
  ## Array helpers
  ##
  class ::Array
    ##
    ## Convert an @tags to plain strings
    ##
    ## @return     [Array] array of strings
    ##
    def tags_to_array
      map { |t| t.sub(/^@/, '') }
    end

    # Convert strings to @tags
    #
    # @example `['one', '@two', 'three'].to_tags`
    # @example `=> ['@one', '@two', '@three']`
    # @return     [Array] Array of @tags
    #
    def to_tags
      map { |t| t.sub(/^@?/, '@') }
    end

    def to_tags!
      replace to_tags
    end

    ##
    ## Hightlight @tags in string for console output
    ##
    ## @param      color  [String] the color to highlight
    ##                    with
    ##
    ## @return     [String] string with @tags highlighted
    ##
    def highlight_tags(color = 'cyan')
      tag_color = Doing::Color.send(color)
      to_tags.map { |t| "#{tag_color}#{t}" }
    end

    ##
    ## Tag array for logging
    ##
    ## @return     [String] Highlighted tag array joined with comma
    ##
    def log_tags
      highlight_tags.join(', ')
    end

    ##
    ## Convert array to nested hash, setting last key to value
    ##
    ## @param      value  The value to set
    ##
    def nested_hash(value)
      raise StandardError, 'Value can not be nil' if value.nil?

      hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      hsh.dig(*self[0..-2])[self.fetch(-1)] = value
      hsh
    end

    ##
    ## Format [d, h, m] as string
    ##
    ## @param      time    [Array] Array of [days, hours,
    ##                     minutes]
    ## @param      format  [Symbol] The format, :dhm, :clock, :natural
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
