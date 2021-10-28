# frozen_string_literal: true

module Doing
  module Errors

    class UserCancelled < ::StandardError
      def initialize(msg='Cancelled')
        Doing.logger.log_now(:warn, 'Exited:', msg)
        Process.exit 1
      end
    end

    class DoingStandardError < ::StandardError
      def initialize(msg='')
        Doing.logger.output_results

        super
      end
    end

    class DoingRuntimeError < ::RuntimeError
      def initialize(msg='')
        Doing.logger.output_results

        super
      end
    end

    class NoResults < ::StandardError
      def initialize(msg='No results')
        Doing.logger.output_results
        Process.exit 0

      end
    end

    class DoingNoTraceError < ::StandardError
      def initialize(msg = nil, level = nil)
        level ||= :error
        Doing.logger.output_results
        if msg
          Doing.logger.log_now(level, msg)
        end

        Process.exit 1
      end
    end

    class PluginException < ::StandardError
      attr_reader :plugin

      def initialize(msg = 'Plugin error', type: nil, plugin: nil)
        @plugin = plugin || 'Uknown Plugin'

        type ||= 'Unknown'
        @type = case type.to_s
                when /^i/
                  'Import plugin'
                when /^e/
                  'Export plugin'
                else
                  type.to_s
                end

        msg = "(#{@type}: #{@plugin}) #{msg}"

        Doing.logger.error('Plugin Error:', msg)
        Doing.logger.output_results
        Process.exit 1
      end
    end

    HookUnavailable = Class.new(PluginException)
    InvalidPluginType = Class.new(PluginException)
    PluginUncallable = Class.new(PluginException)

    InvalidArgument = Class.new(DoingRuntimeError)
    MissingArgument = Class.new(DoingRuntimeError)
    MissingFile = Class.new(DoingRuntimeError)
    MissingEditor = Class.new(DoingRuntimeError)
    NonInteractive = Class.new(StandardError)

    NoEntryError = Class.new(DoingRuntimeError)
    EmptyInput = Class.new(UserCancelled)

    InvalidTimeExpression = Class.new(DoingRuntimeError)
    InvalidSection = Class.new(DoingRuntimeError)
    InvalidView = Class.new(DoingRuntimeError)

    ItemNotFound = Class.new(DoingRuntimeError)
    # FatalException = Class.new(::RuntimeError)
    # InvalidPluginName = Class.new(FatalException)
  end
end
