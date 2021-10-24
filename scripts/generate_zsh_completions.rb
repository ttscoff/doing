#!/usr/bin/env ruby
$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
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
    #compdef doing

    local ret=1 state

    _arguments \\
      ':subcommand:->subcommand' \\
      '*::options:->options' && ret=0

    case $state in
        subcommand)
            local -a subcommands
            subcommands=(
                #{generate_subcommand_completions.join("\n            ")}
            )
            _describe -t subcommands 'doing subcommand' subcommands && ret=0
        ;;
        options)
            case $words[1] in
                #{generate_subcommand_option_completions(indent: '            ').join("\n            ")}
            esac

            _arguments $args && ret=0
        ;;
    esac

    return ret
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
    # processing = []
    @commands.each_with_index do |cmd, i|
      # processing << cmd[:commands].first
      processing = cmd[:commands]
      progress('Processing subcommands', i, @commands.count, processing)
      cmd[:commands].each do |c|
        out << "'#{c}:#{cmd[:description].gsub(/'/,'\\\'')}'"
      end
    end

    out
  end

  def generate_subcommand_option_completions(indent: '        ')

    out = []
    need_export = []
    # processing = []

    @commands.each_with_index do |cmd, i|
      # processing << cmd[:commands].first
      processing = cmd[:commands]
      progress('Processing subcommand options', i, @commands.count, processing)

      data = get_help_sections(cmd[:commands].first)
      option_arr = []

      if data[:command_options]
        parse_options(data[:command_options]).each do |option|
          next if option.nil?

          arg = option[:arg] ? '-r' : ''
          short = option[:short] ? "-s #{option[:short]}" : ''
          long = option[:long] ? "-l #{option[:long]}" : ''
          arg = option[:arg] ? "=" : ''
          option_arr << %({-#{option[:short]},--#{option[:long]}#{arg}}"[#{option[:description].gsub(/'/,'\\\'')}]")
        end
      end

      cmd[:commands].each do |c|
        out << "#{c}) \n#{indent+'    '}args=( #{option_arr.join(' ')} )\n#{indent};;"
      end
    end

    out
  end

  def initialize
    status('Generating Zsh completions', reset: false)
    data = get_help_sections
    @global_options = parse_options(data[:global_options])
    @commands = parse_commands(data[:commands])
  end

  def generate_completions
    generate_helpers
  end
end

puts FishCompletions.new.generate_completions
