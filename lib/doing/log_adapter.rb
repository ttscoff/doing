# frozen_string_literal: true

module Doing
  ##
  ## @brief      Log adapter
  ##
  class LogAdapter
    attr_reader :writer, :messages, :level

    LOG_LEVELS = {
      debug: ::Logger::DEBUG,
      info: ::Logger::INFO,
      warn: ::Logger::WARN,
      error: ::Logger::ERROR
    }.freeze

    #
    # @brief      Create a new instance of a log writer
    #
    # @param      writer  Logger compatible instance
    # @param      level   (optional, symbol) the log level
    #
    def initialize(writer, level = :info)
      @messages = []
      @writer = writer
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
      writer.level = level if level.is_a?(Integer) && level.between?(0, 3)
      writer.level = LOG_LEVELS[level] || raise(ArgumentError, 'unknown log level')

      @level = level
    end

    def adjust_verbosity(options = {})
      # Quiet always wins.
      if options[:quiet]
        self.log_level = :error
      elsif options[:verbose]
        self.log_level = :debug
      end
      debug 'Logging at level:', LOG_LEVELS.key(writer.level).to_s
      debug 'Doing Version:', Doing::VERSION
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
    # @return     false if the message was not written, otherwise
    #             returns the value of calling the appropriate
    #             writer method, e.g. writer.info.
    #
    def write(level_of_message, topic, message = nil, &block)
      return false unless write_message?(level_of_message)

      writer.public_send(level_of_message, message(topic, message, &block))
    end
  end
end
