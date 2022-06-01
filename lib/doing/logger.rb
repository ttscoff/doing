# frozen_string_literal: true

module Doing
  ##
  ## Log adapter
  ##
  class Logger
    # Sets the log device
    attr_writer :logdev

    # Max length of log messages (truncate in middle)
    attr_writer :max_length

    # Returns the current log level (debug, info, warn, error)
    attr_reader :level

    attr_reader :messages, :results

    TOPIC_WIDTH = 12

    LOG_LEVELS = {
      debug: ::Logger::DEBUG,
      info: ::Logger::INFO,
      warn: ::Logger::WARN,
      error: ::Logger::ERROR
    }.freeze

    COUNT_KEYS = %i[
      added
      added_tags
      archived
      autotag
      completed
      completed_archived
      deleted
      moved
      removed_tags
      rotated
      skipped
      updated
      exported
    ].freeze

    #
    # Create a new instance of a log writer
    #
    # @param      level   (optional, symbol) the log level
    #
    def initialize(level = :info)
      @messages = []
      @counters = {}
      COUNT_KEYS.each { |key| @counters[key] = { tag: [], count: 0 } }
      @results = []
      @logdev = $stderr
      @max_length = TTY::Screen.columns - 5 || 85
      self.log_level = level
      @prev_level = level
    end

    #
    # Set the log level on the writer
    #
    # @param      level  (symbol) the log level
    #
    # @return     nothing
    #
    def log_level=(level = 'info')
      level = level.to_s

      level = case level
              when /^[e0]/i
                :error
              when /^[w1]/i
                :warn
              when /^[d3]/i
                :debug
              else
                :info
              end

      @level = level
    end

    # Set log level temporarily
    def temp_level(level)
      return if level.nil? || level.to_sym == @log_level

      @prev_level = log_level.dup
      @log_level = level.to_sym
    end

    # Restore temporary level
    def restore_level
      return if @prev_level.nil? || @prev_level == @log_level

      self.log_level = @prev_level
      @prev_level = nil
    end

    def adjust_verbosity(options = {})
      if options[:log_level]
        self.log_level = options[:log_level].to_sym
      elsif options[:quiet]
        self.log_level = :error
      elsif options[:verbose] || options[:debug]
        self.log_level = :debug
      end
      log_now :debug, 'Logging at level:', @level.to_s
      # log_now :debug, 'Doing Version:', Doing::VERSION
    end

    def count(key, level: :info, count: 1, tag: nil, message: nil)
      raise ArgumentError, 'invalid counter key' unless COUNT_KEYS.include?(key)

      @counters[key][:count] += count
      @counters[key][:tag].concat(tag).sort.uniq unless tag.nil?
      @counters[key][:level] ||= level
      @counters[key][:message] ||= message
    end

    #
    # Print a debug message
    #
    # @param      topic    the topic of the message
    # @param      message  the message detail
    #
    # @return     nothing
    #
    def debug(topic, message = nil, &block)
      write(:debug, topic, message, &block)
    end

    #
    # Print a message
    #
    # @param      topic    the topic of the message, e.g.
    #                      "Configuration file",
    #                      "Deprecation", etc.
    # @param      message  the message detail
    #
    # @return     nothing
    #
    def info(topic, message = nil, &block)
      write(:info, topic, message, &block)
    end

    #
    # Print a message
    #
    # @param      topic    the topic of the message, e.g.
    #                      "Configuration file",
    #                      "Deprecation", etc.
    # @param      message  the message detail
    #
    # @return     nothing
    #
    def warn(topic, message = nil, &block)
      write(:warn, topic, message, &block)
    end

    #
    # Print an error message
    #
    # @param      topic    the topic of the message, e.g.
    #                      "Configuration file",
    #                      "Deprecation", etc.
    # @param      message  the message detail
    #
    # @return     nothing
    #
    def error(topic, message = nil, &block)
      write(:error, topic, message, &block)
    end

    #
    # Print an error message and immediately
    #             abort the process
    #
    # @param      topic    the topic of the message, e.g.
    #                      "Configuration file",
    #                      "Deprecation", etc.
    # @param      message  the message detail (can be
    #                      omitted)
    #
    # @return     nothing
    #
    def abort_with(topic, message = nil, &block)
      error(topic, message, &block)
      abort
    end

    #
    # Format the topic
    #
    # @param      topic  the topic of the message, e.g.
    #                    "Configuration file",
    #                    "Deprecation", etc.
    # @param      colon  Separate with a colon?
    #
    # @return     the formatted topic statement
    #
    def formatted_topic(topic, colon: false)
      if colon
        "#{topic}: ".rjust(TOPIC_WIDTH)
      elsif topic =~ /:$/
        "#{topic} ".rjust(TOPIC_WIDTH)
      else
        "#{topic} "
      end
    end

    #
    # Log a message.
    #
    # @param      level_of_message  [Symbol] the Symbol
    #                               level of message, one of
    #                               :debug, :info, :warn,
    #                               :error
    # @param      topic             [String] the String
    #                               topic or full message
    # @param      message           [String] the String
    #                               message (optional)
    # @param      block             a block containing the
    #                               message (optional)
    #
    # @return     [Boolean] false if the message was not written
    #
    def write(level_of_message, topic, message = nil, &block)
      @results << { level: level_of_message, message: message(topic, message, &block) }
      true
    end

    ##
    ## Log to console immediately instead of writing messages on exit
    ##
    ## @param      level    [Symbol] The level
    ## @param      topic    [String] The topic or full message
    ## @param      message  [String] The message (optional)
    ## @param      block    a block containing the message (optional)
    ##
    def log_now(level, topic, message = nil, &block)
      return false unless write_message?(level)

      if @logdev == $stdout
        @logdev.puts message(topic, message, &block)
      else
        @logdev.puts color_message(level, topic, message, &block)
      end
    end

    ##
    ## Output registers based on log level
    ##
    ## @return     nothing
    ##
    def output_results
      total_counters
      results = @results.select { |msg| write_message?(msg[:level]) }.uniq

      if @logdev == $stdout
        $stdout.print results.map { |res| res[:message].uncolor }.join("\n")
        $stdout.puts
      else
        results.each do |msg|
          @logdev.puts color_message(msg[:level], msg[:message])
        end
      end
    end

    def benchmark(key, state)
      return unless ENV['DOING_BENCHMARK']

      @benchmarks ||= {}
      @benchmarks[key] ||= { start: nil, finish: nil }
      @benchmarks[key][state] = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def log_benchmarks
      if ENV['DOING_BENCHMARK']

        output = []
        beginning = @benchmarks[:total][:start]
        ending = @benchmarks[:total][:finish]
        total = ending - beginning
        factor = TTY::Screen.columns / total

        cols = Array.new(TTY::Screen.columns)

        colors = %w[bgred bggreen bgyellow bgblue bgmagenta bgcyan bgwhite boldbgred boldbggreen boldbgyellow boldbgblue boldbgwhite]
        idx = 0
        # @benchmarks.delete(:total)

        @benchmarks.sort_by { |_, timers| [timers[:start], timers[:finish]] }.each do |k, timers|
          if timers[:finish] && timers[:start]
            color = colors[idx % colors.count]
            fg = if idx < 7
                   Color.boldblack
                 else
                   Color.boldwhite
                 end
            color = Color.send(color) + fg

            start = ((timers[:start] - beginning) * factor).floor
            finish = ((timers[:finish] - beginning) * factor).ceil

            cols.fill("#{color}-", start..finish)
            cols[start] = "#{color}|"
            cols[finish] = "#{color}|"
            output << "#{color}#{k}#{Color.default}: #{timers[:finish] - timers[:start]}"
          else
            output << "#{k}: error"
          end

          idx += 1
        end

        output.each do |msg|
          $stdout.puts color_message(:debug, 'Benchmark:', msg)
        end

        $stdout.puts color_message(:debug, 'Benchmark:', "Total: #{total}")

        $stdout.puts cols[0..TTY::Screen.columns-1].join + Color.reset
      end
    end

    def log_change(tags_added: [], tags_removed: [], count: 1, item: nil, single: false)
      if tags_added.empty? && tags_removed.empty?
        count(:skipped, level: :debug, message: '%count %items with no change', count: count)
      else
        if tags_added.empty?
          count(:skipped, level: :debug, message: 'no tags added to %count %items')
        elsif single && item
          elapsed = if item && tags_added.include?('done')
                      item.interval ? " (#{item.interval&.time_string(format: :dhm)})" : ''
                    else
                      ''
                    end

          added = tags_added.log_tags
          info('Tagged:',
               %(added #{tags_added.count == 1 ? 'tag' : 'tags'} #{added}#{elapsed} to #{item.title}))
        else
          count(:added_tags, level: :info, tag: tags_added, message: '%tags added to %count %items')
        end

        if tags_removed.empty?
          count(:skipped, level: :debug, message: 'no tags removed from %count %items')
        elsif single && item
          removed = tags_removed.log_tags
          info('Untagged:',
               %(removed #{tags_removed.count == 1 ? 'tag' : 'tags'} #{removed} from #{item.title}))
        else
          count(:removed_tags, level: :info, tag: tags_removed, message: '%tags removed from %count %items')
        end
      end
    end

    private

    def format_counter(key, data)
      case key
      when :rotated
        ['Rotated:', data[:message] || 'rotated %count %items']
      when :autotag
        ['Autotag:', data[:message] || 'autotagged %count %items']
      when :added_tags
        ['Tagged:', data[:message] || 'added %tags to %count %items']
      when :removed_tags
        ['Untagged:', data[:message] || 'removed %tags from %count %items']
      when :added
        ['Added:', data[:message] || 'added %count new %items']
      when :updated
        ['Updated:', data[:message] || 'updated %count %items']
      when :deleted
        ['Deleted:', data[:message] || 'deleted %count %items']
      when :moved
        ['Moved:', data[:message] || 'moved %count %items']
      when :completed
        ['Completed:', data[:message] || 'completed %count %items']
      when :archived
        ['Archived:',  data[:message] || 'archived %count %items']
      when :completed_archived
        ['Archived:',  data[:message] || 'completed and archived %count %items']
      when :skipped
        ['Skipped:', data[:message] || '%count %items were unchanged']
      when :exported
        ['Exported:', data[:message] || '%count %items were exported']
      end
    end

    def total_counters
      @counters.each do |key, data|
        next if data[:count].zero?

        count = data[:count]
        tags = data[:tag] ? data[:tag].uniq.map { |t| t.add_at.cyan }.join(', ') : 'tags'
        topic, m = format_counter(key, data)
        message = m.dup
        message.sub!(/%count/, count.to_s)
        message.sub!(/%items/, count == 1 ? 'item' : 'items')
        message.sub!(/%tags/, tags)
        write(data[:level], topic, message)
      end
    end

    #
    # Check if the message should be written
    #             given the log level.
    #
    # @param      level_of_message  the Symbol level of
    #                               message, one of :debug,
    #                               :info, :warn, :error
    #
    # @return     whether the message should be written.
    #
    def write_message?(level_of_message)
      LOG_LEVELS.fetch(@level) <= LOG_LEVELS.fetch(level_of_message)
    end

    # Internal: Build a topic method
    #
    # @param      topic    the topic of the message, e.g.
    #                      "Configuration file",
    #                      "Deprecation", etc.
    # @param      message  the message detail
    #
    # @return     the formatted message
    #
    def message(topic, message = nil)
      raise ArgumentError, 'block or message, not both' if block_given? && message

      message = yield if block_given?
      message = message.to_s.gsub(/\s+/, ' ')

      return topic.ljust(TOPIC_WIDTH) if topic && message.strip.empty?

      topic = formatted_topic(topic, colon: block_given?)
      # message.truncmiddle!(@max_length - TOPIC_WIDTH - 5)
      out = topic + message
      # out.truncate!(@max_length) if @max_length.positive?
      messages << out
      out
    end

    def color_message(level, topic, message = nil, &block)
      colors = Doing::Color
      message = message(topic, message, &block)
      prefix = '  '
      topic_fg = colors.boldcyan
      message_fg = colors.boldwhite

      case level
      when :debug
        prefix = '> '.softpurple
        topic_fg = colors.softpurple
        message_fg = colors.white
      when :warn
        prefix = '> '.boldyellow
        topic_fg = colors.boldyellow
        message_fg = colors.yellow
      when :error
        prefix = '!!'.boldred
        topic_fg = colors.flamingo
        message_fg = colors.red
      end

      message.sub!(/^(\s*\S.*?): (.*?)$/) do
        m = Regexp.last_match
        msg = m[2] =~ /(\e\[[\d;]+m)/ ? msg : "#{message_fg}#{m[2]}"

        "#{topic_fg}#{m[1]}#{colors.reset}: #{message_fg}#{m[2]}"
      end

      "#{prefix} #{message.highlight_tags}#{colors.reset}"
    end
  end
end
