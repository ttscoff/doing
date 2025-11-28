# frozen_string_literal: true

module Doing
  class WWID
    ##
    ## Adds an entry
    ##
    ## @param      title    [String] The entry title
    ## @param      section  [String] The section to add to
    ## @param      opt      [Hash] Additional Options
    ##
    ## @option opt :date [Date] item start date
    ## @option opt :note [Note] item note (will be converted if value is String)
    ## @option opt :back [Date] backdate
    ## @option opt :timed [Boolean] new item is timed entry, marks previous entry as @done
    ## @option opt :done [Date] If set, adds a @done tag to new entry
    ##
    def add_item(title, section = nil, opt)
      opt ||= {}
      section ||= Doing.setting('current_section')
      @content.add_section(section, log: false)
      opt[:back] ||= opt[:date] || Time.now
      opt[:date] ||= Time.now
      note = Note.new
      opt[:timed] ||= false

      note.add(opt[:note]) if opt[:note]

      title = [title.strip.cap_first]
      title = title.join(' ')

      if Doing.auto_tag
        title = autotag(title)
        title.add_tags!(Doing.setting('default_tags')) if Doing.setting('default_tags').good?
      end

      title.compress!
      entry = Item.new(opt[:back], title.strip, section)

      if opt[:done] && entry.should_finish?
        if entry.should_time?
          finish = opt[:done].is_a?(String) ? opt[:done].chronify(guess: :end, context: :today) : opt[:done]
          entry.tag('done', value: finish)
        else
          entry.tag('done')
        end
      end

      entry.note = note

      if opt[:timed]
        last_item = last_entry({ section: section })
        if last_item.tags?(['done'], :not)
          finish_date = verify_duration(last_item.date, opt[:back], title: last_item.title)
          last_item.tag('done', value: finish_date.strftime('%F %R'))
        end
      end

      Hooks.trigger :pre_entry_add, self, entry

      @content.push(entry)
      # logger.count(:added, level: :debug)
      logger.info('New entry:', %(added "#{entry.date.relative_date}: #{entry.title}" to #{section}))

      Hooks.trigger :post_entry_added, self, entry
      entry
    end

    # Reset start date to current time, optionally remove
    # done tag (resume)
    #
    # @param      item    [Item] the item to reset/resume
    # @param      resume  [Boolean] removing @done tag if true
    #
    def reset_item(item, date: nil, finish_date: nil, resume: false)
      date ||= Time.now
      item.date = date
      if finish_date
        item.tag('done', remove: true)
        item.tag('done', value: finish_date.strftime('%F %R'))
      elsif resume
        item.tag('done', remove: true)
      end
      logger.info('Reset:', %(Reset #{resume ? 'and resumed ' : ''} "#{item.title}" in #{item.section}))
      item
    end

    # Duplicate an item and add it as a new item
    #
    # @param      item    [Item] the item to duplicate
    # @param      opt     [Hash] additional options
    #
    # @option opt :editor [Boolean] open new item in editor
    # @option opt :date   [String] set start date
    # @option opt :in     [String] add new item to section :in
    # @option opt :note   [Note] add note to new item
    #
    # @return     nothing
    #
    def repeat_item(item, opt)
      opt ||= {}
      old_item = item.clone
      if item.unfinished? && item.should_finish?
        if item.should_time?
          finish_date = verify_duration(item.date, Time.now, title: item.title)
          item.title.tag!('done', value: finish_date.strftime('%F %R'))
        else
          item.title.tag!('done')
        end
        Hooks.trigger :post_entry_updated, self, item, old_item
      end

      # Remove @done tag
      title = item.title.sub(/\s*@done(\(.*?\))?/, '').chomp
      section = opt[:in].nil? ? item.section : guess_section(opt[:in])
      Doing.auto_tag = false

      note = opt[:note] || Note.new

      if opt[:editor]
        start = opt[:date] || Time.now
        to_edit = "#{start.strftime('%F %R')} | #{title}"
        to_edit += "\n#{note.strip_lines.join("\n")}" unless note.empty?
        new_item = fork_editor(to_edit)
        date, title, note = format_input(new_item)

        opt[:date] = date unless date.nil?

        if title.nil? || title.empty?
          logger.warn('Skipped:', 'No content provided')
          return
        end
      end

      # @content.update_item(original, item)
      add_item(title, section, { note: note, back: opt[:date], timed: false })
    end

    ##
    ## Restart the last entry
    ##
    ## @param      opt   [Hash] Additional Options
    ##
    def repeat_last(opt)
      opt ||= {}
      opt[:section] ||= 'all'
      opt[:section] = guess_section(opt[:section])
      opt[:note] ||= []
      opt[:tag] ||= []
      opt[:tag_bool] ||= :and

      last = last_entry(opt)
      if last.nil?
        logger.warn('Skipped:', 'No previous entry found')
        return
      end

      repeat_item(last, opt)
      write(@doing_file)
    end

    ##
    ## Tag the last entry or X entries
    ##
    ## @param      opt   [Hash] Additional Options (see
    ##                   #filter_items for filtering
    ##                   options)
    ##
    ## @see        #filter_items
    ##
    # hooked
    def tag_last(opt)
      opt ||= {}
      opt[:count] ||= 1
      opt[:archive] ||= false
      opt[:tags] ||= ['done']
      opt[:sequential] ||= false
      opt[:date] ||= false
      opt[:remove] ||= false
      opt[:update] ||= false
      opt[:autotag] ||= false
      opt[:back] ||= false
      opt[:unfinished] ||= false
      opt[:section] = opt[:section] ? guess_section(opt[:section]) : 'All'

      items = filter_items(Items.new, opt: opt)

      if opt[:interactive]
        items = Prompt.choose_from_items(items, include_section: opt[:section] =~ /^all$/i, menu: true,
                                                header: '',
                                                prompt: 'Select entries to tag > ',
                                                multiple: true,
                                                sort: true,
                                                show_if_single: true)

        raise NoResults, 'no items selected' if items.empty?

      end

      raise NoResults, 'no items matched your search' if items.empty?

      if opt[:tags].empty? && !opt[:autotag]
        completions = opt[:remove] ? all_tags(items) : all_tags(@content)
        if opt[:remove]
          puts "#{Color.yellow}Available tags: #{Color.boldwhite}#{completions.map(&:add_at).join(', ')}"
        else
          puts "#{Color.yellow}Use tab to complete known tags"
        end
        opt[:tags] = Doing::Prompt.read_line(prompt: "Enter tag(s) to #{opt[:remove] ? 'remove' : 'add'}",
                                             completions: completions,
                                             default_response: '').to_tags
        raise UserCancelled, 'No tags provided' if opt[:tags].empty?
      end

      items.each do |item|
        old_item = item.clone
        added = []
        removed = []

        item.date = opt[:start_date] if opt[:start_date]

        if opt[:autotag]
          new_title = autotag(item.title) if Doing.auto_tag
          if new_title == item.title
            logger.count(:skipped, level: :debug, message: '%count unchaged %items')
            # logger.debug('Autotag:', 'No changes')
          else
            logger.count(:added_tags)
            logger.write(items.count == 1 ? :info : :debug, 'Tagged:', new_title)
            item.title = new_title
          end
        else
          if opt[:done_date]
            done_date = opt[:done_date]
          elsif opt[:sequential]
            next_entry = next_item(item)

            done_date = if next_entry.nil?
                          Time.now
                        else
                          next_entry.date - 60
                        end
          else
            done_date = item.calculate_end_date(opt)
          end

          opt[:tags].each do |tag|
            if tag == 'done' && !item.should_finish?

              Doing.logger.debug('Skipped:', "Item in never_finish: #{item.title}")
              logger.count(:skipped, level: :debug)
              next
            end

            tag = tag.strip

            if tag =~ /^(\S+)\((.*?)\)$/
              m = Regexp.last_match
              tag = m[1]
              opt[:value] ||= m[2]
            end

            if tag =~ /^done$/ && opt[:date] && item.should_time?
              max_elapsed = Doing.setting('interaction.confirm_longer_than', 0)
              max_elapsed = max_elapsed.chronify_qty if max_elapsed.is_a?(String)
              elapsed = done_date - item.date

              if max_elapsed.positive? && (elapsed > max_elapsed) && !opt[:took]
                puts Color.boldwhite(item.title)
                human = elapsed.time_string(format: :natural)
                res = Prompt.yn(Color.yellow("Did this actually take #{human}"), default_response: true)
                unless res
                  new_elapsed = Prompt.enter_text('How long did it take?').chronify_qty
                  raise InvalidTimeExpression, 'Unrecognized time span entry' unless new_elapsed.positive?

                  opt[:took] = new_elapsed
                  done_date = item.calculate_end_date(opt) if opt[:took]
                end
              end
            end

            if opt[:remove] || opt[:rename] || opt[:value]
              rename_to = nil

              if opt[:value]
                rename_to = tag
              elsif opt[:rename]
                rename_to = tag
                tag = opt[:rename]
              end
              old_title = item.title.dup
              force = opt[:value].nil? ? false : true
              item.title.tag!(tag, remove: opt[:remove], rename_to: rename_to, regex: opt[:regex], value: opt[:value],
                                   force: force)
              if old_title != item.title
                removed << tag
                added << rename_to if rename_to
              else
                logger.count(:skipped, level: :debug)
              end
            else
              old_title = item.title.dup
              should_date = opt[:date] && item.should_time?
              item.title.tag!('done', remove: true) if tag =~ /done/ && (!should_date || opt[:update])
              item.title.tag!(tag, value: should_date ? done_date.strftime('%F %R') : nil)
              added << tag if old_title != item.title
            end
          end
        end

        logger.log_change(tags_added: added, tags_removed: removed, item: item, single: items.count == 1)

        item.note.add(opt[:note]) if opt[:note]

        if opt[:archive] && opt[:section] != 'Archive' && opt[:count].positive?
          item.move_to('Archive', label: true)
        elsif opt[:archive] && opt[:count].zero?
          logger.warn('Skipped:', 'Archiving is skipped when operating on all entries')
        end

        item.expand_date_tags(Doing.setting('date_tags'))
        Hooks.trigger :post_entry_updated, self, item, old_item
      end

      write(@doing_file)
    end

    ##
    ## Accepts one tag and the raw text of a new item if the
    ## passed tag is on any item, it's replaced with @done.
    ## if new_item is not nil, it's tagged with the passed
    ## tag and inserted. This is for use where only one
    ## instance of a given tag should exist (@meanwhile)
    ##
    ## @param      target_tag  [String] Tag to replace
    ## @param      opt         [Hash] Additional Options
    ##
    ## @option opt :section [String] target section
    ## @option opt :archive [Boolean] archive old item
    ## @option opt :back [Date] backdate new item
    ## @option opt :new_item [String] content to use for new item
    ## @option opt :note [Array] note content for new item
    def stop_start(target_tag, opt)
      opt ||= {}
      tag = target_tag.dup
      opt[:section] ||= Doing.setting('current_section')
      opt[:archive] ||= false
      opt[:back] ||= Time.now
      opt[:new_item] ||= false
      opt[:note] ||= false

      opt[:section] = guess_section(opt[:section])

      tag.sub!(/^@/, '')

      found_items = 0

      @content.each_with_index do |item, i|
        old_item = i.clone
        next unless item.section == opt[:section] || opt[:section] =~ /all/i

        next unless item.title =~ /@#{tag}/

        item.title.add_tags!([tag, 'done'], remove: true)
        item.tag('done', value: opt[:back].strftime('%F %R'))

        found_items += 1

        if opt[:archive] && opt[:section] != 'Archive'
          item.title = item.title.sub(/(?:@from\(.*?\))?(.*)$/, "\\1 @from(#{item.section})")
          item.move_to('Archive', label: false, log: false)
          logger.count(:completed_archived)
          logger.info('Completed/archived:', item.title)
        else
          logger.count(:completed)
          logger.info('Completed:', item.title)
        end
        Hooks.trigger :post_entry_updated, self, item, old_item
      end

      logger.debug('Skipped:', "No active @#{tag} tasks found.") if found_items.zero?

      if opt[:new_item]
        date, title, note = format_input(opt[:new_item])
        opt[:back] = date unless date.nil?
        note.add(opt[:note]) if opt[:note]
        title.tag!(tag)
        add_item(title.cap_first, opt[:section], { note: note, back: opt[:back] })
      end

      write(@doing_file)
    end

    ##
    ## Delete a set of items from the main index
    ##
    ## @param      items  [Array] The items to delete
    ## @param      force  [Boolean] Force deletion without confirmation
    ##
    def delete_items(items, force: false)
      items.slice(0, 5).each { |i| puts i.to_pretty } unless force
      puts Color.softpurple("+ #{items.size - 5} additional #{'item'.to_p(items.size - 5)}") if items.size > 5 && !force

      res = force ? true : Prompt.yn("Delete #{items.size} #{'item'.to_p(items.size)}?", default_response: 'y')
      return unless res

      items.each { |i| Hooks.trigger :post_entry_removed, self, @content.delete_item(i, single: items.count == 1) }
      # write(@doing_file)
    end

    ##
    ## Move entries from a section to Archive or other specified
    ##             section
    ##
    ## @param      section      [String] The source section
    ## @param      options      [Hash] Options
    ##
    def archive(section = Doing.setting('current_section'), options)
      options ||= {}
      count       = options[:keep] || 0
      destination = options[:destination] || 'Archive'
      tags        = options[:tags] || []
      bool        = options[:bool] || :and

      section = section[0] if section.is_a?(Array) && section.count == 1
      section = choose_section if section.nil? || section.empty? || section.is_a?(String) && section =~ /choose/i
      archive_all = section =~ /^all$/i # && !(tags.nil? || tags.empty?)
      section = guess_section(section) unless archive_all

      @content.add_section(destination, log: true)
      # add_section(Section.new('Archive')) if destination =~ /^archive$/i && !@content.section?('Archive')

      destination = guess_section(destination)

      unless @content.section?(destination) && (@content.section?(section) || archive_all)
        raise InvalidArgument, 'Either source or destination does not exist'
      end

      do_archive(section, destination,
                 { count: count, tags: tags, bool: bool, search: options[:search], label: options[:label], before: options[:before], after: options[:after], from: options[:from] })
      write(doing_file)
    end

    ##
    ## Uses 'autotag' configuration to turn keywords into tags for time tracking.
    ## Does not repeat tags in a title, and only converts the first instance of an
    ## untagged keyword
    ##
    ## @param      string  [String] The text to tag
    ##
    def autotag(string)
      return unless string
      return string unless Doing.auto_tag

      original = string.dup
      text = string.dup

      current_tags = text.scan(/@\w+/).map { |t| t.sub(/^@/, '') }
      tagged = {
        whitelisted: [],
        synonyms: [],
        transformed: [],
        replaced: []
      }

      Doing.setting('autotag.whitelist').each do |tag|
        next if text =~ /@#{tag}\b/i

        text.sub!(/(?<= |\A)(#{tag.strip})(?= |\Z)/i) do |m|
          m.downcase! unless tag =~ /[A-Z]/
          tagged[:whitelisted].push(m)
          "@#{m}"
        end
      end

      Doing.setting('autotag.synonyms').each do |tag, v|
        v.each do |word|
          word = word.wildcard_to_rx
          next unless text =~ /\b#{word}\b/i

          unless current_tags.include?(tag) || tagged[:whitelisted].include?(tag)
            tagged[:synonyms].push(tag)
            tagged[:synonyms] = tagged[:synonyms].uniq
          end
        end
      end

      Doing.setting('autotag.transform')&.each do |tag|
        next unless tag =~ /\S+:\S+/

        if tag =~ /::/
          rx, r = tag.split(/::/)
        else
          rx, r = tag.split(/:/)
        end

        flag_rx = %r{/(r+)$}
        if r =~ flag_rx
          flags = r.match(flag_rx)[1].split(//)
          r.sub!(flag_rx, '')
        end
        r.gsub!(/\$/, '\\')
        rx.sub!(/^@?/, '@')
        regex = Regexp.new("(?<= |\\A)#{rx}(?= |\\Z)")

        text.sub!(regex) do
          m = Regexp.last_match
          new_tag = r

          m.to_a.slice(1, m.length - 1).each_with_index do |v, idx|
            next if v.nil?

            new_tag.gsub!("\\#{idx + 1}", v)
          end
          # Replace original tag if /r
          if flags&.include?('r')
            tagged[:replaced].concat(new_tag.split(/ /).map { |t| t.sub(/^@/, '') })
            new_tag.split(/ /).map { |t| t.sub(/^@?/, '@') }.join(' ')
          else
            tagged[:transformed].concat(new_tag.split(/ /).map { |t| t.sub(/^@/, '') })
            tagged[:transformed] = tagged[:transformed].uniq
            m[0]
          end
        end
      end

      logger.debug('Autotag:', "whitelisted tags: #{tagged[:whitelisted].log_tags}") unless tagged[:whitelisted].empty?
      logger.debug('Autotag:', "synonyms: #{tagged[:synonyms].log_tags}") unless tagged[:synonyms].empty?
      logger.debug('Autotag:', "transforms: #{tagged[:transformed].log_tags}") unless tagged[:transformed].empty?
      logger.debug('Autotag:', "transform replaced: #{tagged[:replaced].log_tags}") unless tagged[:replaced].empty?

      tail_tags = tagged[:synonyms].concat(tagged[:transformed])
      tail_tags.sort!
      tail_tags.uniq!

      text.add_tags!(tail_tags) unless tail_tags.empty?

      if text == original
        logger.debug('Autotag:', "no change to \"#{text.strip}\"")
      else
        new_tags = tagged[:whitelisted].concat(tail_tags).concat(tagged[:replaced])
        logger.debug('Autotag:', "added #{new_tags.log_tags} to \"#{text.strip}\"")
        logger.count(:autotag, level: :info, count: 1, message: 'autotag updated %count %items')
      end

      text.dedup_tags
    end

    private

    ##
    ## Helper function, performs the actual archiving
    ##
    ## @param      section      [String] The source section
    ## @param      destination  [String] The destination
    ##                          section
    ## @param      opt          [Hash] Additional Options
    ## @api private
    def do_archive(section, destination, opt)
      opt ||= {}
      count = opt[:count] || 0
      tags  = opt[:tags] || []
      bool  = opt[:bool] || :and
      label = opt[:label]

      section = guess_section(section)
      destination = guess_section(destination)

      section_items = @content.in_section(section)
      max = section_items.count - count.to_i

      opt[:after] = opt[:from][0] if opt[:from]
      opt[:before] = opt[:from][1] if opt[:from]

      time_rx = /^(\d{1,2}+(:\d{1,2}+)?( *(am|pm))?|midnight|noon)$/

      if opt[:before].is_a?(String) && opt[:before] =~ time_rx
        opt[:before] = opt[:before].chronify(guess: :end, future: false)
      end

      if opt[:after].is_a?(String) && opt[:after] =~ time_rx
        opt[:after] = opt[:after].chronify(guess: :begin, future: false)
      end

      counter = 0

      @content.map do |item|
        break if counter >= max

        next if item.section.downcase == destination.downcase

        next if item.section.downcase != section.downcase && section != /^all$/i

        next if (opt[:before] && item.date > opt[:before]) || (opt[:after] && item.date < opt[:after])

        next if (!tags.empty? && !item.tags?(tags, bool)) || (opt[:search] && !item.search(opt[:search].to_s))

        counter += 1
        old_item = item.clone
        item.move_to(destination, label: label, log: false)
        Hooks.trigger :post_entry_updated, self, item, old_item
        item
      end

      if counter.positive?
        logger.count(destination == 'Archive' ? :archived : :moved,
                     level: :info,
                     count: counter,
                     message: "%count %items from #{section} to #{destination}")
      else
        logger.info('Skipped:', 'No items were moved')
      end
    end
  end
end
