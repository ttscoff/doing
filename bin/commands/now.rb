# @@now @@next
desc 'Add an entry'
long_desc %(Record what you're starting now, or backdate the start time using natural language.

A parenthetical at the end of the entry will be converted to a note.

Run without arguments to create a new entry interactively.

Run with --editor to create a new entry using #{Doing::Util.default_editor}.)
arg_name 'ENTRY'
command %i[now next] do |c|
  c.example 'doing now', desc: 'Create a new entry with interactive prompts'
  c.example 'doing now -e', desc: "Open #{Doing::Util.default_editor} to input an entry and optional note"
  c.example 'doing now working on a new project', desc: 'Add a new entry at the current time'
  c.example 'doing now debugging @project2', desc: 'Add an entry with a tag'
  c.example 'doing now adding an entry (with a note)', desc: 'Parenthetical at end is converted to note'
  c.example 'doing now --back 2pm A thing I started at 2:00 and am still doing...', desc: 'Backdate an entry'

  c.desc 'Section'
  c.arg_name 'NAME'
  c.flag %i[s section]

  c.desc %(
        Set a start and optionally end time as a date range ("from 1pm to 2:30pm").
        If an end time is provided, a dated @done tag will be added
      )
  c.arg_name 'TIME_RANGE'
  c.flag [:from], type: DateRangeString

  c.desc 'Timed entry, marks last entry in section as @done'
  c.switch %i[f finish_last], negatable: false, default_value: false

  add_options(:add_entry, c)

  # c.desc "Edit entry with specified app"
  # c.arg_name 'editor_app'
  # # c.flag [:a, :app]

  c.action do |global_options, options, args|
    Doing.auto_tag = !options[:noauto]

    raise InvalidArgument, '--back and --from cannot be used together' if options[:back] && options[:from]

    if options[:back]
      date = options[:back]
    elsif options[:from]
      date, finish_date = options[:from]
      options[:done] = finish_date
    else
      date = Time.now
    end
    raise InvalidTimeExpression.new('unable to parse date string', topic: 'Parser:') if date.nil?

    section = if options[:section]
                @wwid.guess_section(options[:section]) || options[:section].cap_first
              else
                Doing.setting('current_section')
              end

    ask_note = if options[:ask] && !options[:editor] && args.count.positive?
                 Doing::Prompt.read_lines(prompt: 'Add a note')
               else
                 ''
               end

    if options[:editor]
      raise MissingEditor, 'No EDITOR variable defined in environment' if Doing::Util.default_editor.nil?

      input = date.strftime('%F %R | ')
      input += args.join(' ') unless args.empty?
      input += " @done(#{options[:done].strftime('%F %R')})" if options[:done]
      input += "\n#{options[:note]}" if options[:note]
      input += "\n#{ask_note}" if ask_note.good?
      input = @wwid.fork_editor(input).strip

      d, title, note = @wwid.format_input(input)
      raise EmptyInput, 'No content' unless title.good?

      if ask_note.empty? && options[:ask]
        ask_note = Doing::Prompt.read_lines(prompt: 'Add a note')
        note.add(ask_note) if ask_note.good?
      end

      date = d.nil? ? date : d
      @wwid.add_item(title.cap_first, section, { note: note, back: date, timed: options[:finish_last] })
    elsif args.length.positive?
      d, title, note = @wwid.format_input(args.join(' '))
      date = d.nil? ? date : d
      note.add(options[:note]) if options[:note]
      note.add(ask_note) if ask_note.good?
      entry = @wwid.add_item(title.cap_first, section, { note: note, back: date, timed: options[:finish_last] })
      if options[:done] && entry.should_finish?
        if entry.should_time?
          entry.tag('done', value: options[:done])
        else
          entry.tag('done')
        end
      end
    elsif global_options[:stdin]
      input = global_options[:stdin]
      d, title, note = @wwid.format_input(input)
      unless d.nil?
        Doing.logger.debug('Parser:', 'Date detected in input, overriding command line values')
        date = d
      end
      note.add(options[:note]) if options[:note]
      if ask_note.empty? && options[:ask]
        ask_note = Doing::Prompt.read_lines(prompt: 'Add a note')
        note.add(ask_note) if ask_note.good?
      end
      entry = @wwid.add_item(title.cap_first, section, { note: note, back: date, timed: options[:finish_last] })
      if options[:done] && entry.should_finish?
        if entry.should_time?
          entry.tag('done', value: options[:done])
        else
          entry.tag('done')
        end
      end
    else
      tags = @wwid.all_tags(@wwid.content)
      $stderr.puts Doing::Color.boldgreen("Add a new entry. Tab will autocomplete known tags. Ctrl-c to cancel.")
      title = Doing::Prompt.read_line(prompt: 'Entry content', completions: tags)
      raise EmptyInput, 'You must provide content when creating a new entry' unless title.good?

      note = Doing::Note.new
      note.add(options[:note]) if options[:note]
      res = Doing::Prompt.yn('Add a note', default_response: false)
      ask_note = res ? Doing::Prompt.read_lines(prompt: 'Enter note') : []
      note.add(ask_note)

      entry = @wwid.add_item(title.cap_first, section, { note: note, back: date, timed: options[:finish_last] })
      if options[:done] && entry.should_finish?
        if entry.should_time?
          entry.tag('done', value: options[:done])
        else
          entry.tag('done')
        end
      end
    end

    @wwid.write(@wwid.doing_file)
  end
end
