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

  c.desc 'Import items that *don\'t* match search/tag/date filters'
  c.switch [:not], default_value: false, negatable: false

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

  c.desc 'Allow entries that overlap existing times'
  c.switch [:overlap], negatable: true

  add_options(:search, c)
  add_options(:date_filter, c)

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

    if options[:type] =~ Doing::Plugins.plugin_regex(type: :import)
      options[:no_overlap] = !options[:overlap]
      @wwid.import(args, options)
      @wwid.write(@wwid.doing_file)
    else
      raise InvalidPluginType, "Invalid import type: #{options[:type]}"
    end
  end
end
