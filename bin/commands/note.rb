# @@note
desc 'Add a note to the last entry'
long_desc %(
  If -r is provided with no other arguments, the last note is removed.
  If new content is specified through arguments or STDIN, any previous
  note will be replaced with the new one.

  Use -e to load the last entry in a text editor where you can append a note.
)
arg_name 'NOTE_TEXT', optional: true
command :note do |c|
  c.example 'doing note', desc: 'Open the last entry in $EDITOR to append a note'
  c.example 'doing note "Just a quick annotation"', desc: 'Add a quick note to the last entry'
  c.example 'doing note --tag done "Keeping it real or something"', desc: 'Add a note to the last item tagged @done'
  c.example 'doing note --search "late night" -e', desc: 'Open $EDITOR to add a note to the last item containing "late night" (fuzzy matched)'

  c.desc 'Section'
  c.arg_name 'NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc "Edit entry with #{Doing::Util.default_editor}"
  c.switch %i[e editor], negatable: false, default_value: false

  c.desc "Replace/Remove last entry's note (default append)"
  c.switch %i[r remove], negatable: false, default_value: false

  c.desc 'Select item for new note from a menu of matching entries'
  c.switch %i[i interactive], negatable: false, default_value: false

  c.desc 'Prompt for note via multi-line input'
  c.switch %i[ask], negatable: false, default_value: false

  add_options(:search, c)
  add_options(:tag_filter, c)

  c.action do |_global_options, options, args|
    options[:fuzzy] = false
    options[:section] = @wwid.guess_section(options[:section]) || options[:section].cap_first if options[:section]
    options[:tag_bool] = options[:bool]

    if options[:search]
      search = options[:search]
      search.sub!(/^'?/, "'") if options[:exact]
      options[:search] = search
    end

    last_entry = @wwid.last_entry(options)
    old_entry = last_entry.clone

    raise NoResults, 'No entry matching parameters was found.' unless last_entry

    last_note = last_entry.note || Doing::Note.new
    new_note = Doing::Note.new

    new_note.add($stdin.read.strip) if $stdin.stat.size.positive?
    new_note.add(args.join(' ')) unless args.empty?

    if options[:editor]
      raise MissingEditor, 'No EDITOR variable defined in environment' if Doing::Util.default_editor.nil?

      input = if options[:remove]
                Doing::Note.new
              else
                last_entry.note || Doing::Note.new
              end

      input.add(new_note)

      new_note = Doing::Note.new(@wwid.fork_editor(input.strip_lines.join("\n"), message: nil).strip)
      options[:remove] = true
    end

    if (new_note.empty? && !options[:remove]) || options[:ask]
      $stderr.puts last_note if last_note.good?
      $stderr.puts new_note if new_note.good?
      new_note.add(Doing::Prompt.read_lines(prompt: 'Add a note'))
    end

    raise EmptyInput, 'You must provide content when adding a note' unless options[:remove] || new_note.good?

    if last_note.equal?(new_note)
      Doing.logger.debug('Skipped:', 'No note change')
    else
      last_note.add(new_note, replace: options[:remove])
      Doing.logger.info('Entry updated:', last_entry.title)
      Doing::Hooks.trigger :post_entry_updated, @wwid, last_entry, old_entry
    end
    # new_entry = Doing::Item.new(last_entry.date, last_entry.title, last_entry.section, new_note)
    @wwid.write(@wwid.doing_file)
  end
end
