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
    class << self
      # Generate a completion script and output to file or
      # stdout
      #
      # @param      type  [String] shell to generate for (zsh|bash|fish)
      # @param      file  [String] Path to save to, or 'stdout'
      #
      def generate_completion(type: 'zsh', file: 'stdout', link: true)
        return generate_all if type =~ /^all$/i

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

        target_dir = File.expand_path('~/.local/share/doing/completion')
        FileUtils.mkdir_p(target_dir)
        files = { zsh: '_doing.zsh', bash: 'doing.bash', fish: 'doing.fish' }
        src = File.expand_path(File.join(File.dirname(__FILE__), '..', 'completion', files[type]))
        FileUtils.cp(src, target_dir)
        link_completion_type(type, File.join(target_dir, files[type]))
      end

      private

      def normalize_type(type)
        case type
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

        linked = false

        targets.each do |target|
          next unless File.directory?(File.expand_path(target))

          target_file = File.join(File.expand_path(target), filename)
          next unless Doing::Prompt.yn("Create link to #{target_file}", default_response: 'n')

          FileUtils.ln_s(File.expand_path(file), target_file, force: true)
          Doing.logger.warn('File linked:', "#{File.expand_path(file)} -> #{target_file}")
          linked = true
          break
        end

        return if linked

        $stdout.puts 'No known auto-load directory found for specified shell'.red
        $stdout.puts "Looked for #{targets.join(', ')}, found no existing directory".yellow
        $stdout.puts 'If you don\'t want to autoload completions'.yellow
        $stdout.puts 'you can source the script directly in your shell\'s startup file:'.yellow
        $stdout.puts %(source "#{file}").boldwhite
      end
    end
  end
end
