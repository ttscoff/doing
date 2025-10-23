# frozen_string_literal: true

require 'pathname'

module Doing
  # Pagination
  module Pager
    class << self
      # Boolean determines whether output is paginated
      def paginate
        @paginate ||= false
      end

      # Enable/disable pagination
      #
      # @param      should_paginate  [Boolean] true to paginate
      attr_writer :paginate

      # Page output. If @paginate is false, just dump to
      # STDOUT
      #
      # @param      text  [String] text to paginate
      #
      def page(text)
        unless @paginate
          puts text
          return
        end

        # Smart pagination: skip pager for small outputs
        if should_skip_pager?(text)
          puts text
          return
        end

        # Use external pager (IO.popen for best performance and UX)
        external_pager(text)
      end

      # External pager using IO.popen for optimal performance and UX
      def external_pager(text)
        pager = which_pager
        Doing.logger.debug('Pager:', "Using external pager: #{pager}")

        begin
          IO.popen(pager, 'w') do |io|
            io.write(text)
            io.close_write
          end
        rescue SystemCallError => e
          # Fallback to direct output if pager fails
          puts text
          Doing.logger.debug('Pager:', "Pager failed, using direct output: #{e}")
        end
      end

      private

      # Smart pagination: skip pager for small outputs
      def should_skip_pager?(text)
        return true if text.nil? || text.empty?

        line_count = text.lines.count

        # Always paginate if output is very large (more than 200 lines)
        return false if line_count > 200

        # Check if output fits within 150% of terminal height
        term_height = terminal_height
        if term_height > 0
          # Only paginate if output is 150% of terminal height or more
          # This allows scrolling up half a page for reasonable outputs
          threshold = (term_height * 1.5).to_i
          return true if line_count < threshold
        end

        # Fallback: skip pager for small outputs (less than 50 lines)
        # This covers most typical doing commands while avoiding pager overhead
        line_count < 50
      end

      # Get terminal height, with caching and fallback
      def terminal_height
        @terminal_height ||= begin
          # Try TTY::Screen first (most reliable)
          if defined?(TTY::Screen) && TTY::Screen.respond_to?(:height)
            TTY::Screen.height
          # Fallback to stty
          elsif system('stty size >/dev/null 2>&1')
            `stty size`.split.first.to_i
          # Fallback to tput
          elsif system('tput lines >/dev/null 2>&1')
            `tput lines`.to_i
          # Last resort: assume 24 lines
          else
            24
          end
        rescue StandardError
          24
        end
      end

      def git_pager
        @git_pager ||= begin
          if TTY::Which.exist?('git')
            result = `#{TTY::Which.which('git')} config --get-all core.pager 2>/dev/null`.strip
            result.empty? ? nil : result
          else
            nil
          end
        rescue StandardError
          nil
        end
      end

      def pagers
        @pagers ||= [
          Doing.setting('editors.pager'),
          ENV['PAGER'],
          'less -FXr',
          ENV['GIT_PAGER'],
          git_pager,
          'more -r'
        ].remove_bad
      end

      def find_executable(*commands)
        execs = commands.empty? ? pagers : commands
        execs
          .remove_bad.uniq
          .find { |cmd| TTY::Which.exist?(cmd.split.first) }
      end

      def which_pager
        @which_pager ||= find_executable(*pagers)
      end
    end
  end
end
