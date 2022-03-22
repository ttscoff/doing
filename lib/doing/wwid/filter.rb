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
      scannable = items.map.with_index { |item, idx| "#{item.title} #{item.note.join(' ')}".gsub(/[|*?!]/, '') + "|#{idx}"  }.join("\n")

      fzf_args = [
        '--multi',
        %(--filter="#{query.sub(/^'?/, "'")}"),
        '--no-sort',
        '-d "\|"',
        '--nth=1'
      ]
      fzf_args << case case_type.normalize_case
                  when :smart
                    query =~ /[A-Z]/ ? '+i' : '-i'
                  when :sensitive
                    '+i'
                  when :ignore
                    '-i'
                  end

      # fzf_args << '-e' if opt[:exact]
      # puts fzf_args.join(' ')
      res = `echo #{Shellwords.escape(scannable)}|#{Prompt.fzf} #{fzf_args.join(' ')}`
      selected = Items.new
      res.split(/\n/).each do |item|
        idx = item.match(/\|(\d+)$/)[1].to_i
        selected.push(items[idx])
      end
      selected
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
      logger.benchmark(:filter_items, :start)
      time_rx = /^(\d{1,2}+(:\d{1,2}+)?( *(am|pm))?|midnight|noon)$/i

      if items.nil? || items.empty?
        section = opt[:section] ? guess_section(opt[:section]) : 'All'
        items = section =~ /^all$/i ? @content.clone : @content.in_section(section)
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

      filtered_items = items.select do |item|
        keep = true
        if opt[:unfinished]
          finished = item.tags?('done', :and)
          finished = opt[:not] ? !finished : finished
          keep = false if finished
        end

        if keep && opt[:val]&.count&.positive?
          bool = opt[:bool].normalize_bool if opt[:bool]
          bool ||= :and
          bool = :and if bool == :pattern

          val_match = opt[:val].nil? || opt[:val].empty? ? true : item.tag_values?(opt[:val], bool)
          keep = false unless val_match
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:tag]
          opt[:tag_bool] = opt[:bool].normalize_bool if opt[:bool]
          opt[:tag_bool] ||= :and
          tag_match = opt[:tag].nil? || opt[:tag].empty? ? true : item.tags?(opt[:tag], opt[:tag_bool])
          keep = false unless tag_match
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:search]
          search_match = if opt[:search].nil? || opt[:search].empty?
                           true
                         else
                           item.search(opt[:search], case_type: opt[:case].normalize_case)
                         end

          keep = false unless search_match
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:date_filter]&.length == 2
          start_date = opt[:date_filter][0]
          end_date = opt[:date_filter][1]

          in_date_range = if end_date
                            item.date >= start_date && item.date <= end_date
                          else
                            item.date.strftime('%F') == start_date.strftime('%F')
                          end
          keep = false unless in_date_range
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:time_filter][0] || opt[:time_filter][1]
          opt[:time_filter][0] = '00:00' if opt[:time_filter][0] =~ /12 *am/i
          opt[:time_filter][1] = '00:00' if opt[:time_filter][1] =~ /12 *am/i
          start_string = if opt[:time_filter][0].nil?
                           "#{item.date.strftime('%Y-%m-%d')} 00:00"
                         else
                           "#{item.date.strftime('%Y-%m-%d')} #{opt[:time_filter][0]}"
                         end
          start_time = start_string.chronify(guess: :begin)

          end_string = if opt[:time_filter][1].nil?
                         "#{item.date.to_datetime.next_day.strftime('%Y-%m-%d')} 00:00"
                       else
                         "#{item.date.strftime('%Y-%m-%d')} #{opt[:time_filter][1]}"
                       end
          end_time = end_string.chronify(guess: :end) || Time.now

          in_time_range = item.date >= start_time && item.date <= end_time

          keep = false unless in_time_range
          keep = opt[:not] ? !keep : keep
        end

        keep = false if keep && opt[:only_timed] && !item.interval

        if keep && opt[:tag_filter]
          keep = item.tags?(opt[:tag_filter]['tags'], opt[:tag_filter]['bool'])
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:before]
          before = opt[:before]
          cutoff = if before =~ time_rx
                     "#{item.date.strftime('%Y-%m-%d')} #{before}".chronify(guess: :begin)
                   elsif before.is_a?(String)
                     before.chronify(guess: :begin)
                   else
                     before
                   end
          keep = cutoff && item.date <= cutoff
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:after]
          after = opt[:after]
          cutoff = if after =~ time_rx
                     "#{item.date.strftime('%Y-%m-%d')} #{after}".chronify(guess: :end)
                   elsif after.is_a?(String)
                     after.chronify(guess: :end)
                   else
                     after
                   end
          keep = cutoff && item.date >= cutoff
          keep = opt[:not] ? !keep : keep
        end

        if keep && opt[:today]
          keep = item.date >= Date.today.to_time && item.date < Date.today.next_day.to_time
          keep = opt[:not] ? !keep : keep
        elsif keep && opt[:yesterday]
          keep = item.date >= Date.today.prev_day.to_time && item.date < Date.today.to_time
          keep = opt[:not] ? !keep : keep
        end

        keep
      end
      count = opt[:count].to_i&.positive? ? opt[:count].to_i : filtered_items.count

      output = Items.new

      if opt[:age] && opt[:age].normalize_age == :oldest
        output.concat(filtered_items.slice(0, count).reverse)
      else
        output.concat(filtered_items.reverse.slice(0, count))
      end

      logger.benchmark(:filter_items, :finish)

      output
    end
  end
end
