# frozen_string_literal: true

module Doing
  class WWID
    # Display methods for WWID class
    module Display
      ##
      ## Display contents of a section based on options
      ##
      ## @param      opt   [Hash] Additional Options
      ##
      def list_section(opt, items: Items.new)
        logger.benchmark(:list_section, :start)
        opt[:config_template] ||= 'default'

        tpl_cfg = Doing.setting(['templates', opt[:config_template]])

        cfg = if opt[:view_template]
                Doing.setting(['views', opt[:view_template]]).deep_merge(tpl_cfg, { extend_existing_arrays: true, sort_merged_arrays: true })
              else
                tpl_cfg
              end

        cfg.deep_merge({
                         'wrap_width' => Doing.setting('wrap_width') || 0,
                         'date_format' => Doing.setting('default_date_format'),
                         'order' => Doing.setting('order') || :asc,
                         'tags_color' => Doing.setting('tags_color'),
                         'duration' => Doing.setting('duration'),
                         'interval_format' => Doing.setting('interval_format')
                       }, { extend_existing_arrays: true, sort_merged_arrays: true })

        opt[:duration] ||= cfg['duration'] || false
        opt[:interval_format] ||= cfg['interval_format'] || 'text'
        opt[:count] ||= 0
        opt[:age] ||= :newest
        opt[:age] = opt[:age].normalize_age
        opt[:format] ||= cfg['date_format']
        opt[:order] ||= cfg['order'] || :asc
        opt[:tag_order] ||= :asc
        opt[:tags_color] = cfg['tags_color'] || false if opt[:tags_color].nil?
        opt[:template] ||= cfg['template']
        opt[:sort_tags] ||= opt[:tag_sort]

        # opt[:highlight] ||= true
        title = ''
        is_single = true
        if opt[:section].nil?
          opt[:section] = choose_section
          title = opt[:section]
        elsif opt[:section].instance_of?(String)
          title = if opt[:section] =~ /^all$/i
                    if opt[:page_title]
                      opt[:page_title]
                    elsif opt[:tag_filter] && opt[:tag_filter]['bool'].normalize_bool != :not
                      opt[:tag_filter]['tags'].map { |tag| "@#{tag}" }.join(' + ')
                    else
                      'doing'
                    end
                  else
                    guess_section(opt[:section])
                  end
        end

        items = filter_items(items, opt: opt)

        items.reverse! unless opt[:order].normalize_order == :desc

        if opt[:delete]
          delete_items(items, force: opt[:force])

          write(@doing_file)
          return
        elsif opt[:editor]
          edit_items(items)

          write(@doing_file)
          return
        elsif opt[:interactive]
          opt[:menu] = !opt[:force]
          opt[:query] = '' # opt[:search]
          opt[:multiple] = true
          selected = Prompt.choose_from_items(items.reverse, include_section: opt[:section] =~ /^all$/i, **opt)

          raise NoResults, 'no items selected' if selected.nil? || selected.empty?

          act_on(selected, opt)
          return
        end

        opt[:output] ||= 'template'
        opt[:wrap_width] ||= Doing.setting('templates.default.wrap_width', 0)

        logger.benchmark(:list_section, :finish)
        output(items, title, is_single, opt)
      end

      ##
      ## Display entries within a date range
      ##
      ## @param      dates    [Array] [start, end]
      ## @param      section  [String] The section
      ## @param      times    (Bool) Show times
      ## @param      output   [String] Output format
      ## @param      opt      [Hash] Additional Options
      ##
      def list_date(dates, section, times = nil, output = nil, opt)
        opt ||= {}
        opt[:totals] ||= false
        opt[:sort_tags] ||= false
        section = guess_section(section)
        # :date_filter expects an array with start and end date
        dates = dates.split_date_range if dates.instance_of?(String)

        opt[:section] = section
        opt[:count] = 0
        opt[:order] = :asc
        opt[:date_filter] = dates
        opt[:times] = times
        opt[:output] = output

        time_rx = /^(\d{1,2}+(:\d{1,2}+)?( *(am|pm))?|midnight|noon)$/
        if opt[:from] && opt[:from][0].is_a?(String) && opt[:from][0] =~ time_rx
          opt[:time_filter] = opt[:from]
        end

        list_section(opt)
      end

      ##
      ## Show all entries from the current day
      ##
      ## @param      times   [Boolean] show times
      ## @param      output  [String] output format
      ## @param      opt     [Hash] Options
      ##
      def today(times = true, output = nil, opt)
        opt ||= {}
        opt[:totals] ||= false
        opt[:sort_tags] ||= false

        cfg = Doing.setting('templates').deep_merge(Doing.setting('templates.default'), { extend_existing_arrays: true, sort_merged_arrays: true }).deep_merge({
          'wrap_width' => Doing.setting('wrap_width') || 0,
          'date_format' => Doing.setting('default_date_format'),
          'order' => Doing.setting('order') || :asc,
          'tags_color' => Doing.setting('tags_color'),
          'duration' => Doing.setting('duration'),
          'interval_format' => Doing.setting('interval_format')
        }, { extend_existing_arrays: true, sort_merged_arrays: true })

        template = opt[:template] || cfg['template']

        opt[:duration] ||= cfg['duration'] || false
        opt[:interval_format] ||= cfg['interval_format'] || 'text'

        options = {
          after: opt[:after],
          before: opt[:before],
          count: 0,
          duration: opt[:duration],
          from: opt[:from],
          format: cfg['date_format'],
          interval_format: opt[:interval_format],
          only_timed: opt[:only_timed],
          order: cfg['order'] || :asc,
          output: output,
          section: opt[:section],
          sort_tags: opt[:sort_tags],
          template: template,
          times: times,
          today: true,
          totals: opt[:totals],
          wrap_width: cfg['wrap_width'],
          tags_color: cfg['tags_color'],
          config_template: opt[:config_template]
        }
        list_section(options)
      end

      ##
      ## Show entries from the previous day
      ##
      ## @param      section  [String] The section
      ## @param      times    (Bool) Show times
      ## @param      output   [String] Output format
      ## @param      opt      [Hash] Additional Options
      ##
      def yesterday(section, times = nil, output = nil, opt)
        opt ||= {}
        opt[:totals] ||= false
        opt[:sort_tags] ||= false
        opt[:config_template] ||= 'today'
        opt[:yesterday] = true

        section = guess_section(section)
        y = (Time.now - (60 * 60 * 24)).strftime('%Y-%m-%d')
        opt[:after] = "#{y} #{opt[:after]}" if opt[:after]
        opt[:before] = "#{y} #{opt[:before]}" if opt[:before]

        opt[:output] = output
        opt[:section] = section
        opt[:times] = times
        opt[:count] = 0

        list_section(opt)
      end

      ##
      ## Show recent entries
      ##
      ## @param      count    [Integer] The number to show
      ## @param      section  [String] The section to show from, default Currently
      ## @param      opt      [Hash] Additional Options
      ##
      def recent(count = 10, section = nil, opt)
        opt ||= {}
        times = opt[:t] || true
        opt[:totals] ||= false
        opt[:sort_tags] ||= false

        cfg = Doing.setting('templates.recent').deep_merge(Doing.setting('templates.default'), { extend_existing_arrays: true, sort_merged_arrays: true }).deep_merge({
          'wrap_width' => Doing.setting('wrap_width') || 0,
          'date_format' => Doing.setting('default_date_format'),
          'order' => Doing.setting('order') || :asc,
          'tags_color' => Doing.setting('tags_color'),
          'duration' => Doing.setting('duration'),
          'interval_format' => Doing.setting('interval_format')
        }, { extend_existing_arrays: true, sort_merged_arrays: true })
        opt[:duration] ||= cfg['duration'] || false
        opt[:interval_format] ||= cfg['interval_format'] || 'text'

        section ||= Doing.setting('current_section')
        section = guess_section(section)

        opt[:section] = section
        opt[:wrap_width] = cfg['wrap_width']
        opt[:count] = count
        opt[:format] = cfg['date_format']
        opt[:template] = opt[:template] || cfg['template']
        opt[:order] = :asc
        opt[:times] = times

        list_section(opt)
      end

      ##
      ## Show the last entry
      ##
      ## @param      times    (Bool) Show times
      ## @param      section  [String] Section to pull from, default Currently
      ##
      def last(times: true, section: nil, options: {})
        section = section.nil? || section =~ /all/i ? 'All' : guess_section(section)
        cfg = Doing.setting(['templates', options[:config_template]]).deep_merge(Doing.setting('templates.default'), { extend_existing_arrays: true, sort_merged_arrays: true }).deep_merge({
          'wrap_width' => Doing.setting('wrap_width', 0),
          'date_format' => Doing.setting('default_date_format'),
          'order' => Doing.setting('order', :asc),
          'tags_color' => Doing.setting('tags_color'),
          'duration' => Doing.setting('duration'),
          'interval_format' => Doing.setting('interval_format')
        }, { extend_existing_arrays: true, sort_merged_arrays: true })
        options[:duration] ||= cfg['duration'] || false
        options[:interval_format] ||= cfg['interval_format'] || 'text'

        opts = {
          case: options[:case],
          config_template: options[:config_template] || 'last',
          count: 1,
          delete: options[:delete],
          duration: options[:duration],
          format: cfg['date_format'],
          interval_format: options[:interval_format],
          not: options[:negate],
          output: options[:output],
          section: section,
          template: options[:template] || cfg['template'],
          times: times,
          val: options[:val],
          wrap_width: cfg['wrap_width']
        }

        if options[:tag]
          opts[:tag_filter] = {
            'tags' => options[:tag],
            'bool' => options[:tag_bool]
          }
        end

        opts[:search] = options[:search] if options[:search]

        list_section(opts)
      end

      ##
      ## Return the content of the last note for a given section
      ##
      ## @param      section  [String] The section to retrieve from, default
      ##                      All
      ##
      def last_note(section = 'All')
        section = guess_section(section)

        last_item = last_entry({ section: section })

        raise NoEntryError, 'No entry found' unless last_item

        logger.log_now(:info, 'Edit note:', last_item.title)

        note = last_item.note&.to_s || ''
        "#{last_item.title}\n# EDIT BELOW THIS LINE ------------\n#{note}"
      end

      ##
      ## Get the last entry
      ##
      ## @param      opt   [Hash] Additional Options
      ##
      def last_entry(opt)
        opt ||= {}
        opt[:tag_bool] ||= :and
        opt[:section] ||= Doing.setting('current_section')

        items = filter_items(Items.new, opt: opt)

        logger.debug('Filtered:', "Parameters matched #{items.count} entries")

        if opt[:interactive]
          last_entry = Prompt.choose_from_items(items, include_section: opt[:section] =~ /^all$/i,
            menu: true,
            header: '',
            prompt: 'Select an entry > ',
            multiple: false,
            sort: false,
            show_if_single: true
           )
        else
          last_entry = items.max_by { |item| item.date }
        end

        last_entry
      end

      private

      ##
      ## Generate output using available export plugins
      ##
      ## @param      items      [Array] The items
      ## @param      title      [String] Page title
      ## @param      is_single  [Boolean] Indicates if single
      ##                        section
      ## @param      opt        [Hash] Additional options
      ##
      ## @return     [String] formatted output based on opt[:output]
      ##             template trigger
      ## @api private
      def output(items, title, is_single, opt)
        logger.benchmark(:output, :start)
        opt ||= {}
        out = nil

        raise InvalidArgument, 'Unknown output format' unless opt[:output] =~ Plugins.plugin_regex(type: :export)

        export_options = { page_title: title, is_single: is_single, options: opt }

        Hooks.trigger :pre_export, self, opt[:output], items

        Plugins.plugins[:export].each do |_, options|
          next unless opt[:output] =~ /^(#{options[:trigger].normalize_trigger})$/i

          out = options[:class].render(self, items, variables: export_options)
          break
        end

        logger.debug('Output:', "#{items.count} #{items.count == 1 ? 'item' : 'items'} shown")
        logger.benchmark(:output, :finish)
        out
      end

      ##
      ## Get next item in the index
      ##
      ## @param      item     [Item] target item
      ## @param      options  [Hash] additional options
      ## @see #filter_items
      ##
      ## @return     [Item] the next chronological item in the index
      ##
      def next_item(item, options = {})
        options ||= {}
        items = filter_items(Items.new, opt: options)

        idx = items.index(item)

        idx.positive? ? items[idx - 1] : nil
      end
    end
  end
end
