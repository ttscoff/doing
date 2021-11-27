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

        generator = case type.to_s
                    when /^f/
                      FishCompletions.new
                    when /^b/
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
