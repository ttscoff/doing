# frozen_string_literal: true

module Doing
  # Methods for requesting user text input
  module PromptInput
    ##
    ## Request single-line input
    ##
    ## @param      prompt            [String] The prompt
    ## @param      default_response  [String] The default
    ##                               response returned if
    ##                               :default_answer is
    ##                               true
    ##
    ## @return     [String] The user response
    ##
    ## @deprecated Use {#read_line} instead
    ##
    def enter_text(prompt, default_response: '')
      $stdin.reopen('/dev/tty')
      return default_response if @default_answer

      print "#{Color.yellow(prompt).sub(/:?$/, ':')} #{Color.reset}"
      $stdin.gets.strip
    end

    ##
    ## Request single-line input using Readline. Allows
    ## for control sequences and tab completions
    ##
    ## @param      prompt            [String] The prompt
    ## @param      completions       [Array] Array of tab
    ##                               completions
    ## @param      default_response  [String] The default
    ##                               response returned if
    ##                               :default_answer is
    ##                               true
    ##
    ## @return     [String] User input string
    ##
    def read_line(prompt: 'Enter text', completions: [], default_response: '')
      $stdin.reopen('/dev/tty')
      return default_response if @default_answer

      unless completions.empty?
        completions.sort!
        comp = proc { |s| completions.grep(/^#{Regexp.escape(s)}/) }
        Readline.completion_append_character = ' '
        Readline.completion_proc = comp
      end

      begin
        Readline.readline("#{Color.yellow(prompt).sub(/:?$/, ':')} #{Color.reset}", true).strip
      rescue Interrupt
        raise UserCancelled
      end
    end

    ##
    ## Request multi-line input using Readline. Allows for
    ## control sequences and tab completion
    ##
    ## @param      prompt            [String] The prompt
    ## @param      completions       [Array] Array of tab
    ##                               completions
    ## @param      default_response  [String] The default
    ##                               response returned if
    ##                               :default_answer is
    ##                               true
    ##
    ## @return     [String] Multi-line result, joined with newlines
    ##
    def read_lines(prompt: 'Enter text', completions: [], default_response: '')
      $stdin.reopen('/dev/tty')
      return default_response if @default_answer

      completions.sort!
      comp = proc { |s| completions.grep(/^#{Regexp.escape(s)}/) }
      Readline.completion_append_character = ' '
      Readline.completion_proc = comp
      puts format(['%<promptcolor>s%<prompt>s %<textcolor>sEnter a blank line',
                   '(%<keycolor>sreturn twice%<textcolor>s)',
                   'to end editing and save,',
                   '%<keycolor>sCTRL-C%<textcolor>s to cancel%<reset>s'].join(' '),
                  { promptcolor: Color.boldgreen, prompt: prompt.sub(/:?$/, ':'),
                    textcolor: Color.yellow, keycolor: Color.boldwhite, reset: Color.reset })

      res = []

      begin
        while (line = Readline.readline('> ', true))
          break if line.strip.empty?

          res << line.chomp
        end
      rescue Interrupt
        return nil
      end

      res.join("\n").strip
    end

    ##
    ## Request multi-line input
    ##
    ## @param      prompt            [String] The prompt
    ## @param      default_response  [String] The default
    ##                               response, returned if
    ##                               :default_answer is
    ##                               true
    ##
    ## @deprecated Use {#read_lines} instead
    def request_lines(prompt: 'Enter text', default_response: '')
      $stdin.reopen('/dev/tty')
      return default_response if @default_answer

      ask_note = []
      reader = TTY::Reader.new(interrupt: -> { raise Errors::UserCancelled }, track_history: false)
      puts "#{Color.boldgreen(prompt.sub(/:?$/,
                                         ':'))} #{Color.yellow('Hit return for a new line, ')}#{Color.boldwhite('enter a blank line (')}#{Color.boldyellow('return twice')}#{Color.boldwhite(') to end editing')}"
      loop do
        res = reader.read_line(Color.green('> '))
        break if res.strip.empty?

        ask_note.push(res)
      end
      ask_note.join("\n").strip
    end
  end
end
