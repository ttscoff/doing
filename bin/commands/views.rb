# @@views
desc 'List available custom views'
command :views do |c|
  c.desc 'List in single column'
  c.switch %i[c column], default_value: false

  c.action do |_global_options, options, _args|
    joiner = options[:column] ? "\n" : "\t"
    print @wwid.views.join(joiner)
  end
end
