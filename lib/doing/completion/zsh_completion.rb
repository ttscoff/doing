module Doing
  module Completion
    class ZshCompletions

      attr_accessor :commands, :global_options

      def generate_helpers
        out=<<~EOFUNCTIONS
          compdef _doing doing

          function _doing() {
              local line state

              function _commands {
                  local -a commands

                  commands=(
                            #{generate_subcommand_completions.join("\n                  ")}
                  )
                  _describe 'command' commands
              }

              _arguments -C \
                      "1: :_commands" \
                      "*::arg:->args"



              case $line[1] in
                  #{generate_subcommand_option_completions(indent: '            ').join("\n            ")}
              esac

              _arguments -s $args
          }

        EOFUNCTIONS
        @bar.finish
        out
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
        res = option.match(/(?:-(?<short>\w), )?(?:--(?:\[no-\])?(?<long>w+)(?:=(?<arg>\w+))?)\s+- (?<desc>.*?)$/)
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

      def generate_subcommand_completions
        out = []
        @commands.each_with_index do |cmd, i|
          cmd[:commands].each do |c|
            out << "'#{c}:#{cmd[:description].gsub(/'/, '\\\'')}'"
          end
        end
        out
      end

      def generate_subcommand_option_completions(indent: '        ')

        out = []

        @commands.each_with_index do |cmd, i|
          @bar.advance

          data = get_help_sections(cmd[:commands].first)
          option_arr = []

          if data[:command_options]
            parse_options(data[:command_options]).each do |option|
              next if option.nil?

              arg = option[:arg] ? '=' : ''

              option_arr << if option[:short]
                              %({-#{option[:short]},--#{option[:long]}#{arg}}"[#{option[:description].gsub(/'/, '\\\'')}]")
                            else
                              %("(--#{option[:long]}#{arg})--#{option[:long]}#{arg}}[#{option[:description].gsub(/'/, '\\\'')}]")
                            end
            end
          end

          cmd[:commands].each do |c|
            out << "#{c}) \n#{indent}    args=( #{option_arr.join(' ')} )\n#{indent};;"
          end
        end

        out
      end

      def initialize
        data = get_help_sections
        @global_options = parse_options(data[:global_options])
        @commands = parse_commands(data[:commands])
        @bar = TTY::ProgressBar.new(" \033[0;0;33mGenerating Zsh completions: \033[0;35;40m[:bar]\033[0m", total: @commands.count, bar_format: :blade)
        @bar.resize(25)
      end

      def generate_completions
        @bar.start
        generate_helpers
      end
    end
  end
end
