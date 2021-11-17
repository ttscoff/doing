desc 'Output a tag wiki'
command :wiki do |c|
  c.desc 'Section to rotate'
  c.arg_name 'SECTION_NAME'
  c.flag %i[s section], default_value: 'All'

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

  c.action do |global, options, args|
    wwid = global[:wwid]
    tags = wwid.tag_groups([], opt: options)

    wiki = Doing::Plugins.plugins.dig(:export, 'wiki', :class)

    tags.each do |tag, items|
      export_options = { page_title: tag, is_single: false, options: options }

      raise RuntimeError, 'Missing plugin "wiki"' unless wiki

      out = wiki.render(wwid, items, variables: export_options)

      if out
        FileUtils.mkdir_p('doing_wiki')
        File.open(File.join('doing_wiki', tag + '.html'), 'w') do |f|
          f.puts out
        end
      end
    end

    template = if wwid.config['export_templates']['wiki_index'] && File.exist?(File.expand_path(wwid.config['export_templates']['wiki_index']))
                 IO.read(File.expand_path(wwid.config['export_templates']['wiki_index']))
               else
                 wiki.template('wiki_index')
               end
    style = if wwid.config['export_templates']['wiki_css'] && File.exist?(File.expand_path(wwid.config['export_templates']['wiki_css']))
              IO.read(File.expand_path(wwid.config['export_templates']['wiki_css']))
            else
              wiki.template('wiki_css')
            end
    tags_out = tags.map { |t| {url: "#{t}.html"} }
    engine = Haml::Engine.new(template)
    index_out = engine.render(Object.new,
                       { :@tags => tags.each_with_object([]) { |(tag, items), arr| arr << { name: tag, count: items.count } }, :@page_title => "Tags wiki", :@style => style })

    if index_out
      File.open(File.join('doing_wiki', 'index.html'), 'w') do |f|
        f.puts index_out
      end
      Doing.logger.warn("Wiki written to doing_wiki directory")
    end
  end
end
