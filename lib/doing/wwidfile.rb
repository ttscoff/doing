# frozen_string_literal: true

module Doing
  class Items < Array
    def from(path)
      return [] unless path
      path = File.expand_path(path)

      if File.exist?(path) && File.file?(path) && File.stat(path).size.positive?
        input = IO.read(File.expand_path(input))
        input = input.force_encoding('utf-8') if input.respond_to? :force_encoding
      end

      section = 'Uncategorized'
      lines = input.split(/[\n\r]/)
      current = 0

      lines.each do |line|
        next if line =~ /^\s*$/

        if line =~ /^(\S[\S ]+):\s*(@\S+\s*)*$/
          section = Regexp.last_match(1)
          @sections << { original: line, title: section }
          current = 0
        elsif line =~ /^\s*- (\d{4}-\d\d-\d\d \d\d:\d\d) \| (.*)/
          date = Regexp.last_match(1).strip
          title = Regexp.last_match(2).strip
          item = Item.new(date, title, section)
          @items.push(item)
          current += 1
        elsif current.zero?
          # if content[section][:items].length - 1 == current
          @other_content_top.push(line)
        elsif line =~ /^\S/
          @other_content_bottom.push(line)
        else
          prev_item = @items[current - 1]
          prev_item.note = Note.new unless prev_item.note

          prev_item.note.add(line)
          # end
        end
      end
      Hooks.trigger :post_read, self
    end

    def section_titles
      @sections.map { |s| s[:title] }
    end

    ##
    ## @brief      Adds a section.
    ##
    ## @param      title  (String) The new section title
    ##
    def add_section(title)
      if section_titles.include?(title.cap_first)
        Doing.logger.debug('Skipped': 'Section already exists')
        return
      end

      @sections << { original: "#{title}:", title: title }
      Doing.logger.info('Added section:', %("#{title.cap_first}"))
    end

    ##
    ## @brief      Attempt to match a string with an existing section
    ##
    ## @param      frag     (String) The user-provided string
    ## @param      guessed  (Boolean) already guessed and failed
    ##
    def guess_section(frag, guessed: false, suggest: false)
      return 'All' if frag =~ /^all$/i
      frag ||= wwid.config['current_section']

      @sections.each { |sect| return sect[:title].cap_first if frag.downcase == sect[:title].downcase }

      section = false
      re = frag.split('').join('.*?')
      sections.each do |sect|
        next unless sect =~ /#{re}/i

        Doing.logger.debug('Section match:', %(Assuming "#{sect}" from "#{frag}"))
        section = sect
        break
      end

      return section if suggest

      unless section || guessed
        alt = WWID.guess_view(frag, guessed: true, suggest: true)
        if alt
          meant_view = WWID.yn("Did you mean `doing view #{alt}`?", default_response: 'n')
          raise Errors::InvalidSection, "Run again with `doing view #{alt}`" if meant_view
        end

        res = WWID.yn("Section #{frag} not found, create it", default_response: 'n')

        if res
          add_section(frag.cap_first)
          WWID.write(@doing_file)
          return frag.cap_first
        end

        raise Errors::InvalidSection, "Unknown section: #{frag}"
      end
      section ? section.cap_first : guessed
    end

    def section_items(section)
      section = guess_section(section)
      return @items if section =~ /all/i

      @items.filter { |i| i.section == section }
    end
  end
end
