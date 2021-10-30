# frozen_string_literal: true

module Doing
  ##
  ## @brief      Log adapter
  ##
  class LogAdapter
    attr_writer :logdev, :max_length

    attr_reader :messages, :level, :results

    TOPIC_WIDTH = 12

    LOG_LEVELS = {
      debug: ::Logger::DEBUG,
      info: ::Logger::INFO,
      warn: ::Logger::WARN,
      error: ::Logger::ERROR
    }.freeze

    COUNT_KEYS = [
      :added_tags,
      :removed_tags,
      :added,
      :updated,
      :deleted,
      :completed,
      :archived,
      :moved,
      :completed_archived,
      :skipped
    ].freeze

    #
    # @brief      Create a new instance of a log writer
    #
    # @param      level   (optional, symbol) the log level
    #
    def initialize(level = :info)
      @messages = []
      @counters = {}
      COUNT_KEYS.each { |key| @counters[key] = { tag: [], count: 0 } }
      @results = []
      @logdev = $stderr
      @max_length = `tput cols`.strip.to_i - 5 || 85
      self.log_level = level
    end

    #
    # @brief      Set the log level on the writer
    #
    # @param      level  (symbol) the log level
    #
    # @return     nothing
    #
    def log_level=(level)
      level ||= 'info'
      level = level.to_s
      if level.is_a?(String) && level =~ /^([ewid]\w+|[0123])$/
        level = case level
                when /^[e0]/
                  :error
                when /^[w1]/
                  :warn
                when /^[i2]/
                  :info
                when /^[d3]/
                  :debug
                end
      else
        level = level.downcase.to_sym
      end

      @level = level
    end

    def adjust_verbosity(options = {})
      if options[:quiet]
        self.log_level = :error
      elsif options[:verbose] || options[:debug]
        self.log_level = :debug
      end
      log_now :debug, 'Logging at level:', @level.to_s
      # log_now :debug, 'Doing Version:', Doing::VERSION
    end

    def format_counter(key, data)
      case key
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
      end
    end

    def total_counters
      @counters.each do |key, data|
        next if data[:count].zero?

        count = data[:count]
        tags = data[:tag] ? data[:tag].uniq.map { |t| "@#{t}".cyan }.join(', ') : 'tags'
        topic, m = format_counter(key, data)
        message = m.dup
        message.sub!(/%count/, count.to_s)
        message.sub!(/%items/, count == 1 ? 'item' : 'items')
        message.sub!(/%tags/, tags)
        write(data[:level], topic, message)
      end
    end

    def count(key, level: :info, count: 1, tag: nil, message: nil)
      raise ArgumentError, 'invalid counter key' unless COUNT_KEYS.include?(key)

      @counters[key][:count] += count
      @counters[key][:tag].concat(tag).sort.uniq unless tag.nil?
      @counters[key][:level] ||= level
      @counters[key][:message] ||= message
    end

    #
    # @brief      Print a debug message
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
    # @brief      Print a message
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
    # @brief      Print a message
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
    # @brief      Print an error message
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
    # @brief      Print an error message and immediately
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
      message.truncmiddle!(@max_length - TOPIC_WIDTH - 5)
      out = topic + message
      out.truncate!(@max_length) if @max_length.positive?
      messages << out
      out
    end

    #
    # @brief      Format the topic
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
    # @brief      Check if the message should be written
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

    #
    # @brief      Log a message.
    #
    # @param      level_of_message  the Symbol level of
    #                               message, one of :debug,
    #                               :info, :warn, :error
    # @param      topic             the String topic or full
    #                               message
    # @param      message           the String message
    #                               (optional)
    # @param      block             a block containing the
    #                               message (optional)
    #
    # @return     false if the message was not written
    #
    def write(level_of_message, topic, message = nil, &block)
      @results << { level: level_of_message, message: message(topic, message, &block) }
      true
    end

    def log_now(level, topic, message = nil, &block)
      return false unless write_message?(level)

      # if @logdev == $stdout
      #   @logdev.puts message(topic, message, &block)
      # else
      #   @logdev.puts color_message(level, topic, message, &block)
      # end
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
        "#{topic_fg}#{m[1]}#{colors.reset}: #{message_fg}#{m[2]}"
      end

      "#{prefix} #{message.highlight_tags}#{colors.reset}"
    end

    def output_results
      total_counters

      results = @results.select { |msg| write_message?(msg[:level]) }.uniq

      if @logdev == $stdout
        $stdout.print results.map {|res| res[:message].uncolor }.join("\n")
      else
        results.each do |msg|
          @logdev.puts color_message(msg[:level], msg[:message])
        end
      end
    end
  end
end
