# frozen_string_literal: true

module Doing
  # Terminal Prompt methods
  module Prompt
    class << self
      attr_writer :force_answer, :default_answer

      include Color

      def force_answer
        @force_answer ||= nil
      end

      def default_answer
        @default_answer ||= false
      end

      def enter_text(prompt, default_response: '')
        return default_response if @default_answer

        print "#{yellow(prompt).sub(/:?$/, ':')} #{reset}"
        $stdin.gets.strip
      end


      ##
      ## Ask a yes or no question in the terminal
      ##
      ## @param      question          [String] The question
      ##                               to ask
      ## @param      default_response  (Bool)   default
      ##                               response if no input
      ##
      ## @return     (Bool) yes or no
      ##
      def yn(question, default_response: false)
        unless @force_answer.nil?
          return @force_answer
        end

        default = if default_response.is_a?(String)
                    default_response =~ /y/i ? true : false
                  else
                    default_response
                  end

        # if global --default is set, answer default
        return default if @default_answer

        # if this isn't an interactive shell, answer default
        return default unless $stdout.isatty

        # clear the buffer
        if ARGV&.length
          ARGV.length.times do
            ARGV.shift
          end
        end
        system 'stty cbreak'

        cw = white
        cbw = boldwhite
        cbg = boldgreen
        cd = Color.default

        options = unless default.nil?
                    "#{cw}[#{default ? "#{cbg}Y#{cw}/#{cbw}n" : "#{cbw}y#{cw}/#{cbg}N"}#{cw}]#{cd}"
                  else
                    "#{cw}[#{cbw}y#{cw}/#{cbw}n#{cw}]#{cd}"
                  end
        $stdout.syswrite "#{cbw}#{question.sub(/\?$/, '')} #{options}#{cbw}?#{cd} "
        res = $stdin.sysread 1
        puts
        system 'stty cooked'

        res.chomp!
        res.downcase!

        return default if res.empty?

        res =~ /y/i ? true : false
      end

      def fzf
        @fzf ||= install_fzf
      end

      def install_fzf
        fzf_dir = File.join(File.dirname(__FILE__), '../helpers/fzf')
        FileUtils.mkdir_p(fzf_dir) unless File.directory?(fzf_dir)
        fzf_bin = File.join(fzf_dir, 'bin/fzf')
        return fzf_bin if File.exist?(fzf_bin)

        prev_level = Doing.logger.level
        Doing.logger.adjust_verbosity({ log_level: :info })
        Doing.logger.log_now(:warn, 'Compiling and installing fzf -- this will only happen once')
        Doing.logger.log_now(:warn, 'fzf is copyright Junegunn Choi, MIT License <https://github.com/junegunn/fzf/blob/master/LICENSE>')

        system("'#{fzf_dir}/install' --bin --no-key-bindings --no-completion --no-update-rc --no-bash --no-zsh --no-fish &> /dev/null")
        unless File.exist?(fzf_bin)
          Doing.logger.log_now(:warn, 'Error installing, trying again as root')
          system("sudo '#{fzf_dir}/install' --bin --no-key-bindings --no-completion --no-update-rc --no-bash --no-zsh --no-fish &> /dev/null")
        end
        raise RuntimeError.new('Error installing fzf, please report at https://github.com/ttscoff/doing/issues') unless File.exist?(fzf_bin)

        Doing.logger.info("fzf installed to #{fzf}")
        Doing.logger.adjust_verbosity({ log_level: prev_level })
        fzf_bin
      end

      ##
      ## Generate a menu of options and allow user selection
      ##
      ## @return     [String] The selected option
      ##
      def choose_from(options, prompt: 'Make a selection: ', multiple: false, sorted: true, fzf_args: [])
        return nil unless $stdout.isatty

        # fzf_args << '-1' # User is expecting a menu, and even if only one it seves as confirmation
        default_args = []
        default_args << %(--prompt="#{prompt}")
        default_args << "--height=#{options.count + 2}"
        default_args << '--info=inline'
        default_args << '--multi' if multiple
        header = "esc: cancel,#{multiple ? ' tab: multi-select, ctrl-a: select all,' : ''} return: confirm"
        default_args << %(--header="#{header}")
        default_args.concat(fzf_args)
        options.sort! if sorted
        res = `echo #{Shellwords.escape(options.join("\n"))}|#{fzf} #{fzf_args.join(' ')}`
        return false if res.strip.size.zero?

        res
      end

      ##
      ## Create an interactive menu to select from a set of Items
      ##
      ## @param      items            [Array] list of items
      ## @param      opt              Additional options
      ##
      ## @option opt [Boolean] :include_section Include section name for each item in menu
      ## @option opt [String] :header A custom header string
      ## @option opt [String] :prompt A custom prompt string
      ## @option opt [String] :query Initial query
      ## @option opt [Boolean] :show_if_single Show menu even if there's only one option
      ## @option opt [Boolean] :menu Show menu
      ## @option opt [Boolean] :sort Sort options
      ## @option opt [Boolean] :multiple Allow multiple selections
      ## @option opt [Symbol] :case (:sensitive, :ignore, :smart)
      ##
      def choose_from_items(items, **opt)
        return items unless $stdout.isatty

        return nil unless items.count.positive?

        case_sensitive = opt.fetch(:case, :smart).normalize_case
        header = opt.fetch(:header, 'Arrows: navigate, tab: mark for selection, ctrl-a: select all, enter: commit')
        prompt = opt.fetch(:prompt, 'Select entries to act on > ')
        query = opt.fetch(:query) { opt.fetch(:search, '') }
        include_section = opt.fetch(:include_section, false)

        pad = items.length.to_s.length
        options = items.map.with_index do |item, i|
          out = [
            format("%#{pad}d", i),
            ') ',
            format('%13s', item.date.relative_date),
            ' | ',
            item.title
          ]
          if include_section
            out.concat([
              ' (',
              item.section,
              ') '
            ])
          end
          out.join('')
        end

        fzf_args = [
          %(--header="#{header}"),
          %(--prompt="#{prompt.sub(/ *$/, ' ')}"),
          opt.fetch(:multiple) ? '--multi' : '--no-multi',
          '-0',
          '--bind ctrl-a:select-all',
          %(-q "#{query}"),
          '--info=inline'
        ]
        fzf_args.push('-1') unless opt.fetch(:show_if_single)
        fzf_args << case case_sensitive
                    when :sensitive
                      '+i'
                    when :ignore
                      '-i'
                    end
        fzf_args << '-e' if opt.fetch(:exact, false)


        unless opt.fetch(:menu)
          raise InvalidArgument, "Can't skip menu when no query is provided" unless query && !query.empty?

          fzf_args.concat([%(--filter="#{query}"), opt.fetch(:sort) ? '' : '--no-sort'])
        end

        res = `echo #{Shellwords.escape(options.join("\n"))}|#{fzf} #{fzf_args.join(' ')}`
        selected = []
        res.split(/\n/).each do |item|
          idx = item.match(/^ *(\d+)\)/)[1].to_i
          selected.push(items[idx])
        end

        opt.fetch(:multiple) ? selected : selected[0]
      end
    end
  end
end
