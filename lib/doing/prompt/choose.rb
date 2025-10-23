# frozen_string_literal: true

module Doing
  # Methods for creating interactive menus of options and items
  module PromptChoose
    ##
    ## Generate a menu of options and allow user selection
    ##
    ## @return     [String] The selected option
    ##
    ## @param      options   [Array] The options from which to choose
    ## @param      prompt    [String] The prompt
    ## @param      multiple  [Boolean] If true, allow multiple selections
    ## @param      sorted    [Boolean] If true, sort selections alphanumerically
    ## @param      fzf_args  [Array] Additional fzf arguments
    ##
    def choose_from(options, prompt: 'Make a selection: ', multiple: false, sorted: true, fzf_args: [])
      return nil unless $stdout.isatty

      # fzf_args << '-1' # User is expecting a menu, and even if only one it serves as confirmation
      default_args = []
      default_args << %(--prompt="#{prompt}")
      default_args << "--height=#{options.count + 2}"
      default_args << '--info=inline'
      default_args << '--multi' if multiple
      header = "esc: cancel,#{multiple ? ' tab: multi-select, ctrl-a: select all,' : ''} return: confirm"
      default_args << %(--header="#{header}")
      default_args.concat(fzf_args)
      options.sort! if sorted

      res = `echo #{Shellwords.escape(options.join("\n"))}|#{fzf} #{default_args.join(' ')}`
      return false if res.strip.empty?

      res
    end

    ##
    ## Create an interactive menu to select from a set of Items
    ##
    ## @param      items            [Array] list of items
    ## @param      opt              Additional options
    ##
    ## @option opt [Boolean] :include_section Include section name for each item in menu
    ## @option opt [String] :header A custom header string
    ## @option opt [String] :prompt A custom prompt string
    ## @option opt [String] :query Initial query
    ## @option opt [Boolean] :show_if_single Show menu even if there's only one option
    ## @option opt [Boolean] :menu Show menu
    ## @option opt [Boolean] :sort Sort options
    ## @option opt [Boolean] :multiple Allow multiple selections
    ## @option opt [Symbol] :case (:sensitive, :ignore, :smart)
    ##
    def choose_from_items(items, **opt)
      return items unless $stdout.isatty

      return nil unless items.count.positive?

      case_sensitive = opt.fetch(:case, :smart).normalize_case
      header = opt.fetch(:header, 'Arrows: navigate, tab: mark for selection, ctrl-a: select all, enter: commit')
      prompt = opt.fetch(:prompt, 'Select entries to act on > ')
      query = opt.fetch(:query) { opt.fetch(:search, '') }
      include_section = opt.fetch(:include_section, false)

      pad = items.length.to_s.length
      options = items.map.with_index do |item, i|
        out = [
          format("%#{pad}d", i),
          ') ',
          format('%16s', item.date.strftime('%Y-%m-%d %H:%M')),
          ' | ',
          item.title
        ]
        if include_section
          out.concat([
                       ' (',
                       item.section,
                       ') '
                     ])
        end
        out.join('')
      end

      fzf_args = [
        %(--header="#{header}"),
        %(--prompt="#{prompt.sub(/ *$/, ' ')}"),
        opt.fetch(:multiple) ? '--multi' : '--no-multi',
        '-0',
        '--bind ctrl-a:select-all',
        %(-q "#{query}"),
        '--info=inline'
      ]
      fzf_args.push('-1') unless opt.fetch(:show_if_single, false)
      fzf_args << case case_sensitive
                  when :sensitive
                    '+i'
                  when :ignore
                    '-i'
                  end
      fzf_args << '-e' if opt.fetch(:exact, false)

      unless opt.fetch(:menu)
        raise InvalidArgument, "Can't skip menu when no query is provided" unless query && !query.empty?

        fzf_args.concat([%(--filter="#{query}"), opt.fetch(:sort) ? '' : '--no-sort'])
      end
      res = `echo #{Shellwords.escape(options.join("\n"))}|#{fzf} #{fzf_args.join(' ')}`

      selected = []
      res.split(/\n/).each do |item|
        idx = item.match(/^ *(\d+)\)/)[1].to_i
        selected.push(items[idx])
      end

      opt.fetch(:multiple) ? selected : selected[0]
    end
  end
end
