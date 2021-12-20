module Doing
  module Completion
    class FishCompletions

      attr_accessor :commands, :global_options

      def generate_helpers
        <<~EOFUNCTIONS
          function __fish_doing_needs_command
            # Figure out if the current invocation already has a command.

            set -l opts color h-help config_file= f-doing_file= n-notes v-version stdout debug default x-noauto no p-pager q-quiet yes
            set cmd (commandline -opc)
            set -e cmd[1]
            argparse -s $opts -- $cmd 2>/dev/null
            or return 0
            # These flags function as commands, effectively.
            if set -q argv[1]
              # Also print the command, so this can be used to figure out what it is.
              echo $argv[1]
              return 1
            end
            return 0
          end

          function __fish_doing_using_command
            set -l cmd (__fish_doing_needs_command)
            test -z "$cmd"
            and return 1
            contains -- $cmd $argv
            and return 0
          end

          function __fish_doing_complete_sections
            doing sections -c
          end

          function __fish_doing_complete_views
            doing views -c
          end

          function __fish_doing_subcommands
            doing help -c
          end

          function __fish_doing_export_plugins
            doing plugins --type export -c
          end

          function __fish_doing_import_plugins
            doing plugins --type import -c
          end

          function __fish_doing_complete_templates
            doing template -c
          end

          complete -c doing -f
          complete -xc doing -n '__fish_doing_needs_command' -a '(__fish_doing_subcommands)'

          complete -f -c doing -n '__fish_doing_using_command show' -a '(__fish_doing_complete_sections)'
          complete -f -c doing -n '__fish_doing_using_command view' -a '(__fish_doing_complete_views)'
          complete -f -c doing -n '__fish_doing_using_command template' -a '(__fish_doing_complete_templates)'
          complete -f -c doing -s t -l type -x -n '__fish_doing_using_command import' -a '(__fish_doing_import_plugins)'

          complete -xc doing -n '__fish_seen_subcommand_from help; and not __fish_seen_subcommand_from (doing help -c)' -a "(doing help -c)"
        EOFUNCTIONS
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
        res = option.match(/(?:-(?<short>\w), )?(?:--(?:\[no-\])?(?<long>\w+)(?:=(?<arg>\w+))?)\s+- (?<desc>.*?)$/)
        return nil unless res

        {
          short: res['short'],
          long: res['long'],
          arg: res['arg'],
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
          out << "complete -xc doing -n '__fish_doing_needs_command' -a '#{cmd[:commands].join(' ')}' -d #{Shellwords.escape(cmd[:description])}"
        end

        out.join("\n")
      end

      def generate_subcommand_option_completions

        out = []
        need_export = []
        need_bool = []
        need_case = []
        need_sort = []
        need_tag_sort = []
        need_tag_order = []
        need_age = []
        need_section = []

        @commands.each_with_index do |cmd, i|
          @bar.advance
          data = get_help_sections(cmd[:commands].first)

          if data[:synopsis].join(' ').strip.split(/ /).last =~ /(path|file)/i
            out << "complete -c doing -F -n '__fish_doing_using_command #{cmd[:commands].join(" ")}'"
          end

          if data[:command_options]
            parse_options(data[:command_options]).each do |option|
              next if option.nil?

              arg = option[:arg] ? '-r' : ''
              short = option[:short] ? "-s #{option[:short]}" : ''
              long = option[:long] ? "-l #{option[:long]}" : ''
              out << "complete -c doing #{long} #{short} -f #{arg} -n '__fish_doing_using_command #{cmd[:commands].join(' ')}' -d #{Shellwords.escape(option[:description])}"

              need_export.concat(cmd[:commands]) if option[:long] == 'output'
              need_bool.concat(cmd[:commands]) if option[:long] == 'bool'
              need_case.concat(cmd[:commands]) if option[:long] == 'case'
              need_case.concat(cmd[:commands]) if option[:long] == 'sort'
              need_tag_sort.concat(cmd[:commands]) if option[:long] == 'tag_sort'
              need_tag_order.concat(cmd[:commands]) if option[:long] == 'tag_order'
              need_age.concat(cmd[:commands]) if option[:long] == 'age'
              need_section.concat(cmd[:commands]) if option[:long] == 'section'
            end
          end
        end

        unless need_export.empty?
          out << "complete -f -c doing -s o -l output -x -n '__fish_doing_using_command #{need_export.join(' ')}' -a '(__fish_doing_export_plugins)'"
        end

        unless need_bool.empty?
          out << "complete -f -c doing -s b -l bool -x -n '__fish_doing_using_command #{need_bool.join(' ')}' -a 'and or not pattern'"
        end

        unless need_case.empty?
          out << "complete -f -c doing -l case -x -n '__fish_doing_using_command #{need_case.join(' ')}' -a 'case-sensitive ignore smart'"
        end

        unless need_sort.empty?
          out << "complete -f -c doing -l sort -x -n '__fish_doing_using_command #{need_sort.join(' ')}' -a 'asc desc'"
        end

        unless need_tag_sort.empty?
          out << "complete -f -c doing -l tag_sort -x -n '__fish_doing_using_command #{need_tag_sort.join(' ')}' -a 'name time'"
        end

        unless need_tag_order.empty?
          out << "complete -f -c doing -l tag_order -x -n '__fish_doing_using_command #{need_tag_order.join(' ')}' -a 'asc desc'"
        end

        unless need_age.empty?
          out << "complete -f -c doing -s a -l age -x -n '__fish_doing_using_command #{need_age.join(' ')}' -a 'oldest newest'"
        end

        unless need_section.empty?
          out << "complete -f -c doing -s s -l section -x -n '__fish_doing_using_command #{need_section.join(' ')}' -a '(__fish_doing_complete_sections)'"
        end

        # clear
        out.join("\n")
      end

      def initialize
        data = get_help_sections
        @global_options = parse_options(data[:global_options])
        @commands = parse_commands(data[:commands])
        @bar = TTY::ProgressBar.new("\033[0;0;33mGenerating Fish completions: \033[0;35;40m[:bar]\033[0m", total: @commands.count, bar_format: :blade)
        @bar.resize(25)
      end

      def generate_completions
        @bar.start
        out = []
        out << generate_helpers
        out << generate_subcommand_completions
        out << generate_subcommand_option_completions
        @bar.finish
        out.join("\n")
      end
    end
  end
end
