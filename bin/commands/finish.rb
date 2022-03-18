# frozen_string_literal: true

# @@finish
module Doing
  # finish command methods
  class FinishCommand
    def initialize(wwid)
      @wwid = wwid
    end

    def add_examples(cmd)
      cmd.example 'doing finish', desc: 'Mark the last entry @done'
      cmd.example 'doing finish --auto --section Later 10', desc: 'Add @done to any unfinished entries in the last 10 in Later, setting the finish time based on the start time of the task after it'
      cmd.example 'doing finish --search "a specific entry" --at "yesterday 3pm"', desc: 'Search for an entry containing string and set its @done time to yesterday at 3pm'
    end

    def add_options(cmd)
      cmd.desc 'Include date'
      cmd.switch [:date], negatable: true, default_value: true

      cmd.desc 'Backdate completed date to date string [4pm|20m|2h|yesterday noon]'
      cmd.arg_name 'DATE_STRING'
      cmd.flag %i[b back started], type: DateBeginString

      cmd.desc 'Overwrite existing @done tag with new date'
      cmd.switch %i[update], negatable: false, default_value: false

      cmd.desc 'Remove @done tag'
      cmd.switch %i[r remove], negatable: false, default_value: false

      cmd.desc 'Finish last entry (or entries) not already marked @done'
      cmd.switch %i[u unfinished], negatable: false, default_value: false

      cmd.desc %(Auto-generate finish dates from next entry's start time.
      Automatically generate completion dates 1 minute before next item (in any section) began.
      --auto overrides the --date and --back parameters.)
      cmd.switch [:auto], negatable: false, default_value: false

      cmd.desc 'Archive entries'
      cmd.switch %i[a archive], negatable: false, default_value: false

      cmd.desc 'Section'
      cmd.arg_name 'NAME'
      cmd.flag %i[s section]

      cmd.desc 'Select item(s) to finish from a menu of matching entries'
      cmd.switch %i[i interactive], negatable: false, default_value: false
    end

    def handle_from(options)
      options[:from] = options[:from].split(/#{REGEX_RANGE_INDICATOR}/).map do |time|
        time =~ REGEX_TIME ? "today #{time.sub(/(?mi)(^.*?(?=\d+)|(?<=[ap]m).*?$)/, '')}" : time
      end.join(' to ').split_date_range
      start_date, finish_date = options[:from]
      finish_date ||= Time.now
      [start_date, finish_date]
    end

    def handle_date_options(options)
      if options[:took]
        took = options[:took]
        raise InvalidTimeExpression, 'Unable to parse date string for --took' if took.nil?

      end

      if options[:at]
        finish_date = options[:at]
        finish_date = finish_date.chronify(guess: :begin) if finish_date.is_a? String
        raise InvalidTimeExpression, 'Unable to parse date string for --at' if finish_date.nil?

        start_date = options[:took] ? finish_date - took : nil
      elsif options[:back]
        start_date = options[:back]
        finish_date = options[:took] ? start_date + took : Time.now

        raise InvalidTimeExpression, 'Unable to parse date string' if start_date.nil?

      else
        start_date = options[:took] ? Time.now - took : nil
        finish_date = Time.now
      end

      [start_date, finish_date]
    end
  end
end

desc 'Mark last X entries as @done'
long_desc 'Marks the last X entries with a @done tag and current date. Does not alter already completed entries.'
arg_name 'COUNT', optional: true
command :finish do |c|
  cmd = Doing::FinishCommand.new(@wwid)
  cmd.add_examples(c)
  cmd.add_options(c)
  add_options(:search, c)
  add_options(:tag_filter, c)
  add_options(:finish_entry, c)

  c.action do |_global_options, options, args|
    options[:fuzzy] = false
    unless options[:auto]
      if options[:from]
        start_date, finish_date = cmd.handle_from(options)
      else
        start_date, finish_date = cmd.handle_date_options(options)
      end
    end

    tags = options[:tag] || []

    raise InvalidArgument, 'Only one argument allowed' if args.length > 1

    unless args.empty? || args[0] =~ /\d+/
      raise InvalidArgument, 'Invalid argument (specify number of recent items to mark @done)'

    end

    count = if options[:interactive]
              0
            else
              args[0] ? args[0].to_i : 1
            end

    search = nil

    if options[:search]
      search = options[:search]
      search.sub!(/^'?/, "'") if options[:exact]
    end

    opts = {
      archive: options[:archive],
      back: start_date,
      case: options[:case].normalize_case,
      count: count,
      date: options[:date],
      done_date: finish_date,
      fuzzy: options[:fuzzy],
      interactive: options[:interactive],
      not: options[:not],
      remove: options[:remove],
      search: search,
      section: options[:section],
      sequential: options[:auto],
      start_date: start_date,
      tag: tags,
      tag_bool: options[:bool].normalize_bool,
      tags: ['done'],
      took: options[:took],
      unfinished: options[:unfinished],
      update: options[:update],
      val: options[:val]
    }

    @wwid.tag_last(opts)
  end
end
