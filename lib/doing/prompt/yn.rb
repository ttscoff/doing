# frozen_string_literal: true

module Doing
  # Request Yes/No answers on command line
  module PromptYN
    ##
    ## Ask a yes or no question in the terminal
    ##
    ## @param      question          [String] The question
    ##                               to ask
    ## @param      default_response  [Boolean]   default
    ##                               response if no input
    ##
    ## @return     [Boolean] yes or no
    ##
    def yn(question, default_response: false)
      return @force_answer == :yes ? true : false unless @force_answer.nil?

      $stdin.reopen('/dev/tty')

      default = if default_response.is_a?(String)
                  default_response =~ /y/i ? true : false
                else
                  default_response
                end

      # if global --default is set, answer default
      return default if @default_answer

      # if this isn't an interactive shell, answer default
      return default unless $stdout.isatty

      # clear the buffer
      if ARGV&.length
        ARGV.length.times do
          ARGV.shift
        end
      end
      system 'stty cbreak'

      cw = white
      cbw = boldwhite
      cbg = boldgreen
      cd = Color.default

      options = unless default.nil?
                  "#{cw}[#{default ? "#{cbg}Y#{cw}/#{cbw}n" : "#{cbw}y#{cw}/#{cbg}N"}#{cw}]#{cd}"
                else
                  "#{cw}[#{cbw}y#{cw}/#{cbw}n#{cw}]#{cd}"
                end
      $stdout.syswrite "#{cbw}#{question.sub(/\?$/, '')} #{options}#{cbw}?#{cd} "
      res = $stdin.sysread 1
      puts
      system 'stty cooked'

      res.chomp!
      res.downcase!

      return default if res.empty?

      res =~ /y/i ? true : false
    end
  end
end
