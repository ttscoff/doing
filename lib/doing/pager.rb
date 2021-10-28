# frozen_string_literal: true

module Doing
  # Pagination
  module Pager
    class << self
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

        read_io, write_io = IO.pipe

        input = $stdin

        pid = Kernel.fork do
          write_io.close
          input.reopen(read_io)
          read_io.close

          # Wait until we have input before we start the pager
          IO.select [input]

          pager = which_pager
          Doing.logger.debug('Pager:', "Using #{pager}")
          begin
            exec(pager.join(' '))
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

      def which_pager
        pagers = [ENV['GIT_PAGER'], ENV['PAGER']]

        if Util.exec_available('git')
          git_pager = `git config --get-all core.pager || true`.split.first
          git_pager && pagers.push(git_pager)
        end

        pagers.concat(%w[bat less more pager])

        pagers.select! do |f|
          if f
            if f.strip =~ /[ |]/
              f
            elsif f == 'most'
              Doing.logger.warn('most not allowed as pager')
              false
            else
              system "which #{f}", out: File::NULL, err: File::NULL
            end
          else
            false
          end
        end

        pg = pagers.first
        args = case pg
               when /^more$/
                 ' -r'
               when /^less$/
                 ' -Xr'
               when /^bat$/
                 ' -p --pager="less -Xr"'
               else
                 ''
               end

        [pg, args]
      end
    end
  end
end
