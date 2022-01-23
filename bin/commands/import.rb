# @@import
desc 'Import entries from an external source'
long_desc "Imports entries from other sources. Available plugins: #{Doing::Plugins.plugin_names(type: :import, separator: ', ')}"
arg_name 'PATH'
command :import do |c|
  c.example 'doing import --type timing "~/Desktop/All Activities.json"', desc: 'Import a Timing.app JSON report'
  c.example 'doing import --type doing --tag imported --no-autotag ~/doing_backup.md', desc: 'Import an Doing archive, tag all entries with @imported, skip autotagging'
  c.example 'doing import --type doing --from "10/1 to 10/15" ~/doing_backup.md', desc: 'Import a Doing archive, only importing entries between two dates'

  c.desc "Import type (#{Doing::Plugins.plugin_names(type: :import)})"
  c.arg_name 'TYPE'
  c.flag :type, default_value: 'doing'

  c.desc 'Only import items matching search. Surround with slashes for regex (/query/), start with single quote for exact match ("\'query")'
  c.arg_name 'QUERY'
  c.flag [:search]

  # c.desc '[DEPRECATED] Use alternative fuzzy matching for search string'
  # c.switch [:fuzzy], default_value: false, negatable: false

  c.desc 'Force exact search string matching (case sensitive)'
  c.switch %i[x exact], default_value: @config.exact_match?, negatable: @config.exact_match?

  c.desc 'Import items that *don\'t* match search/tag/date filters'
  c.switch [:not], default_value: false, negatable: false

  c.desc 'Case sensitivity for search string matching [(c)ase-sensitive, (i)gnore, (s)mart]'
  c.arg_name 'TYPE'
  c.flag [:case], must_match: /^[csi]/, default_value: @settings.dig('search', 'case')

  c.desc 'Only import items with recorded time intervals'
  c.switch [:only_timed], default_value: false, negatable: false

  c.desc 'Target section'
  c.arg_name 'NAME'
  c.flag %i[s section]

  c.desc 'Tag all imported entries'
  c.arg_name 'TAGS'
  c.flag %i[t tag]

  c.desc 'Autotag entries'
  c.switch :autotag, negatable: true, default_value: true

  c.desc 'Prefix entries with'
  c.arg_name 'PREFIX'
  c.flag :prefix

  # TODO: Allow time range filtering
  c.desc 'Import entries older than date'
  c.arg_name 'DATE_STRING'
  c.flag [:before], type: DateBeginString

  c.desc 'Import entries newer than date'
  c.arg_name 'DATE_STRING'
  c.flag [:after], type: DateEndString

  c.desc %(
    Date range to import. Date range argument should be quoted. Date specifications can be natural language.
    To specify a range, use "to" or "through": `--from "monday to friday"` or `--from 10/1 to 10/31`.
    Has no effect unless the import plugin has implemented date range filtering.
  )
  c.arg_name 'DATE_OR_RANGE'
  c.flag %i[f from], type: DateRangeString

  c.desc 'Allow entries that overlap existing times'
  c.switch [:overlap], negatable: true

  c.action do |_global_options, options, args|
    options[:fuzzy] = false
    if options[:section]
      options[:section] = @wwid.guess_section(options[:section]) || options[:section].cap_first
    end

    if options[:search]
      search = options[:search]
      search.sub!(/^'?/, "'") if options[:exact]
      options[:search] = search
    end

    if options[:from]
      options[:date_filter] = options[:from]

      raise InvalidTimeExpression, 'Unrecognized date string' unless options[:date_filter][0]
    elsif options[:before] || options[:after]
      options[:date_filter] = [nil, nil]
      options[:date_filter][1] = options[:before] || Time.now + (1 << 64)
      options[:date_filter][0] = options[:after] || Time.now - (1 << 64)
    end

    options[:case] = options[:case].normalize_case

    if options[:type] =~ Doing::Plugins.plugin_regex(type: :import)
      options[:no_overlap] = !options[:overlap]
      @wwid.import(args, options)
      @wwid.write(@wwid.doing_file)
    else
      raise InvalidPluginType, "Invalid import type: #{options[:type]}"
    end
  end
end
