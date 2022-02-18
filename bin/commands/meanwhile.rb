# @@meanwhile
desc 'Finish any running @meanwhile tasks and optionally create a new one'
long_desc 'The @meanwhile tag allows you to have long-running entries that encompass smaller entries.
This command makes it easy to start and stop these overarching entries. Just run `doing meanwhile Starting work on this
big project` to start a @meanwhile entry, add other entries as you work on the project, then use `doing meanwhile` by
itself to mark the entry as @done.'
arg_name 'ENTRY', optional: true
command :meanwhile do |c|
  c.example 'doing meanwhile "Long task that will have others after it before it\'s done"', desc: 'Add a new long-running entry, completing any current @meanwhile entry'
  c.example 'doing meanwhile', desc: 'Finish any open @meanwhile entry'
  c.example 'doing meanwhile --archive', desc: 'Finish any open @meanwhile entry and archive it'
  c.example 'doing meanwhile --back 2h "Something I\'ve been working on for a while', desc: 'Add a @meanwhile entry with a start date 2 hours ago'

  c.desc 'Section'
  c.arg_name 'NAME'
  c.flag %i[s section]

  c.desc 'Archive previous @meanwhile entry'
  c.switch %i[a archive], negatable: false, default_value: false

  add_options(:add_entry, c)

  c.action do |_global_options, options, args|
    Doing.auto_tag = !options[:noauto]

    if options[:back]
      date = options[:back]

      raise InvalidTimeExpression, 'Unable to parse date string' if date.nil?
    else
      date = Time.now
    end

    if options[:section]
      section = @wwid.guess_section(options[:section]) || options[:section].cap_first
    else
      section = Doing.setting('current_section')
    end
    input = ''

    ask_note = options[:ask] ? Doing::Prompt.read_lines(prompt: 'Add a note') : []

    if options[:editor]
      raise MissingEditor, 'No EDITOR variable defined in environment' if Doing::Util.default_editor.nil?
      input += date.strftime('%F %R | ')
      input += args.join(' ') unless args.empty?
      input += "\n#{options[:note]}" if options[:note]
      input += "\n#{ask_note}" unless ask_note.good?

      input = @wwid.fork_editor(input).strip
    elsif !args.empty?
      input = args.join(' ')
    elsif $stdin.stat.size.positive?
      input = $stdin.read.strip
    end

    if input.good?
      d, input, note = @wwid.format_input(input)
      unless d.nil?
        Doing.logger.debug('Parser:', 'Date detected in input, overriding command line values')
        date = d
      end
    else
      input = nil
      note = []
    end

    unless options[:editor]
      note.add(options[:note]) if options[:note]
      note.add(ask_note) if ask_note.good?
    end

    @wwid.stop_start('meanwhile', { new_item: input, back: date, section: section, archive: options[:archive], note: note })
    @wwid.write(@wwid.doing_file)
  end
end
