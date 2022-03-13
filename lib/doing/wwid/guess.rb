# frozen_string_literal: true

module Doing
  # Section and view guessing methods for WWID class
  class WWID
    ##
    ## Attempt to match a string with an existing section
    ##
    ## @param      frag     [String] The user-provided string
    ## @param      guessed  [Boolean] already guessed and failed
    ##
    def guess_section(frag, guessed: false, suggest: false)
      return 'All' if frag =~ /^all$/i
      frag ||= Doing.setting('current_section')

      return frag.cap_first if @content.section?(frag)

      section = nil
      re = frag.to_rx(distance: 2, case_type: :ignore)
      sections.each do |sect|
        next unless sect =~ /#{re}/i

        logger.debug('Match:', %(Assuming "#{sect}" from "#{frag}"))
        section = sect
        break
      end

      return section if suggest

      unless section || guessed
        alt = guess_view(frag, guessed: true, suggest: true)
        if alt
          meant_view = Prompt.yn("#{boldwhite("Did you mean")} `#{yellow("doing view #{alt}")}#{boldwhite}`?", default_response: 'n')

          raise Errors::WrongCommand.new("run again with #{"doing view #{alt}".boldwhite}", topic: 'Try again:') if meant_view

        end

        res = Prompt.yn("#{boldwhite}Section #{frag.yellow}#{boldwhite} not found, create it", default_response: 'n')

        if res
          @content.add_section(frag.cap_first, log: true)
          write(@doing_file)
          return frag.cap_first
        end

        raise Errors::InvalidSection.new("unknown section #{frag.bold.white}", topic: 'Missing:')
      end
      section ? section.cap_first : guessed
    end

    ##
    ## Attempt to match a string with an existing view
    ##
    ## @param      frag     [String] The user-provided string
    ## @param      guessed  [Boolean] already guessed
    ##
    def guess_view(frag, guessed: false, suggest: false)
      views.each { |view| return view if frag.downcase == view.downcase }
      view = false
      re = frag.to_rx(distance: 2, case_type: :ignore)
      views.each do |v|
        next unless v =~ /#{re}/i

        logger.debug('Match:', %(Assuming "#{v}" from "#{frag}"))
        view = v
        break
      end
      unless view || guessed
        alt = guess_section(frag, guessed: true, suggest: true)

        raise Errors::InvalidView.new(%(unknown view #{frag.bold.white}), topic: 'Missing:') unless alt

        meant_view = Prompt.yn("Did you mean `doing show #{alt}`?", default_response: 'n')

        raise Errors::WrongCommand.new("run again with #{"doing show #{alt}".yellow}", topic: 'Try again:') if meant_view

        raise Errors::InvalidView.new(%(unknown view #{alt.bold.white}), topic: 'Missing:')
      end
      view
    end
  end
end
