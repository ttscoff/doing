# @@now @@next

module Doing
  # Methods for the now command
  class NowCommand
    def initialize(wwid)
      @wwid = wwid
    end

    def setup(cmd)
      add_examples(cmd)
      add_options(cmd)
    end

    def process_now_options(options)
      raise InvalidArgument, '--back and --from cannot be used together' if options[:back] && options[:from]

      if options[:back]
        options[:date] = options[:back]
      elsif options[:from]
        options[:date], finish_date = options[:from]
        finish_date = finish_date.is_a?(String) ? finish_date.chronify(guess: :end, context: :today) : finish_date
        options[:done] = finish_date.strftime('%F %R')
      else
        options[:date] = Time.now
      end
      raise InvalidTimeExpression.new('unable to parse date string', topic: 'Parser:') if options[:date].nil?

      options[:section] = if options[:section]
                            @wwid.guess_section(options[:section]) || options[:section].cap_first
                          else
                            Doing.setting('current_section')
                          end

      options[:ask_note] = if options[:ask] && !options[:editor] && options[:has_args]
                             Doing::Prompt.read_lines(prompt: 'Add a note')
                           else
                             ''
                           end

      options
    end

    def now_with_editor(options, args)
      raise MissingEditor, 'No EDITOR variable defined in environment' if Doing::Util.default_editor.nil?

      input = options[:date].strftime('%F %R | ')
      input += args.join(' ') unless args.empty?
      input += " @done(#{options[:done].strftime('%F %R')})" if options[:done]
      input += "\n#{options[:note]}" if options[:note]
      input += "\n#{options[:ask_note]}" if options[:ask_note].good?
      input = @wwid.fork_editor(input).strip

      d, title, note = @wwid.format_input(input)
      raise EmptyInput, 'No content' unless title.good?

      note = ask_note(options, note, prompt: false)

      options[:date] = d.nil? ? options[:date] : d
      opts = { note: note, back: options[:date], timed: options[:finish_last] }
      @wwid.add_item(title.cap_first, options[:section], opts)
    end

    def now_with_args(options, args)
      d, title, note = @wwid.format_input(args.join(' '))
      options[:date] = d.nil? ? options[:date] : d

      note = ask_note(options, note, prompt: false)

      opts = { note: note, back: options[:date], timed: options[:finish_last] }
      entry = @wwid.add_item(title.cap_first, options[:section], opts)
      return unless options[:done] && entry.should_finish?

      entry.should_time? ? entry.tag('done', value: options[:done]) : entry.tag('done')
    end

    def now_with_stdin(global_options, options, _args)
      d, title, note = @wwid.format_input(global_options[:stdin])

      unless d.nil?
        Doing.logger.debug('Parser:', 'Date detected in input, overriding command line values')
        options[:date] = d
      end

      note = ask_note(options, note, prompt: false)

      opts = { note: note, back: options[:date], timed: options[:finish_last] }
      entry = @wwid.add_item(title.cap_first, options[:section], opts)
      return unless options[:done] && entry.should_finish?

      entry.should_time? ? entry.tag('done', value: options[:done]) : entry.tag('done')
    end

    def interactive_now(options, _args)
      tags = @wwid.all_tags(@wwid.content)
      puts Doing::Color.boldgreen('Add a new entry. Tab will autocomplete known tags. Ctrl-c to cancel.')
      title = Doing::Prompt.read_line(prompt: 'Entry content', completions: tags)
      raise EmptyInput, 'You must provide content when creating a new entry' unless title.good?

      note = ask_note(options, prompt: true)

      opts = { note: note, back: options[:date], timed: options[:finish_last] }
      entry = @wwid.add_item(title.cap_first, options[:section], opts)
      return unless options[:done] && entry.should_finish?

      if entry.should_time?
        entry.tag('done', value: options[:done])
      else
        entry.tag('done')
      end
    end

    private

    def ask_note(options, note = nil, prompt: false)
      note ||= Doing::Note.new
      note.add(options[:note]) if options[:note]

      res = prompt ? Doing::Prompt.yn('Add a note', default_response: false) : false

      if options[:ask_note].empty? && (res || options[:ask])
        options[:ask_note] = Doing::Prompt.read_lines(prompt: 'Enter note')
      end

      note.add(options[:ask_note]) if options[:ask_note].good?
      note
    end

    def add_examples(cmd)
      cmd.example 'doing now', desc: 'Create a new entry with interactive prompts'
      cmd.example 'doing now -e', desc: "Open #{Doing::Util.default_editor} to input an entry and optional note"
      cmd.example 'doing now working on a new project', desc: 'Add a new entry at the current time'
      cmd.example 'doing now debugging @project2', desc: 'Add an entry with a tag'
      cmd.example 'doing now adding an entry (with a note)', desc: 'Parenthetical at end is converted to note'
      cmd.example 'doing now --back 2pm A thing I started at 2:00 and am still doing...', desc: 'Backdate an entry'
    end

    def add_options(cmd)
      cmd.desc 'Section'
      cmd.arg_name 'NAME'
      cmd.flag %i[s section]

      cmd.desc %(Set a start and optionally end time as a date range ("from 1pm to 2:30pm").
            If an end time is provided, a dated @done tag will be added)
      cmd.arg_name 'TIME_RANGE'
      cmd.flag [:from], type: DateRangeString

      cmd.desc 'Timed entry, marks last entry in section as @done'
      cmd.switch %i[f finish_last], negatable: false, default_value: false
    end
  end
end

desc 'Add an entry'
long_desc %(Record what you're starting now, or backdate the start time using natural language.

A parenthetical at the end of the entry will be converted to a note.

Run without arguments to create a new entry interactively.

Run with --editor to create a new entry using #{Doing::Util.default_editor}.)
arg_name 'ENTRY'
command %i[now next] do |c|
  cmd = Doing::NowCommand.new(@wwid)
  cmd.setup(c)
  add_options(:add_entry, c)

  # c.desc "Edit entry with specified app"
  # c.arg_name 'editor_app'
  # # c.flag [:a, :app]
  c.action do |global_options, options, args|
    Doing.auto_tag = !options[:noauto]
    options[:has_args] = args.count.positive?
    options = cmd.process_now_options(options)

    if options[:editor]
      cmd.now_with_editor(options, args)
    elsif args.length.positive?
      cmd.now_with_args(options, args)
    elsif global_options[:stdin]
      cmd.now_with_stdin(global_options, options, args)
    else
      cmd.interactive_now(options, args)
    end

    @wwid.write(@wwid.doing_file)
  end
end
