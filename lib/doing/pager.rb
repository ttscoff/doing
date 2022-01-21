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
      def paginate=(should_paginate)
        @paginate = should_paginate
      end

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

        pager = which_pager
        Doing.logger.debug('Pager:', "Using #{pager}")

        read_io, write_io = IO.pipe

        input = $stdin

        pid = Kernel.fork do
          write_io.close
          input.reopen(read_io)
          read_io.close

          # Wait until we have input before we start the pager
          IO.select [input]

          begin
            exec(pager)
          rescue SystemCallError => e
            raise Errors::DoingStandardError, "Pager error, #{e}"
          end
        end

        begin
          read_io.close
          write_io.write(text)
          write_io.close
        rescue SystemCallError # => e
          # raise Errors::DoingStandardError, "Pager error, #{e}"
        end

        _, status = Process.waitpid2(pid)
        status.success?
      end

      private

      def git_pager
        TTY::Which.exist?('git') ? `#{TTY::Which.which('git')} config --get-all core.pager` : nil
      end

      def pagers
        [ENV['GIT_PAGER'], ENV['PAGER'], git_pager,
         'bat -p --pager="less -Xr"', 'less -Xr', 'more -r'].compact
      end

      def find_executable(*commands)
        execs = commands.empty? ? pagers : commands
        execs
          .compact.map(&:strip).reject(&:empty?).uniq
          .find { |cmd| TTY::Which.exist?(cmd.split.first) }
      end

      def which_pager
        @which_pager ||= find_executable(*pagers)
      end
    end
  end
end
