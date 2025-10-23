# frozen_string_literal: true

module Doing
  class WWID
    # Use fzf to filter an Items object with a search query.
    # Faster than {#filter_items} when all you need is a
    # text search of the title and note
    #
    # @param      items      [Items] an Items object
    # @param      query      [String] The search query
    # @param      case_type  [Symbol] The case type (:smart, :sensitive, :ignore)
    #
    # @return     [Items] Filtered Items array
    #
    def fuzzy_filter_items(items, query, case_type: :smart)
      scannable = items.map.with_index do |item, idx|
        "#{item.title} #{item.note.join(' ')}".gsub(/[|*?!]/, '') + "|#{idx}"
      end.join("\n")

      res = `echo #{Shellwords.escape(scannable)}|#{Prompt.fzf} #{fuzzy_filter_args(query, case_type).join(' ')}`
      selected = Items.new
      res.split(/\n/).each do |item|
        idx = item.match(/\|(\d+)$/)[1].to_i
        selected.push(items[idx])
      end
      selected
    end

    def fuzzy_filter_args(query, case_type)
      fzf_args = ['--multi', %(--filter="#{query.sub(/^'?/, "'")}"), '--no-sort', '-d "\|"', '--nth=1']
      fzf_args << case case_type.normalize_case
                  when :smart
                    query =~ /[A-Z]/ ? '+i' : '-i'
                  when :sensitive
                    '+i'
                  when :ignore
                    '-i'
                  end
      fzf_args
    end

    ##
    ## Filter items based on search criteria
    ##
    ## @param      items  [Array] The items to filter (if empty, filters all items)
    ## @param      opt    [Hash] The filter parameters
    ##
    ## @option opt [String] :section ('all')
    ## @option opt [Boolean] :unfinished (false)
    ## @option opt [Array or String] :tag ([]) Array or comma-separated string
    ## @option opt [Symbol] :tag_bool (:and) :and, :or, :not
    ## @option opt [String] :search ('') string, optional regex with `/string/`
    ## @option opt [Array] :date_filter (nil) [[Time]start, [Time]end]
    ## @option opt [Boolean] :only_timed (false)
    ## @option opt [String] :before (nil) Date/Time string, unparsed
    ## @option opt [String] :after  (nil) Date/Time string, unparsed
    ## @option opt [Boolean] :today (false) limit to entries from today
    ## @option opt [Boolean] :yesterday (false) limit to entries from yesterday
    ## @option opt [Number] :count (0) max entries to return
    ## @option opt [String] :age (new) 'old' or 'new'
    ## @option opt [Array] :val (nil) Array of tag value queries
    ##
    def filter_items(items = Items.new, opt: {})
      logger.measure(:filter_items) do
        time_rx = /^(\d{1,2}+(:\d{1,2}+)?( *(am|pm))?|midnight|noon)$/i

        if items.nil? || items.empty?
          section = !opt[:section] || opt[:section].empty? ? 'All' : guess_section(opt[:section])
          if section.is_a?(Array)
            section.each do |s|
              s = s[0] if s.is_a?(Array)
              items.concat(s =~ /^all$/i ? @content.clone : @content.in_section(s))
            end
          else
            items = section =~ /^all$/i ? @content.clone : @content.in_section(section)
          end
        end

        unless opt[:time_filter]
          opt[:time_filter] = [nil, nil]
          if opt[:from] && !opt[:date_filter]
            if opt[:from][0].is_a?(String) && opt[:from][0] =~ time_rx
              opt[:time_filter] = opt[:from]
            elsif opt[:from][0].is_a?(Time)
              opt[:date_filter] = opt[:from]
            end
          end
        end

        if opt[:before].is_a?(String) && opt[:before] =~ time_rx
          opt[:time_filter][1] = opt[:before]
          opt[:before] = nil
        end

        if opt[:after].is_a?(String) && opt[:after] =~ time_rx
          opt[:time_filter][0] = opt[:after]
          opt[:after] = nil
        end

        items.sort_by! { |item| [item.date, item.title.downcase] }.reverse

        filtered_items = items.select { |item| item.keep_item?(opt) }

        count = opt[:count].to_i&.positive? ? opt[:count].to_i : filtered_items.count

        output = Items.new

        if opt[:age] && opt[:age].normalize_age == :oldest
          output.concat(filtered_items.slice(0, count).reverse)
        else
          output.concat(filtered_items.reverse.slice(0, count))
        end

        output
      end
    end
  end
end
