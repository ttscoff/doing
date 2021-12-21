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
      def generate_completion(type: 'zsh', file: 'stdout')
        if type =~ /^all$/i
          Doing.logger.log_now(:warn, 'Generating:', 'all completion types, will use default paths')
          generate_completion(type: 'fish', file: 'lib/completion/doing.fish')
          Doing.logger.warn('File written:', "fish completions written to lib/completion/doing.fish")
          generate_completion(type: 'zsh', file: 'lib/completion/_doing.zsh')
          Doing.logger.warn('File written:', "zsh completions written to lib/completion/_doing.zsh")
          generate_completion(type: 'bash', file: 'lib/completion/doing.bash')
          Doing.logger.warn('File written:', "bash completions written to lib/completion/doing.bash")
          return
        end

        generator = case type.to_s
                    when /^f/i
                      FishCompletions.new
                    when /^b/i
                      BashCompletions.new
                    else
                      ZshCompletions.new
                    end

        result = generator.generate_completions

        if file =~ /^stdout$/i
          $stdout.puts result
        else
          File.open(File.expand_path(file), 'w') do |f|
            f.puts result
          end
          Doing.logger.warn('File written:', "#{type} completions written to #{file}")
        end
      end
    end
  end
end
