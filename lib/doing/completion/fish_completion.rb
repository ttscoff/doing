# frozen_string_literal: true

module Doing
  module Completion
    # Generate completions for Fish
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

          function __fish_doing_cache_timer_expired
            set -l timer __fish_doing_cache_timer_$argv[1]
            if not set -q $timer
              set -g $timer (date '+%s')
            end

            if test (math (date '+%s') - $$timer) -gt $argv[2]
              set -g $timer (date '+%s')
              return 1
            end

            return 0
          end

          function __fish_doing_subcommands
            if not set -q __fish_doing_subcommands_cache
              or __fish_doing_cache_timer_expired subcommands 86400
              set -g -a __fish_doing_subcommands_cache (doing help -c)
            end
            printf '%s\n' $__fish_doing_subcommands_cache
          end

          function __fish_doing_complete_sections
            if not set -q __fish_doing_sections_cache
              or __fish_doing_cache_timer_expired sections 3600
              set -g -a __fish_doing_sections_cache (doing sections -c)
            end
            printf '%s\n' $__fish_doing_sections_cache
            __fish_doing_complete_show_tag
          end

          function __fish_doing_complete_views
            if not set -q __fish_doing_views_cache
              or __fish_doing_cache_timer_expired views 3600
              set -g -a __fish_doing_views_cache (doing views -c)
            end
            printf '%s\n' $__fish_doing_views_cache
          end

          function __fish_doing_export_plugin
            if not set -q __fish_doing_export_plugin_cache
              or __fish_doing_cache_timer_expired export_plugins 3600
              set -g -a __fish_doing_export_plugin_cache (doing plugins --type export -c)
            end
            printf '%s\n' $__fish_doing_export_plugin_cache
          end

          function __fish_doing_import_plugin
            if not set -q __fish_doing_import_plugin_cache
              or __fish_doing_cache_timer_expired import_plugins 3600
              set -g -a __fish_doing_import_plugin_cache (doing plugins --type import -c)
            end
            printf '%s\n' $__fish_doing_import_plugin_cache
          end

          function __fish_doing_complete_template
            if not set -q __fish_doing_template_cache
              or __fish_doing_cache_timer_expired template 3600
              set -g -a __fish_doing_template_cache (doing template -c)
            end
            printf '%s\n' $__fish_doing_template_cache
          end

          function __fish_doing_complete_tag
            if not set -q __fish_doing_tag_cache
              or __fish_doing_cache_timer_expired tags 60
              set -g -a __fish_doing_tag_cache (doing tags)
            end
            printf '%s\n' $__fish_doing_tag_cache
          end

          function __fish_doing_complete_show_tag
            if not set -q __fish_doing_tag_cache
              or __fish_doing_cache_timer_expired tags 60
              set -g -a __fish_doing_tag_cache (doing tags)
            end
            printf '@%s\n' $__fish_doing_tag_cache
          end

          function __fish_doing_complete_args
            for cmd in (doing commands_accepting -c $argv[1])
              complete -x -c doing -l $argv[1] -n "__fish_doing_using_command $cmd" -a "(__fish_doing_complete_$argv[1])"
            end
          end

          complete -c doing -f
          complete -xc doing -n '__fish_doing_needs_command' -a '(__fish_doing_subcommands)'

          complete -f -c doing -n '__fish_doing_using_command show' -a '(__fish_doing_complete_sections)'
          complete -f -c doing -n '__fish_doing_using_command view' -a '(__fish_doing_complete_views)'
          complete -f -c doing -n '__fish_doing_using_command template' -a '(__fish_doing_complete_templates)'
          complete -f -c doing -s t -l type -x -n '__fish_doing_using_command import' -a '(__fish_doing_import_plugins)'
          complete -f -c doing -n '__fish_doing_using_command help' -a '(__fish_doing_subcommands)'

          # complete -xc doing -n '__fish_seen_subcommand_from help; and not __fish_seen_subcommand_from (doing help -c)' -a "(doing help -c)"

          function __fish_doing_complete_args
            for cmd in (doing commands_accepting -c $argv[1])
              complete -x -c doing -l $argv[1] -n "__fish_doing_using_command $cmd" -a "(__fish_doing_complete_$argv[1])"
            end
          end

          __fish_doing_complete_args tag
        EOFUNCTIONS
      end

      def generate_subcommand_completions
        out = []
        @commands.each do |cmd|
          desc = Shellwords.escape(cmd[:description])
          cmds = cmd[:commands].join(' ')
          out << "complete -xc doing -n '__fish_doing_needs_command' -a '#{cmds}' -d #{desc}"
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
          @bar.advance(status: cmd[:commands].first)
          data = Completion.get_help_sections(cmd[:commands].first)

          if data[:synopsis].join(' ').strip.split(/ /).last =~ /(path|file)/i
            out << "complete -c doing -F -n '__fish_doing_using_command #{cmd[:commands].join(" ")}'"
          end

          if data[:command_options]
            Completion.parse_options(data[:command_options]).each do |option|
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
          out << "complete -f -c doing -s o -l output -x -n '__fish_doing_using_command #{need_export.join(' ')}' -a '(__fish_doing_export_plugin)'"
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
        data = Completion.get_help_sections
        @global_options = Completion.parse_options(data[:global_options])
        @commands = Completion.parse_commands(data[:commands])
        @bar = TTY::ProgressBar.new("\033[0;0;33mGenerating Fish completions: \033[0;35;40m[:bar] :status\033[0m", total: @commands.count + 1, bar_format: :block, hide_cursor: true, status: 'processing subcommands')
        width = TTY::Screen.columns - 45
        @bar.resize(width)
      end

      def generate_completions
        @bar.start
        out = []
        out << generate_helpers
        out << generate_subcommand_completions
        out << generate_subcommand_option_completions
        @bar.advance(status: '✅')
        @bar.finish
        out.join("\n")
      end
    end
  end
end
