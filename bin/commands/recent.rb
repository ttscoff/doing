# @@recent
desc 'List recent entries'
default_value 10
arg_name 'COUNT'
command :recent do |c|
  c.example 'doing recent', desc: 'Show the 10 most recent entries across all sections'
  c.example 'doing recent 20', desc: 'Show the 20 most recent entries across all sections'
  c.example 'doing recent --section Currently 20', desc: 'List the 20 most recent entries from the Currently section'
  c.example 'doing recent --interactive 20', desc: 'Create a menu from the 20 most recent entries to perform batch actions on'

  c.desc 'Section'
  c.arg_name 'NAME'
  c.flag %i[s section], default_value: 'All'

  c.desc 'Show time intervals on @done tasks'
  c.switch %i[t times], default_value: true, negatable: true

  c.desc "Output using a template from configuration"
  c.arg_name 'TEMPLATE_KEY'
  c.flag [:config_template], type: TemplateName, default_value: 'recent'

  c.desc 'Override output format with a template string containing %placeholders'
  c.arg_name 'TEMPLATE_STRING'
  c.flag [:template]

  c.desc 'Show elapsed time on entries without @done tag'
  c.switch [:duration]

  c.desc 'Show intervals with totals at the end of output'
  c.switch [:totals], default_value: false, negatable: false

  c.desc 'Sort tags by (name|time)'
  default = @settings['tag_sort'].normalize_tag_sort || :name
  c.arg_name 'KEY'
  c.flag [:tag_sort], must_match: REGEX_TAG_SORT, default_value: default, type: TagSortSymbol

  c.desc 'Select from a menu of matching entries to perform additional operations'
  c.switch %i[i interactive], negatable: false, default_value: false

  c.action do |global_options, options, args|
    section = @wwid.guess_section(options[:section]) || options[:section].cap_first

    unless global_options[:version]
      if @settings['templates']['recent'].key?('count')
        config_count = @settings['templates']['recent']['count'].to_i
      else
        config_count = 10
      end

      if options[:interactive]
        count = 0
      else
        count = args.empty? ? config_count : args[0].to_i
      end

      options[:times] = true if options[:totals]
      options[:sort_tags] = options[:tag_sort]

      template = @settings['templates']['recent'].deep_merge(@settings['templates']['default'])
      tags_color = template.key?('tags_color') ? template['tags_color'] : nil

      opts = {
        sort_tags: options[:sort_tags],
        tags_color: tags_color,
        times: options[:times],
        totals: options[:totals],
        interactive: options[:interactive],
        duration: options[:duration],
        config_template: options[:config_template],
        template: options[:template]
      }

      Doing::Pager::page @wwid.recent(count, section.cap_first, opts)

    end
  end
end
