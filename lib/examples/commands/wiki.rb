desc 'Output a tag wiki'
command :wiki do |c|
  c.desc 'Section to rotate'
  c.arg_name 'SECTION_NAME'
  c.flag %i[s section], default_value: 'All', multiple: true

  c.desc 'Tag filter, combine multiple tags with a comma, use with --bool'
  c.arg_name 'TAG'
  c.flag [:tag]

  c.desc 'Tag boolean (AND,OR,NOT)'
  c.arg_name 'BOOLEAN'
  c.flag %i[b bool], must_match: REGEX_BOOL, default_value: 'OR'

  c.desc 'Include entries older than date'
  c.arg_name 'DATE_STRING'
  c.flag [:before]

  c.desc 'Include entries newer than date'
  c.arg_name 'DATE_STRING'
  c.flag [:after]

  c.desc 'Search filter, surround with slashes for regex (/query/), start with single quote for exact match ("\'query")'
  c.arg_name 'QUERY'
  c.flag [:search]

  c.desc %(
    Date range to include, or a single day to filter date on.
    Date range argument should be quoted. Date specifications can be natural language.
    To specify a range, use "to" or "through": `doing show --from "monday to friday"`
  )
  c.arg_name 'DATE_OR_RANGE'
  c.flag %i[f from]

  c.desc 'Only show items with recorded time intervals'
  c.switch [:only_timed], default_value: false, negatable: false

  c.action do |_global, options, _args|
    tags = @wwid.tag_groups([], opt: options)

    wiki = Doing::Plugins.plugins.dig(:export, 'wiki', :class)

    tags.each do |tag, items|
      export_options = { page_title: tag, is_single: false, options: options }

      raise 'Missing plugin "wiki"' unless wiki

      out = wiki.render(@wwid, items, variables: export_options)

      if out
        FileUtils.mkdir_p('doing_wiki')
        File.open(File.join('doing_wiki', "#{tag}.html"), 'w') { |f| f.puts out }
      end
    end

    engine = Haml::Engine.new(wiki_template(wiki))
    tag_arr = tags.each_with_object([]) { |(tag, items), arr| arr << { name: tag, count: items.count } }
    index_out = engine.render(Object.new,
                              { :@tags => tag_arr,
                                :@page_title => 'Tags wiki',
                                :@style => wiki_style(wiki) })

    if index_out
      File.open(File.join('doing_wiki', 'index.html'), 'w') do |f|
        f.puts index_out
      end
      Doing.logger.warn('Wiki written to doing_wiki directory')
    end
  end

  def wiki_template(wiki)
    if Doing.setting('export_templates.wiki_index') &&
       File.exist?(File.expand_path(Doing.setting('export_templates.wiki_index')))
      IO.read(File.expand_path(Doing.setting('export_templates.wiki_index')))
    else
      wiki.template('wiki_index')
    end
  end

  def wiki_style(wiki)
    if Doing.setting('export_templates.wiki_css') &&
       File.exist?(File.expand_path(Doing.setting('export_templates.wiki_css')))
      IO.read(File.expand_path(Doing.setting('export_templates.wiki_css')))
    else
      wiki.template('wiki_css')
    end
  end
end
