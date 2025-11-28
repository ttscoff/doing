# frozen_string_literal: true

module Doing
  class WWID
    ##
    ## Display an interactive menu of entries
    ##
    ## @param      opt   [Hash] Additional options
    ##
    ## Options hash is shared with #filter_items and #act_on
    ##
    def interactive(opt)
      opt ||= {}
      opt[:section] = opt[:section] ? guess_section(opt[:section]) : 'All'

      search = nil

      if opt[:search]
        search = opt[:search]
        search.sub!(/^'?/, "'") if opt[:exact]
        opt[:search] = search
      end

      # opt[:query] = opt[:search] if opt[:search] && !opt[:query]
      opt[:query] = "!#{opt[:query]}" if opt[:query] && opt[:not]
      opt[:multiple] = true
      opt[:show_if_single] = true
      filter_options = %i[after before case date_filter from fuzzy not search section val].each_with_object({}) do
        |k, hsh| hsh[k] = opt[k]
      end
      items = filter_items(Items.new, opt: filter_options)

      menu_options = %i[search query exact multiple show_if_single menu sort case].each_with_object({}) do |k, hsh|
        hsh[k] = opt[k]
      end
      include_section = (opt[:section].is_a?(Array) && opt[:section][0] =~ /^all$/i) || (opt[:section].is_a?(String) && opt[:section] =~ /^all$/i)

      selection = Prompt.choose_from_items(items, include_section: include_section, **menu_options)

      raise NoResults, 'no items selected' if selection.nil? || selection.empty?

      act_on(selection, opt)
    end

    ##
    ## Perform actions on a set of entries. If
    ##             no valid action is included in the opt
    ##             hash and the terminal is a TTY, a menu
    ##             will be presented
    ##
    ## @param      items  [Array] Array of Items to affect
    ## @param      opt    [Hash] Options and actions to perform
    ##
    ## @option opt [Boolean] :editor
    ## @option opt [Boolean] :delete
    ## @option opt [String] :tag
    ## @option opt [Boolean] :flag
    ## @option opt [Boolean] :finish
    ## @option opt [Boolean] :cancel
    ## @option opt [Boolean] :archive
    ## @option opt [String] :output
    ## @option opt [String] :save_to
    ## @option opt [Boolean] :again
    ## @option opt [Boolean] :resume
    ##
    def act_on(items, opt)
      opt ||= {}
      actions = %i[editor delete tag flag finish cancel archive output save_to again resume]
      has_action = false
      single = items.count == 1

      actions.each do |a|
        if opt[a]
          has_action = true
          break
        end
      end

      unless has_action
        actions = [
          'add tag',
          'remove tag',
          'autotag',
          'cancel',
          'delete',
          'finish',
          'flag',
          'archive',
          'move',
          'edit',
          'output formatted'
        ]

        actions.concat(['resume/repeat', 'begin/reset']) if items.count == 1

        choice = Prompt.choose_from(actions.map(&:titlecase),
                                    prompt: 'What do you want to do with the selected items? > ',
                                    multiple: true,
                                    sorted: false,
                                    fzf_args: ["--height=#{actions.count + 3}", '--tac', '--no-sort', '--info=hidden'])
        return unless choice

        to_do = choice.strip.split(/\n/).map(&:downcase)

        to_do.each do |action|
          action = 'resume' if action =~ /^resume/i
          action = 'reset' if action =~ /^begin/i

          case action
          when /(resume|reset|autotag|archive|delete|finish|cancel|flag)/
            opt[action.to_sym] = true
          when /edit/
            opt[:editor] = true
          when /(add|remove) tag/
            type = action =~ /^add/ ? 'add' : 'remove'
            raise InvalidArgument, "'add tag' and 'remove tag' can not be used together" if opt[:tag]

            tags = type == 'add' ? all_tags(@content) : all_tags(items)

            add_msg = type == 'add' ? ', include values with tag(value)' : ''
            puts "#{Color.yellow}Separate multiple tags with spaces, hit tab to complete known tags#{add_msg}"
            puts "#{boldgreen}Available tags: #{boldwhite}#{tags.sort.map(&:add_at).join(', ')}" if type == 'remove'
            tag = Prompt.read_line(prompt: "Tags to #{type}", completions: tags)

            # print "#{yellow("Tag to #{type}: ")}#{reset}"
            # tag = $stdin.gets
            next if tag =~ /^ *$/

            opt[:tag] = tag.strip.sub(/^@/, '')
            opt[:remove] = true if type == 'remove'
          when /output formatted/
            plugins = Plugins.available_plugins(type: :export).sort
            output_format = Prompt.choose_from(plugins,
                                               prompt: 'Which output format? > ',
                                               fzf_args: [
                                                 "--height=#{plugins.count + 3}",
                                                 '--tac',
                                                 '--no-sort',
                                                 '--info=hidden'
                                               ])
            next if output_format =~ /^ *$/

            raise UserCancelled unless output_format

            opt[:output] = output_format.strip
            res = opt[:force] ? false : Prompt.yn('Save to file?', default_response: 'n')
            if res
              # print "#{yellow('File path/name: ')}#{reset}"
              # filename = $stdin.gets.strip
              filename = Prompt.read_line(prompt: 'File path/name')
              next if filename.empty?

              opt[:save_to] = filename
            end
          when /move/
            section = choose_section.strip
            opt[:move] = section.strip unless section =~ /^ *$/
          end
        end
      end

      if opt[:resume] || opt[:reset]
        raise InvalidArgument, 'resume and restart can only be used on a single entry' if items.count > 1

        item = items[0]
        if opt[:resume] && !opt[:reset]
          repeat_item(item, { editor: opt[:editor] }) # hooked
        elsif opt[:reset]
          res = Prompt.enter_text('Start date (blank for current time)', default_response: '')
          date = if res =~ /^ *$/
                   Time.now
                 else
                   res.chronify(guess: :begin)
                 end

          res = if item.tags?('done', :and) && !opt[:resume]
                  opt[:force] ? true : Prompt.yn('Remove @done tag?', default_response: 'y')
                else
                  opt[:resume]
                end
          old_item = item.clone
          new_entry = reset_item(item, date: date, resume: res)
          @content.update_item(item, new_entry)
          Hooks.trigger :post_entry_updated, self, new_entry, old_item
        end
        write(@doing_file)

        return
      end

      if opt[:delete]
        delete_items(items, force: opt[:force]) # hooked
        write(@doing_file)

        return
      end

      if opt[:flag]
        tag = Doing.setting('marker_tag', 'flagged')
        items.map! do |i|
          old_item = i.clone
          i.tag(tag, date: false, remove: opt[:remove], single: single)
          Hooks.trigger :post_entry_updated, self, i, old_item
        end
      end

      if opt[:finish] || opt[:cancel]
        tag = 'done'
        items.map! do |i|
          next unless i.should_finish?

          old_item = i.clone
          should_date = !opt[:cancel] && i.should_time?
          i.tag(tag, date: should_date, remove: opt[:remove], single: single)
          Hooks.trigger :post_entry_updated, self, i, old_item
        end
      end

      if opt[:autotag]
        items.map! do |i|
          new_title = autotag(i.title)
          if new_title == i.title
            logger.count(:skipped, level: :debug, message: '%count unchaged %items')
            # logger.debug('Autotag:', 'No changes')
          else
            logger.count(:added_tags)
            logger.write(items.count == 1 ? :info : :debug, 'Tagged:', new_title)
            old_item = i.clone
            i.title = new_title
            Hooks.trigger :post_entry_updated, self, i, old_item
          end
        end
      end

      if opt[:tag]
        tag = opt[:tag]
        items.map! do |i|
          old_item = i.clone
          i.tag(tag, date: false, remove: opt[:remove], single: single)
          i.expand_date_tags(Doing.setting('date_tags'))
          Hooks.trigger :post_entry_updated, self, i, old_item
        end
      end

      if opt[:archive] || opt[:move]
        section = opt[:archive] ? 'Archive' : guess_section(opt[:move])
        items.map! do |i|
          old_item = i.clone
          i.move_to(section, label: true)
          Hooks.trigger :post_entry_updated, self, i, old_item
        end
      end

      write(@doing_file)

      if opt[:editor]
        sleep 2 # This seems to be necessary between running fzf
        # and forking the editor, otherwise vim gets all
        # screwy and I can't figure out why
        edit_items(items) # hooked

        write(@doing_file)
      end

      return unless opt[:output]

      items.each { |i| i.title = "#{i.title} @section(#{i.section})" }

      export_items = Items.new
      export_items.concat(items)
      export_items.add_section(Section.new('Export'), log: false)
      options = { section: 'All' }

      if opt[:output] =~ /doing/
        options[:output] = 'template'
        options[:template] = '- %date | %title%note'
      else
        options[:output] = opt[:output]
        options[:template] = opt[:template] || nil
      end

      output = list_section(options, items: export_items) # hooked

      if opt[:save_to]
        file = File.expand_path(opt[:save_to])
        if File.exist?(file)
          # Create a backup copy for the undo command
          FileUtils.cp(file, "#{file}~")
        end

        File.open(file, 'w+') do |f|
          f.puts output
        end

        logger.warn('File written:', file)
      else
        Doing::Pager.page output
      end
    end

    ##
    ## Generate a menu of sections and allow user selection
    ##
    ## @return     [String] The selected section name
    ##
    def choose_section(include_all: false)
      options = @content.section_titles.sort
      options.unshift('All') if include_all
      choice = Prompt.choose_from(options, prompt: 'Choose a section > ', fzf_args: ['--height=60%'])
      choice ? choice.strip : choice
    end

    ##
    ## Generate a menu of tags and allow user selection
    ##
    ## @return     [String] The selected tag name
    ##
    def choose_tag(section = 'All', items: nil, include_all: false)
      items ||= @content.in_section(section)
      tags = all_tags(items, counts: true).map { |t, c| "@#{t} (#{c})" }
      tags.unshift('No tag filter') if include_all
      choice = Prompt.choose_from(tags,
                                  sorted: false,
                                  multiple: true,
                                  prompt: 'Choose tag(s) > ',
                                  fzf_args: ['--height=60%'])
      choice ? choice.split(/\n/).map { |t| t.strip.sub(/ \(.*?\)$/, '') }.join(' ') : choice
    end

    ##
    ## Generate a menu of sections and tags and allow user selection
    ##
    ## @return     [String] The selected section or tag name
    ##
    def choose_section_tag
      options = @content.section_titles.sort
      options.concat(@content.all_tags.sort.map { |t| "@#{t}" })
      choice = Prompt.choose_from(options, prompt: 'Choose a section or tag > ', fzf_args: ['--height=60%'])
      choice ? choice.strip : choice
    end

    ##
    ## Generate a menu of views and allow user selection
    ##
    ## @return     [String] The selected view name
    ##
    def choose_view
      choice = Prompt.choose_from(views.sort, prompt: 'Choose a view > ', fzf_args: ['--height=60%'])
      choice ? choice.strip : choice
    end

    ##
    ## Interactively verify an item modification if elapsed time is greater than configured threshold
    ##
    ## @param      date         [String] Item date
    ## @param      finish_date  [String] The finish date
    ## @param      title        [String] The Item title
    ##
    def verify_duration(date, finish_date, title: nil)
      max_elapsed = Doing.setting('interaction.confirm_longer_than', 0)
      max_elapsed = max_elapsed.chronify_qty if max_elapsed.is_a?(String)
      date = date.chronify(guess: :end, context: :today) if date.is_a?(String)
      finish_date = finish_date.chronify(guess: :end, context: :today) if finish_date.is_a?(String)

      elapsed = finish_date - date

      if max_elapsed.positive? && (elapsed > max_elapsed)
        puts Color.boldwhite(title) if title
        human = elapsed.time_string(format: :natural)
        res = Prompt.yn(Color.yellow("Did this entry actually take #{human}"), default_response: true)
        unless res
          new_elapsed = Prompt.enter_text('How long did it take?').chronify_qty
          raise InvalidTimeExpression, 'Unrecognized time span entry' unless new_elapsed.positive?

          finish_date = date + new_elapsed if new_elapsed
        end
      end

      finish_date
    end
  end
end
