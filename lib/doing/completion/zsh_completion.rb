# frozen_string_literal: true

module Doing
  module Completion
    class ::String
      def sanitize
        gsub(/'/, '\\\'').gsub(/\[/, '(').gsub(/\]/, ')')
      end
    end

    # Generate completions for zsh
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
        @bar.advance(status: '✅')
        @bar.finish
        out
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
          @bar.advance(status: cmd[:commands].first)

          data = Completion.get_help_sections(cmd[:commands].first)
          option_arr = []

          if data[:command_options]
            Completion.parse_options(data[:command_options]).each do |option|
              next if option.nil?

              arg = option[:arg] ? ":#{option[:arg]}:" : ''

              option_arr << if option[:short]
                              %({'(--#{option[:long]})-#{option[:short]}','(-#{option[:short]})--#{option[:long]}'}"[#{option[:description].sanitize}]#{arg}")
                            else
                              %("--#{option[:long]}[#{option[:description].sanitize}]#{arg}")
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
        data = Completion.get_help_sections
        @global_options = Completion.parse_options(data[:global_options])
        @commands = Completion.parse_commands(data[:commands])
        @bar = TTY::ProgressBar.new(" \033[0;0;33mGenerating Zsh completions: \033[0;35;40m[:bar] :status\033[0m", total: @commands.count + 1, bar_format: :square, hide_cursor: true, status: 'processing subcommands')
        width = TTY::Screen.columns - 45
        @bar.resize(width)
      end

      def generate_completions
        @bar.start
        generate_helpers
      end
    end
  end
end
