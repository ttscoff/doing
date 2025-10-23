# frozen_string_literal: true

# @@template
desc 'Output HTML, CSS, and Markdown (ERB) templates for customization'
long_desc %(
  Templates are printed to STDOUT for piping to a file.
  Save them and use them in the configuration file under export_templates.
)
arg_name 'TYPE', must_match: Doing::Plugins.template_regex
command :template do |c|
  c.example 'doing template haml > ~/styles/my_doing.haml', desc: 'Output the haml template and save it to a file'

  c.desc 'List all available templates'
  c.switch %i[l list], negatable: false

  c.desc 'List in single column for completion'
  c.switch %i[c column]

  c.desc 'Save template to file instead of STDOUT'
  c.switch %i[s save], default_value: false, negatable: false

  c.desc 'Save template to alternate location'
  c.arg_name 'DIRECTORY'
  c.flag %i[p path], default_value: File.join(Doing::Util.user_home, '.config', 'doing', 'templates')

  c.action do |_global_options, options, args|
    if options[:list] || options[:column]
      if options[:column]
        $stdout.print Doing::Plugins.plugin_templates.join("\n")
      else
        $stdout.puts "Available templates: #{Doing::Plugins.plugin_templates.join(', ')}"
      end
    else

      if args.empty?
        type = Doing::Prompt.choose_from(Doing::Plugins.plugin_templates, sorted: false,
                                                                          prompt: 'Select template type > ')
        type.sub!(/ \(.*?\)$/, '').strip!
        options[:save] = Doing::Prompt.yn("Save to #{options[:path]}? (No outputs to STDOUT)", default_response: false)
      else
        type = args[0]
      end

      unless type
        raise InvalidPluginType,
              "No type specified, use `doing template [#{Doing::Plugins.plugin_templates.join('|')}]`"
      end

      if options[:save]
        Doing::Plugins.template_for_trigger(type, save_to: options[:path])
      else
        $stdout.puts Doing::Plugins.template_for_trigger(type, save_to: nil)
      end
    end
  end
end
