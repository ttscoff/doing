# @@sections
desc 'List sections'
command :sections do |c|
  c.desc 'List in single column'
  c.switch %i[c column], negatable: false, default_value: false

  c.action do |_global_options, options, _args|
    joiner = options[:column] ? "\n" : "\t"
    print @wwid.content.section_titles.join(joiner)
  end
end
