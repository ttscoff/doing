# frozen_string_literal: true

module Doing
  class WWID
    ##
    ## Attempt to match a string with an existing section
    ##
    ## @param      frag     [String] The user-provided string
    ## @param      guessed  [Boolean] already guessed and failed
    ##
    def guess_section(frag, guessed: false, suggest: false)
      if frag.is_a?(Array) && frag.count == 1
        frag = frag[0]
      end

      frag = frag.split(/ *, */).map(&:strip) if frag.is_a?(String) && frag =~ /,/

      return frag.map { |s| guess_section(s, guessed: guessed, suggest: suggest) } if frag.is_a?(Array)

      return 'All' if frag =~ /^all$/i || frag.empty? || frag.nil?

      frag ||= Doing.setting('current_section')

      return frag.cap_first if @content.section?(frag)

      found = @content.guess_section(frag, distance: 2)

      section = found ? found.title : nil

      return section if suggest

      unless section || guessed
        alt = guess_view(frag, guessed: true, suggest: true)
        if alt
          prompt = Color.template("{bw}Did you mean `{xy}doing {by}view {xy}#{alt}`{bw}?{x}")
          meant_view = Prompt.yn(prompt, default_response: 'n')

          msg = format('%<y>srun with `%<w>sdoing view %<alt>s%<y>s`', w: boldwhite, y: yellow, alt: alt)
          raise Errors::WrongCommand.new(msg, topic: 'Try again:') if meant_view

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
      view = nil
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

        prompt = Color.template("{bw}Did you mean `{xy}doing {by}show {xy}#{alt}`{bw}?{x}")
        meant_view = Prompt.yn(prompt, default_response: 'n')

        if meant_view
          msg = format('%<y>srun with `%<w>sdoing show %<alt>s%<y>s`', w: boldwhite, y: yellow, alt: alt)
          raise Errors::WrongCommand.new(msg, topic: 'Try again:')

        end

        raise Errors::InvalidView.new(%(unknown view #{alt.bold.white}), topic: 'Missing:')

      end
      view
    end
  end
end
