# frozen_string_literal: true

require 'tty-progressbar'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'completion'))
require 'string'
require 'fish_completion'
require 'zsh_completion'
require 'bash_completion'

module Doing
  # Completion script generator
  module Completion
    OPTIONS_RX = /(?:-(?<short>\w), )?(?:--(?:\[no-\])?(?<long>\w+)(?:=(?<arg>\w+))?)\s+- (?<desc>.*?)$/.freeze
    SECTIONS_RX = /(?m-i)^([A-Z ]+)\n([\s\S]*?)(?=\n+[A-Z]+|\Z)/.freeze
    COMMAND_RX = /^(?<cmd>[^, \t]+)(?<alias>(?:, [^, \t]+)*)?\s+- (?<desc>.*?)$/.freeze

    class << self
      def get_help_sections(command = '')
        res = `doing help #{command}`.strip
        scanned = res.scan(SECTIONS_RX)
        sections = {}
        scanned.each do |sect|
          title = sect[0].downcase.strip.gsub(/ +/, '_').to_sym
          content = sect[1].split(/\n/).map(&:strip).delete_if(&:empty?)
          sections[title] = content
        end
        sections
      end

      def parse_option(option)
        res = option.match(OPTIONS_RX)
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
        res = command.match(COMMAND_RX)
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

      # Generate a completion script and output to file or
      # stdout
      #
      # @param      type  [String] shell to generate for (zsh|bash|fish)
      # @param      file  [String] Path to save to, or 'stdout'
      #
      def generate_completion(type: 'zsh', file: :default, link: true)
        return generate_all if type =~ /^all$/i

        file = file == :default ? default_file(type) : file
        file = validate_target(file)
        result = generate_type(type)

        if file =~ /^stdout$/i
          $stdout.puts result
        else
          File.open(file, 'w') { |f| f.puts result }
          Doing.logger.warn('File written:', "#{type} completions written to #{file}")

          link_completion_type(type, file) if link
        end
      end

      def link_default(type)
        type = normalize_type(type)
        raise InvalidArgument, 'Unrecognized shell specified' if type == :invalid

        return %i[zsh bash fish].each { |t| link_default(t) } if type == :all

        install_builtin(type)

        link_completion_type(type, File.join(default_dir, default_filenames[type]))
      end

      def install_builtin(type)
        FileUtils.mkdir_p(default_dir)
        src = File.expand_path(File.join(File.dirname(__FILE__), '..', 'completion', default_filenames[type]))

        if File.exist?(File.join(default_dir, default_filenames[type]))
          return unless Doing::Prompt.yn("Update #{type} completion script", default_response: 'n')
        end

        FileUtils.cp(src, default_dir)
        Doing.logger.warn('File written:', "#{type} completions saved to #{default_file(type)}")
      end

      def normalize_type(type)
        case type.to_s
        when /^f/i
          :fish
        when /^b/i
          :bash
        when /^z/i
          :zsh
        when /^a/i
          :all
        else
          :invalid
        end
      end

      private

      def generate_type(type)
        generator = case type.to_s
                    when /^f/i
                      FishCompletions.new
                    when /^b/i
                      BashCompletions.new
                    else
                      ZshCompletions.new
                    end

        generator.generate_completions
      end

      def validate_target(file)
        unless file =~ /stdout/i
          file = validate_file(file)

          validate_dir(file)
        end

        file
      end

      def default_dir
        File.expand_path('~/.local/share/doing/completion')
      end

      def default_filenames
        { zsh: '_doing.zsh', bash: 'doing.bash', fish: 'doing.fish' }
      end

      def default_file(type)
        type = normalize_type(type)

        File.join(default_dir, default_filenames[type])
      end

      def validate_file(file)
        file = File.expand_path(file)
        if File.exist?(file)
          res = Doing::Prompt.yn("Overwrite #{file}", default_response: 'y')
          raise UserCancelled unless res

          FileUtils.rm(file) if res
        end
        file
      end

      def validate_dir(file)
        dir = File.dirname(file)
        unless File.directory?(dir)
          res = Doing::Prompt.yn("#{dir} doesn't exist, create it", default_response: 'y')
          raise UserCancelled unless res

          FileUtils.mkdir_p(dir)
        end
        dir
      end

      def generate_all
        Doing.logger.log_now(:warn, 'Generating:', 'all completion types, will use default paths')
        generate_completion(type: 'fish', file: 'lib/completion/doing.fish', link: false)
        Doing.logger.warn('File written:', 'fish completions written to lib/completion/doing.fish')
        generate_completion(type: 'zsh', file: 'lib/completion/_doing.zsh', link: false)
        Doing.logger.warn('File written:', 'zsh completions written to lib/completion/_doing.zsh')
        generate_completion(type: 'bash', file: 'lib/completion/doing.bash', link: false)
        Doing.logger.warn('File written:', 'bash completions written to lib/completion/doing.bash')
      end

      def link_completion_type(type, file)
        dir = File.dirname(file)
        case type.to_s
        when /^b/i
          unless dir =~ %r{(\.bash_it/completion|bash_completion/completions)}
            link_completion(file, ['~/.bash_it/completion/enabled', '/usr/share/bash_completion/completions'], 'doing.bash')
          end
        when /^f/i
          link_completion(file, ['~/.config/fish/completions'], 'doing.fish') unless dir =~ %r{.config/fish/completions}
        when /^z/i
          unless dir =~ %r{(\.oh-my-zsh/completions|share/site-functions)}
            link_completion(file, ['~/.oh-my-zsh/completions', '/usr/local/share/zsh/site-functions'], '_doing.zsh')
          end
        end
      end

      def link_completion(file, targets, filename)
        return if targets.map { |t| File.expand_path(t) }.include?(File.dirname(file))

        found = false
        linked = false

        targets.each do |target|
          next unless File.directory?(File.expand_path(target))
          found = true

          target_file = File.join(File.expand_path(target), filename)
          next unless Doing::Prompt.yn("Create link to #{target_file}", default_response: 'n')

          FileUtils.ln_s(File.expand_path(file), target_file, force: true)
          Doing.logger.warn('File linked:', "#{File.expand_path(file)} -> #{target_file}")
          linked = true
          break
        end

        return if linked

        unless found
          $stdout.puts 'No known auto-load directory found for specified shell'.red
          $stdout.puts "Looked for #{targets.join(', ')}, found no existing directory".yellow
        end
        $stdout.puts 'If you don\'t want to autoload completions'.yellow
        $stdout.puts 'you can source the script directly in your shell\'s startup file:'.yellow
        $stdout.puts %(source "#{file}").boldwhite
      end
    end
  end
end
