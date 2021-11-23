module Doing
  module Completion
    class BashCompletions
      attr_accessor :commands, :global_options

      def main_function
        first = true
        out = []
        logic = []
        need_export = []

        @commands.each_with_index do |cmd, i|
          @bar.advance

          data = get_help_sections(cmd[:commands].first)

          arg = data[:synopsis].join(' ').strip.split(/ /).last
          case arg
          when /(path|file)/i
            type = :file
          when /sect/i
            type = 'sections'
          when /view/i
            type = 'views'
          else
            type = nil
          end

          if data[:command_options]
            options = parse_options(data[:command_options])
            out << command_function(cmd[:commands].first, options, type)

            if first
              op = 'if'
              first = false
            else
              op = 'elif'
            end
            logic << %(#{op} [[ $last =~ (#{cmd[:commands].join('|')}) ]]; then _doing_#{cmd[:commands].first})
          end
        end

        out << <<~EOFUNC
          _doing()
          {
            local last="${@: -1}"
            local token=${COMP_WORDS[$COMP_CWORD]}

            #{logic.join("\n    ")}
            else
              OLD_IFS="$IFS"
              IFS=$'\n'
              COMPREPLY=( $(compgen -W "$(doing help -c)" -- $token) )
              IFS="$OLD_IFS"
            fi
          }
        EOFUNC
        out.join("\n")
      end

      def command_function(command, options, type)
        long_options = []
        short_options = []

        options.each do |o|
          next if o.nil?

          long_options << o[:long] if o[:long]
          short_options << o[:short] if o[:short]
        end

        long = long_options.map! {|o| "--#{o}"}.join(' ')
        short = short_options.map! {|o| "-#{o}"}.join(' ')
        words = ''
        logic = ''
        words, logic = get_words(type) if type && type.is_a?(String)

        func = <<~ENDFUNC
        _doing_#{command}() {
          #{words}
          if [[ "$token" == --* ]]; then
            COMPREPLY=( $( compgen -W '#{long}' -- $token ) )
          elif [[ "$token" == -* ]]; then
            COMPREPLY=( $( compgen -W '#{short} #{long}' -- $token ) )
          #{logic}
          fi
        }
        ENDFUNC

        func
      end

      def get_words(type)
        func = <<~EOFUNC
          OLD_IFS="$IFS"
          local token=${COMP_WORDS[$COMP_CWORD]}
          IFS=$'\t'
          local words=$(doing #{type})
          IFS="$OLD_IFS"
        EOFUNC

        logic = <<~EOLOGIC
          else
            local nocasematchWasOff=0
            shopt nocasematch >/dev/null || nocasematchWasOff=1
            (( nocasematchWasOff )) && shopt -s nocasematch
            local w matches=()
            OLD_IFS="$IFS"
            IFS=$'\t'‰
            for w in $words; do
              if [[ "$w" == "$token"* ]]; then
                matches+=("${w// /\ }")
              fi
            done
            IFS="$OLD_IFS"
            (( nocasematchWasOff )) && shopt -u nocasematch
            COMPREPLY=("${matches[@]}")
        EOLOGIC

        [func, logic]
      end



      def get_help_sections(command = '')
        res = `doing help #{command}`.strip
        scanned = res.scan(/(?m-i)^([A-Z ]+)\n([\s\S]*?)(?=\n+[A-Z]+|\Z)/)
        sections = {}
        scanned.each do |sect|
          title = sect[0].downcase.strip.gsub(/ +/, '_').to_sym
          content = sect[1].split(/\n/).map(&:strip).delete_if(&:empty?)
          sections[title] = content
        end
        sections
      end

      def parse_option(option)
        res = option.match(/(?:-(?<short>\w), )?(?:--(?:\[no-\])?(?<long>[\w_]+)(?:=(?<arg>\w+))?)\s+- (?<desc>.*?)$/)
        return nil unless res
        {
          short: res['short'],
          long: res['long'],
          arg: res[:arg],
          description: res['desc'].short_desc
        }
      end

      def parse_options(options)
        options.map { |opt| parse_option(opt) }
      end

      def parse_command(command)
        res = command.match(/^(?<cmd>[^, \t]+)(?<alias>(?:, [^, \t]+)*)?\s+- (?<desc>.*?)$/)
        commands = [res['cmd']]
        commands.concat(res['alias'].split(/, /).delete_if(&:empty?)) if res['alias']

        {
          commands: commands,
          description: res['desc'].short_desc
        }
      end

      def parse_commands(commands)
        commands.map { |cmd| parse_command(cmd) }
      end

      def initialize
        data = get_help_sections
        @global_options = parse_options(data[:global_options])
        @commands = parse_commands(data[:commands])
        @bar = TTY::ProgressBar.new("\033[0;0;33mGenerating Bash completions: \033[0;35;40m[:bar]\033[0m", total: @commands.count, bar_format: :blade)
        @bar.resize(25)
      end

      def generate_completions
        @bar.start
        out = []
        out << main_function
        out << 'complete -F _doing doing'
        @bar.finish
        out.join("\n")
      end
    end
  end
end
