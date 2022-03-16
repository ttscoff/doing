# frozen_string_literal: true

module Doing
  # STDOUT and STDERR methods
  module PromptSTD
    ##
    ## Clear the terminal screen
    ##
    def clear_screen(msg = nil)
      puts "\e[H\e[2J" if $stdout.tty?
      puts msg if msg.good?
    end

    ##
    ## Redirect STDOUT and STDERR to /dev/null or file
    ##
    ## @param      file  [String] a file path to redirect to
    ##
    def silence_std(file = '/dev/null')
      $stdout = File.new(file, 'w')
      $stderr = File.new(file, 'w')
    end

    ##
    ## Restore silenced STDOUT and STDERR
    ##
    def restore_std
      $stdout = STDOUT
      $stderr = STDERR
    end
  end
end
