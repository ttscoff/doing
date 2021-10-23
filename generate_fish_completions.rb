#!/usr/bin/env ruby
$LOAD_PATH.unshift File.join(__dir__, 'lib')
require 'doing/cli_status'

require 'shellwords'

class ::String
  def short_desc
    split(/[,.]/)[0].sub(/ \(.*?\)?$/, '').strip
  end

  def ltrunc(max)
    if length > max
      sub(/^.*?(.{#{max - 3}})$/, '...\1')
    else
      self
    end
  end

  def ltrunc!(max)
    replace ltrunc(max)
  end
end

class FishCompletions
  include Status

  attr_accessor :commands, :global_options

  def generate_helpers
    <<~EOFUNCTIONS
      function __fish_doing_needs_command
        # Figure out if the current invocation already has a command.

        set -l opts h-help config_file= f-doing_file= n-notes v-version stdout d-debug default x-noauto
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

    EOFUNCTIONS
  end

  def get_help_sections(command = '')
    res = `bundle exec bin/doing help #{command}`.strip
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

  def generate_subcommand_completions
    out = []
    processing = []
    @commands.each_with_index do |cmd, i|
      processing << cmd[:commands].first
      progress('Processing subcommands', i, @commands.count, processing)
      out << "complete -xc doing -n '__fish_doing_needs_command' -a '#{cmd[:commands].join(' ')}' -d #{Shellwords.escape(cmd[:description])}"
    end

    out.join("\n")
  end

  def generate_subcommand_option_completions

    out = []
    need_export = []
    processing = []

    @commands.each_with_index do |cmd, i|
      processing << cmd[:commands].first
      progress('Processing subcommand options', i, @commands.count, processing)

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
        end
      end
    end

    unless need_export.empty?
      out << "complete -f -c doing -s o -l output -x -n '__fish_doing_using_command #{need_export.join(' ')}' -a '(__fish_doing_export_plugins)'"
    end

    out.join("\n")
  end

  def initialize
    data = get_help_sections()
    @global_options = parse_options(data[:global_options])
    @commands = parse_commands(data[:commands])
  end

  def generate_completions
    out = []
    out << generate_helpers
    out << generate_subcommand_completions
    out << generate_subcommand_option_completions
    out.join("\n")
  end
end

puts FishCompletions.new.generate_completions
