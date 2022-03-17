# frozen_string_literal: true

module Doing
  class WWID
    ##
    ## Create a process for an editor and wait for the file handle to return
    ##
    ## @param      input  [String] Text input for editor
    ##
    def fork_editor(input = '', message: :default)
      # raise NonInteractive, 'Non-interactive terminal' unless $stdout.isatty || ENV['DOING_EDITOR_TEST']

      raise MissingEditor, 'No EDITOR variable defined in environment' if Util.default_editor.nil?

      tmpfile = Tempfile.new(['doing_temp', '.doing'])

      File.open(tmpfile.path, 'w+') do |f|
        f.puts input
        unless message.nil?
          f.puts message == :default ? '# First line is the entry title, lines after are added as a note' : message
        end
      end

      pid = Process.fork { system("#{Util.editor_with_args} #{tmpfile.path}") }

      trap('INT') do
        begin
          Process.kill(9, pid)
        rescue StandardError
          Errno::ESRCH
        end
        tmpfile.unlink
        tmpfile.close!
        exit 0
      end

      Process.wait(pid)

      begin
        if $?.exitstatus == 0
          input = IO.read(tmpfile.path)
        else
          exit_now! 'Cancelled'
        end
      ensure
        tmpfile.close
        tmpfile.unlink
      end

      input.split(/\n/).delete_if(&:ignore?).join("\n")
    end

    ##
    ## Takes a multi-line string and formats it as an entry
    ##
    ## @param      input  [String] The string to parse
    ##
    ## @return     [Array] [[String]title, [Note]note]
    ##
    def format_input(input)
      raise EmptyInput, 'No content in entry' if input.nil? || input.strip.empty?

      input_lines = input.split(/[\n\r]+/).delete_if(&:ignore?)
      title = input_lines[0]&.strip
      raise EmptyInput, 'No content in first line' if title.nil? || title.strip.empty?

      date = nil
      iso_rx = /\d{4}-\d\d-\d\d \d\d:\d\d/
      date_rx = /^(?:\s*- )?(?<date>.*?) \| (?=\S)/

      raise EmptyInput, 'No content' if title.sub(/^.*?\| */, '').strip.empty?

      title.expand_date_tags(Doing.setting('date_tags'))

      if title =~ date_rx
        m = title.match(date_rx)
        d = m['date']
        date = if d =~ iso_rx
                 Time.parse(d)
               else
                 d.chronify(guess: :begin)
               end
        title.sub!(date_rx, '').strip!
      end

      note = Note.new
      note.add(input_lines[1..-1]) if input_lines.length > 1
      # If title line ends in a parenthetical, use that as the note
      if note.empty? && title =~ /\s+\(.*?\)$/
        title.sub!(/\s+\((?<note>.*?)\)$/) do
          m = Regexp.last_match
          note.add(m['note'])
          ''
        end
      end

      note.strip_lines!
      note.compress

      [date, title, note]
    end

    def add_with_editor(**options)
      raise MissingEditor, 'No EDITOR variable defined in environment' if Util.default_editor.nil?

      input = options[:date].strftime('%F %R | ')
      input += options[:title]
      input += "\n#{options[:note]}" if options[:note]
      input = fork_editor(input).strip

      d, title, note = format_input(input)
      raise EmptyInput, 'No content' if title.empty?

      if options[:ask]
        ask_note = Doing::Prompt.read_lines(prompt: 'Add a note')
        note.add(ask_note) unless ask_note.empty?
      end

      date = d.nil? ? options[:date] : d
      finish = options[:finish_last] || false
      add_item(title.cap_first, options[:section], { note: note, back: date, timed: finish })
      write(@doing_file)
    end

    def edit_items(items)
      items.sort_by! { |i| i.date }
      editable_items = []

      items.each do |i|
        editable = "#{i.date.strftime('%F %R')} | #{i.title}"
        old_note = i.note ? i.note.strip_lines.join("\n") : nil
        editable += "\n#{old_note}" unless old_note.nil?
        editable_items << editable
      end
      divider = "-----------"
      notice =<<~EONOTICE

      # - You may delete entries, but leave all divider lines (---) in place.
      # - Start and @done dates replaced with a time string (yesterday 3pm) will
      #   be parsed automatically. Do not delete the pipe (|) between start date
      #   and entry title.
      EONOTICE
      input =  "#{editable_items.map(&:strip).join("\n#{divider}\n")}\n"

      new_items = fork_editor(input, message: notice).split(/^#{divider}/).map(&:strip)

      new_items.each_with_index do |new_item, i|
        input_lines = new_item.split(/[\n\r]+/).delete_if(&:ignore?)
        first_line = input_lines[0]&.strip

        if first_line.nil? || first_line =~ /^#{divider.strip}$/ || first_line.strip.empty?
          deleted = @content.delete_item(items[i], single: new_items.count == 1)
          Hooks.trigger :post_entry_removed, self, deleted
          Doing.logger.info('Deleted:', deleted.title)
        else
          date, title, note = format_input(new_item)

          note.map!(&:strip)
          note.delete_if(&:ignore?)
          item = items[i]
          old_item = item.clone
          item.date = date || items[i].date
          item.title = title
          item.note = note
          if (item.equal?(old_item))
            Doing.logger.count(:skipped, level: :debug)
          else
            Doing.logger.count(:updated)
            Hooks.trigger :post_entry_updated, self, item, old_item
          end
        end
      end
    end

    ##
    ## Edit the last entry
    ##
    ## @param      section  [String] The section, default "All"
    ##
    def edit_last(section: 'All', options: {})
      options[:section] = guess_section(section)

      item = last_entry(options)

      if item.nil?
        logger.debug('Skipped:', 'No entries found')
        return
      end

      old_item = item.clone
      content = ["#{item.date.strftime('%F %R')} | #{item.title.dup}"]
      content << item.note.strip_lines.join("\n") unless item.note.empty?
      new_item = fork_editor(content.join("\n"))
      raise UserCancelled, 'No change' if new_item.strip == content.join("\n").strip

      date, title, note = format_input(new_item)
      date ||= item.date

      if title.nil? || title.empty?
        logger.debug('Skipped:', 'No content provided')
      elsif title == item.title && note.equal?(item.note) && date.equal?(item.date)
        logger.debug('Skipped:', 'No change in content')
      else
        item.date = date unless date.nil?
        item.title = title
        item.note.add(note, replace: true)
        logger.info('Edited:', item.title)
        Hooks.trigger :post_entry_updated, self, item, old_item

        write(@doing_file)
      end
    end
  end
end
