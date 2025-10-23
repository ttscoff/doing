# frozen_string_literal: true

# @@done @@did
desc 'Add a completed item with @done(date). No argument finishes last entry'
long_desc 'Use this command to add an entry after you\'ve already finished it. It will be immediately marked as @done.
You can modify the start and end times of the entry using the --back, --took, and --at flags, making it an easy
way to add entries in post and maintain accurate (albeit manual) time tracking.'
arg_name 'ENTRY', optional: true
command %i[done did] do |c|
  c.example 'doing done', desc: 'Tag the last entry @done'
  c.example 'doing done I already finished this', desc: 'Add a new entry and immediately mark it @done'
  c.example 'doing done --back 30m This took me half an hour',
            desc: 'Add an entry with a start date 30 minutes ago and a @done date of right now'
  c.example 'doing done --at 3pm --took 1h Started and finished this afternoon',
            desc: 'Add an entry with a @done date of 3pm and a start date of 2pm (3pm - 1h)'

  c.desc 'Remove @done tag'
  c.switch %i[r remove], negatable: false, default_value: false

  c.desc 'Include date'
  c.switch [:date], negatable: true, default_value: true

  c.desc 'Immediately archive the entry'
  c.switch %i[a archive], negatable: false, default_value: false

  c.desc 'Section'
  c.arg_name 'NAME'
  c.flag %i[s section]

  c.desc 'Finish last entry not already marked @done'
  c.switch %i[u unfinished], negatable: false, default_value: false

  add_options(:add_entry, c)
  add_options(:finish_entry, c)

  c.action do |global_options, options, args|
    Doing.auto_tag = !options[:noauto]

    took = 0
    donedate = nil

    if options[:from]
      options[:from] = options[:from].split(/#{REGEX_RANGE_INDICATOR}/).map do |time|
        time =~ REGEX_TIME ? "today #{time.sub(/(?mi)(^.*?(?=\d+)|(?<=[ap]m).*?$)/, '')}" : time
      end.join(' to ').split_date_range
      date, finish_date = options[:from]
      finish_date ||= Time.now
    else
      if options[:took]
        took = options[:took]
        raise InvalidTimeExpression, 'Unable to parse date string for --took' if took.nil?
      end

      if options[:back]
        date = options[:back]
        raise InvalidTimeExpression, 'Unable to parse date string for --back' if date.nil?
      else
        date = options[:took] ? Time.now - took : Time.now
      end

      if options[:at]
        finish_date = options[:at]
        finish_date = finish_date.chronify(guess: :begin) if finish_date.is_a? String
        raise InvalidTimeExpression, 'Unable to parse date string for --at' if finish_date.nil?

        if options[:took]
          date = finish_date - took
        else
          date ||= finish_date
        end
      elsif options[:took]
        finish_date = date + took
      else
        finish_date = Time.now
      end
    end

    if options[:date]
      date = date.chronify(guess: :begin, context: :today) if date.is_a? String
      finish_date = @wwid.verify_duration(date, finish_date) unless options[:took] || options[:from]

      donedate = finish_date.strftime('%F %R')
    end

    section = if options[:section]
                @wwid.guess_section(options[:section]) || options[:section].cap_first
              else
                Doing.setting('current_section')
              end

    note = Doing::Note.new
    note.add(options[:note]) if options[:note]

    note.add(Doing::Prompt.read_lines(prompt: 'Add a note')) if options[:ask] && !options[:editor]

    if options[:editor]
      raise MissingEditor, 'No EDITOR variable defined in environment' if Doing::Util.default_editor.nil?

      is_new = false

      if args.empty?
        last_entry = @wwid.filter_items([],
                                        opt: { unfinished: options[:unfinished], section: section, count: 1,
                                               age: :newest }).max_by(&:date)

        unless last_entry
          Doing.logger.debug('Skipped:', options[:unfinished] ? 'No unfinished entry' : 'Last entry already @done')
          raise NoResults, 'No results'
        end

        old_entry = last_entry.clone
        last_entry.note.add(note)
        input = ["#{last_entry.date.strftime('%F %R | ')}#{last_entry.title}",
                 last_entry.note.strip_lines.join("\n")].join("\n")
      else
        is_new = true
        input = ["#{date.strftime('%F %R | ')}#{args.join(' ')}", note.strip_lines.join("\n")].join("\n")
      end

      input = @wwid.fork_editor(input).strip
      raise EmptyInput, 'No content' unless input.good?

      d, title, note = @wwid.format_input(input)

      if options[:ask]
        ask_note = Doing::Prompt.read_lines(prompt: 'Add a note')
        note.add(ask_note) if ask_note.good?
      end

      if Doing.auto_tag
        title = @wwid.autotag(title)
        title.add_tags!(Doing.setting('default_tags')) if Doing.setting('default_tags').good?
      end

      date = d.nil? ? date : d
      new_entry = Doing::Item.new(date, title, section, note)
      if new_entry.should_finish?
        if new_entry.should_time?
          new_entry.tag('done', value: donedate)
        else
          new_entry.tag('done')
        end
      end

      if is_new
        Doing::Hooks.trigger :pre_entry_add, @wwid, new_entry
        @wwid.content.push(new_entry)
        Doing::Hooks.trigger :post_entry_added, @wwid, new_entry
      else
        old = old_entry.clone
        @wwid.content.update_item(old_entry, new_entry)
        Doing::Hooks.trigger :post_entry_updated, @wwid, new_entry, old unless options[:archive]
      end

      if options[:archive]
        @wwid.move_item(new_entry, 'Archive', label: true)
        Doing::Hooks.trigger :post_entry_updated, @wwid, new_entry, old_entry
      end

      @wwid.write(@wwid.doing_file)
    elsif args.empty? && global_options[:stdin].nil?
      if options[:remove]
        @wwid.tag_last({ tags: ['done'], count: 1, section: section, remove: true })
      else
        opt = {
          archive: options[:archive],
          back: finish_date,
          count: 1,
          date: options[:date],
          note: note,
          section: section,
          tags: ['done'],
          took: took.zero? ? nil : took,
          unfinished: options[:unfinished]
        }
        @wwid.tag_last(opt)
      end
    elsif !args.empty?
      d, title, new_note = @wwid.format_input([args.join(' '), note.strip_lines.join("\n")].join("\n"))
      date = d.nil? ? date : d
      new_note.add(options[:note])
      title.chomp!
      section = 'Archive' if options[:archive]

      if Doing.auto_tag
        title = @wwid.autotag(title)
        title.add_tags!(Doing.setting('default_tags')) if Doing.setting('default_tags').good?
      end

      new_entry = Doing::Item.new(date, title, section, new_note)

      if new_entry.should_finish?
        if new_entry.should_time?
          new_entry.tag('done', value: donedate)
        else
          new_entry.tag('done')
        end
      end

      Doing::Hooks.trigger :pre_entry_add, @wwid, new_entry
      @wwid.content.push(new_entry)
      Doing::Hooks.trigger :post_entry_added, @wwid, new_entry
      @wwid.write(@wwid.doing_file)
      Doing.logger.info('New entry:', %(added "#{new_entry.date.relative_date}: #{new_entry.title}" to #{section}))
    elsif !global_options[:stdin].nil?
      Doing::Note.new(options[:note])
      d, title, note = @wwid.format_input(global_options[:stdin])
      unless d.nil?
        Doing.logger.debug('Parser:', 'Date detected in input, overriding command line values')
        date = d
      end
      note.add(options[:note]) if options[:note]
      section = options[:archive] ? 'Archive' : section
      new_entry = Doing::Item.new(date, title, section, note)

      if new_entry.should_finish?
        if new_entry.should_time?
          new_entry.tag('done', value: donedate)
        else
          new_entry.tag('done')
        end
      end

      Doing::Hooks.trigger :pre_entry_add, @wwid, new_entry
      @wwid.content.push(new_entry)
      Doing::Hooks.trigger :post_entry_added, @wwid, new_entry

      @wwid.write(@wwid.doing_file)
      Doing.logger.info('New entry:', %(added "#{new_entry.date.relative_date}: #{new_entry.title}" to #{section}))
    else
      raise EmptyInput, 'You must provide content when creating a new entry'
    end
  end
end
