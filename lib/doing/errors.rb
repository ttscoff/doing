# frozen_string_literal: true

module Doing
  module Errors
    class DoingNoTraceError < ::StandardError
      def initialize(msg = nil, level: nil, topic: 'Error:', exit_code: 1)
        level ||= :error
        Doing.logger.output_results
        if msg
          Doing.logger.log_now(level, topic, msg)
        end

        Process.exit exit_code
      end
    end

    class UserCancelled < DoingNoTraceError
      def initialize(msg = 'Cancelled', topic = 'Exited:')
        super(msg, level: :warn, topic: topic, exit_code: 1)
      end
    end

    class EmptyInput < DoingNoTraceError
      def initialize(msg = 'No input', topic = 'Exited:')
        super(msg, level: :warn, topic: topic, exit_code: 6)
      end
    end

    class DoingStandardError < ::StandardError
      def initialize(msg = '')
        Doing.logger.output_results

        super(msg)
      end
    end

    class WrongCommand < DoingNoTraceError
      def initialize(msg = 'wrong command', topic: 'Error:')
        super(msg, level: :warn, topic: topic, exit_code: 2)
      end
    end

    class DoingRuntimeError < ::RuntimeError
      def initialize(msg = 'Runtime Error', exit_code = nil, topic: 'Error:')
        Doing.logger.output_results
        Doing.logger.log_now(:error, topic, msg)

        Process.exit exit_code if exit_code
      end
    end

    class NoResults < DoingNoTraceError
      def initialize(msg = 'No results', topic = 'Exited:')
        super(msg, level: :warn, topic: topic, exit_code: 0)

      end
    end

    class HistoryLimitError < DoingNoTraceError
      def initialize(msg, exit_code = 24)
        super(msg, level: :error, topic: 'History:', exit_code: exit_code)
      end
    end

    class MissingBackupFile < DoingNoTraceError
      def initialize(msg, exit_code = 26)
        super(msg, level: :error, topic: 'History:', exit_code: exit_code)
      end
    end

    class InvalidPlugin < DoingRuntimeError
      def initialize(kind = 'output', msg = nil)
        super(%(Invalid #{kind} type (#{msg})), 128, topic: 'Plugin:')
      end
    end

    class PluginException < ::StandardError
      attr_reader :plugin

      def initialize(msg = 'Plugin error', type = nil, plugin = nil)
        @plugin = plugin || 'Unknown Plugin'

        type ||= 'Unknown'
        @type = case type.to_s
                when /^i/
                  'Import plugin'
                when /^e/
                  'Export plugin'
                when /^h/
                  'Hook'
                when /^u/
                  'Unrecognized'
                else
                  type.to_s
                end

        msg = "(#{@type}: #{@plugin}) #{msg}"

        Doing.logger.log_now(:error, 'Plugin:', msg)

        super(msg)
      end
    end

    HookUnavailable = Class.new(PluginException)
    InvalidPluginType = Class.new(PluginException)
    PluginUncallable = Class.new(PluginException)

    InvalidArgument = Class.new(DoingNoTraceError)
    MissingArgument = Class.new(DoingNoTraceError)
    MissingFile = Class.new(DoingNoTraceError)
    MissingEditor = Class.new(DoingNoTraceError)
    NonInteractive = Class.new(StandardError)

    NoEntryError = Class.new(DoingNoTraceError)

    InvalidTimeExpression = Class.new(DoingRuntimeError)
    InvalidSection = Class.new(DoingNoTraceError)
    InvalidView = Class.new(DoingNoTraceError)

    ItemNotFound = Class.new(DoingRuntimeError)
    # FatalException = Class.new(::RuntimeError)
    # InvalidPluginName = Class.new(FatalException)
  end
end
