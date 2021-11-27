# frozen_string_literal: true
require 'pathname'

module Doing
  # Pagination
  module Pager
    class << self
      def command_exist?(command)
        exts = ENV.fetch("PATHEXT", "").split(::File::PATH_SEPARATOR)
        if Pathname.new(command).absolute?
          ::File.exist?(command) ||
            exts.any? { |ext| ::File.exist?("#{command}#{ext}")}
        else
          ENV.fetch("PATH", "").split(::File::PATH_SEPARATOR).any? do |dir|
            file = ::File.join(dir, command)
            ::File.exist?(file) ||
              exts.any? { |ext| ::File.exist?("#{file}#{ext}") }
          end
        end
      end

      def git_pager
        command_exist?("git") ? `git config --get-all core.pager` : nil
      end

      def paginate
        @paginate ||= false
      end

      def paginate=(should_paginate)
        @paginate = should_paginate
      end

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
        rescue SystemCallError => e
          raise Errors::DoingStandardError, "Pager error, #{e}"
        end

        _, status = Process.waitpid2(pid)
        status.success?
      end

      def pagers
        [ENV['GIT_PAGER'], ENV['PAGER'], git_pager,
         'bat -p --pager="less -Xr"', 'less -Xr', 'more -r'].compact
      end

      def find_executable(*commands)
        execs = commands.empty? ? pagers : commands
        execs
          .compact.map(&:strip).reject(&:empty?).uniq
          .find { |cmd| command_exist?(cmd.split.first) }
      end

      def exec_available?(*commands)
        !find_executable(*commands).nil?
      end

      def which_pager
        @which_pager ||= find_executable(*pagers)
      end
    end
  end
end
