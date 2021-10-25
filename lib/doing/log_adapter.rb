# frozen_string_literal: true

module Doing
  ##
  ## @brief      Log adapter
  ##
  class LogAdapter
    attr_writer :logdev

    attr_reader :messages, :level, :results

    LOG_LEVELS = {
      debug: ::Logger::DEBUG,
      info: ::Logger::INFO,
      warn: ::Logger::WARN,
      error: ::Logger::ERROR
    }.freeze

    #
    # @brief      Create a new instance of a log writer
    #
    # @param      level   (optional, symbol) the log level
    #
    def initialize(level = :info)
      @messages = []
      @results = []
      @logdev = $stderr
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
      topic = formatted_topic(topic, colon: block_given?)
      out = topic + message
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
      "#{topic}#{colon ? ': ' : ' '}".rjust(20)
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
      LOG_LEVELS.fetch(level) <= LOG_LEVELS.fetch(level_of_message)
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
      return false unless write_message?(level_of_message)

      @results << { level: level_of_message, message: message(topic, message, &block) }
      true
    end

    def log_now(level, topic, message = nil, &block)
      return false unless write_message?(level)

      if @logdev == $stdout
        @logdev.puts message(topic, message, &block)
      else
        @logdev.puts color_message(level, topic, message, &block)
      end
    end

    def color_message(level, topic, message = nil, &block)
      colors = Doing::Color
      message = message(topic, message, &block)
      case level
      when :debug
        prefix = '> '.softpurple
        message = message.white
      when :warn
        prefix = '> '.boldyellow
        message = message.yellow
      when :error
        prefix = '!!'.boldred
        message = message.red
      else
        prefix = '  '
        message = message.boldwhite
      end

      "#{prefix} #{message.highlight_tags}#{colors.default}"
    end

    def output_results
      if @logdev == $stdout
        $stdout.print @results.map {|res| res[:message].uncolor }.join("\n")
      else
        @results.each do |msg|
          @logdev.puts color_message(msg[:level], msg[:message])
        end
      end
    end
  end
end
