# frozen_string_literal: true

module Doing
  module Completion
    class ::String
      def sanitize
        gsub(/"/, '\"')
      end
    end

    # Generate completions for zsh
    class FigCompletions
      attr_accessor :commands, :global_options

      def generate_helpers
        out=<<~EOFUNCTIONS
        const completionSpec: Fig.Spec = {
          name: "doing",
          description: "A CLI for a What Was I Doing system",
          subcommands: [
            #{generate_subcommand_completions.join("\n    ")}
          ],
        };
        export default completionSpec;
        EOFUNCTIONS
        @bar.advance(status: '✅')
        @bar.finish
        out
      end

      def generate_subcommand_completions
        out = []
        indent = '      '
        @commands.each do |cmd|
          cmd[:commands].each do |c|
            out << <<~EOCOMMAND
              {
              #{indent}name: "#{c}",
              #{indent}description: "#{cmd[:description].sanitize}",
              #{indent}#{generate_subcommand_option_completions(cmd)}
                  },
            EOCOMMAND
          end
        end

        out
      end

      def generate_subcommand_option_completions(cmd, indent: '          ')
        out = []

        @bar.advance(status: cmd[:commands].first)

        data = Completion.get_help_sections(cmd[:commands].first)

        option_arr = []

        if data[:command_options]
          Completion.parse_options(data[:command_options]).each do |option|
            next if option.nil?

            arg = ''

            if option[:arg]
              arg =<<~EOARG
              args: {
              #{indent}        name: "#{option[:arg]}",
              #{indent}        description: "#{option[:arg]}",
              #{indent}  },
              EOARG
            end

            if option[:short]
              opt_data =<<~EOOPT
              {
              #{indent}  name: ["-#{option[:short]}", "--#{option[:long]}"],
              #{indent}  description: "#{option[:description].sanitize}",
              #{indent}  #{arg}
              #{indent}},
              EOOPT
            else
              opt_data = <<~EOOPT
              {
              #{indent}  name: ["--#{option[:long]}"],
              #{indent}  description: "#{option[:description].sanitize}",
              #{indent}  #{arg}
              #{indent}},
              EOOPT
            end

            option_arr << opt_data

          end

          cmd_opts = <<~EOCMD
            options: [
            #{indent}#{option_arr.join("\n#{indent}")}
                    ],
          EOCMD
          out << cmd_opts
        end

        out.join("\n")
      end

      def initialize
        data = Completion.get_help_sections
        @global_options = Completion.parse_options(data[:global_options])
        @commands = Completion.parse_commands(data[:commands])
        @bar = TTY::ProgressBar.new(" \033[0;0;33mGenerating Fig completions: \033[0;35;40m[:bar] :status\033[0m", total: @commands.count + 1, bar_format: :square, hide_cursor: true, status: 'processing subcommands')
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
