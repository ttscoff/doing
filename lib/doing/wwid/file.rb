# frozen_string_literal: true

module Doing
  # File methods for WWID class
  class WWID
    ##
    ## Initializes the doing file.
    ##
    ## @param      path  [String] Override path to a doing file, optional
    ##
    def init_doing_file(path = nil)
      @doing_file =  File.expand_path(Doing.setting('doing_file'))

      if path.nil?
        create(@doing_file) unless File.exist?(@doing_file)
        input = IO.read(@doing_file)
        input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
        logger.debug('Read:', "read file #{@doing_file}")
      elsif File.exist?(File.expand_path(path)) && File.file?(File.expand_path(path)) && File.stat(File.expand_path(path)).size.positive?
        @doing_file = File.expand_path(path)
        input = IO.read(File.expand_path(path))
        input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
        logger.debug('Read:', "read file #{File.expand_path(path)}")
      elsif path.length < 256
        @doing_file = File.expand_path(path)
        create(path)
        input = IO.read(File.expand_path(path))
        input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
        logger.debug('Read:', "read file #{File.expand_path(path)}")
      end

      @other_content_top = []
      @other_content_bottom = []

      section = nil
      lines = input.split(/[\n\r]/)

      lines.each do |line|
        next if line =~ /^\s*$/

        if line =~ /^(\S[\S ]+):\s*(@\S+\s*)*$/
          section = Regexp.last_match(1)
          @content.add_section(Section.new(section, original: line), log: false)
        elsif line =~ /^\s*- (\d{4}-\d\d-\d\d \d\d:\d\d) \| (.*)/
          if section.nil?
            section = 'Uncategorized'
            @content.add_section(Section.new(section, original: 'Uncategorized:'), log: false)
          end

          date = Regexp.last_match(1).strip
          title = Regexp.last_match(2).strip
          item = Item.new(date, title, section)
          @content.push(item)
        elsif @content.count.zero?
          # if content[section].items.length - 1 == current
          @other_content_top.push(line)
        elsif line =~ /^\S/
          @other_content_bottom.push(line)
        else
          prev_item = @content.last
          prev_item.note = Note.new unless prev_item.note

          prev_item.note.add(line)
          # end
        end
      end

      Hooks.trigger :post_read, self
      @initial_content = @content.clone
    end

    ##
    ## Create a new doing file
    ##
    def create(filename = nil)
      filename = @doing_file if filename.nil?
      return if File.exist?(filename) && File.stat(filename).size.positive?

      FileUtils.mkdir_p(File.dirname(filename)) unless File.directory?(File.dirname(filename))

      File.open(filename, 'w+') do |f|
        f.puts "#{Doing.setting('current_section')}:"
      end
    end

    ##
    ## Write content to file or STDOUT
    ##
    ## @param      file  [String] The filepath to write to
    ##
    def write(file = nil, backup: true)
      Hooks.trigger :pre_write, self, file
      output = combined_content
      if file.nil?
        $stdout.puts output
      else
        Util.write_to_file(file, output, backup: backup)
        run_after if Doing.setting('run_after')
      end

      # pp @content.diff(@initial_content)
    end

    ##
    ## Rename doing file with date and start fresh one
    ##
    def rotate(opt)
      opt ||= {}
      keep = opt[:keep] || 0
      tags = []
      tags.concat(opt[:tag].split(/ *, */).map { |t| t.sub(/^@/, '').strip }) if opt[:tag]
      bool  = opt[:bool] || :and
      sect = opt[:section] !~ /^all$/i ? guess_section(opt[:section]) : 'all'

      section = guess_section(sect)

      section_items = @content.in_section(section)
      max = section_items.count - keep.to_i

      counter = 0
      new_content = Items.new

      section_items.each do |item|
        break if counter >= max
        if opt[:before]
          time_string = opt[:before]
          cutoff = time_string.chronify(guess: :begin)
        end

        unless ((!tags.empty? && !item.tags?(tags, bool)) || (opt[:search] && !item.search(opt[:search].to_s)) || (opt[:before] && item.date >= cutoff))
          new_item = @content.delete(item)
          Hooks.trigger :post_entry_removed, self, item.clone
          raise DoingRuntimeError, "Error deleting item: #{item}" if new_item.nil?

          new_content.add_section(new_item.section, log: false)
          new_content.push(new_item)
          counter += 1
        end
      end

      if counter.positive?
        logger.count(:rotated,
                     level: :info,
                     count: counter,
                     message: "Rotated %count %items")
      else
        logger.info('Skipped:', 'No items were rotated')
      end

      write(@doing_file)

      file = @doing_file.sub(/(\.\w+)$/, "_#{Time.now.strftime('%Y-%m-%d')}\\1")
      if File.exist?(file)
        init_doing_file(file)
        @content.concat(new_content).uniq!
        logger.warn('File update:', "added entries to existing file: #{file}")
      else
        @content = new_content
        logger.warn('File update:', "created new file: #{file}")
      end

      write(file, backup: false)
    end

    private

    ##
    ## Wraps doing file content with additional
    ##             header/footer content
    ##
    ## @return     [String] concatenated content
    ## @api private
    def combined_content
      output = @other_content_top ? "#{@other_content_top.join("\n")}\n" : ''
      was_color = Color.coloring?
      Color.coloring = false
      @content.dedup!(match_section: true)
      output += @content.to_s
      output += @other_content_bottom.join("\n") unless @other_content_bottom.nil?
      # Just strip all ANSI colors from the content before writing to doing file
      Color.coloring = was_color

      output.uncolor
    end
  end
end
