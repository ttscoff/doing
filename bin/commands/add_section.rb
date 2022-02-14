# frozen_string_literal: true

# @@add_section
desc 'Add a new section to the "doing" file'
arg_name 'SECTION_NAME'
command :add_section do |c|
  c.example 'doing add_section Ideas', desc: 'Add a section called Ideas to the doing file'

  c.action do |_global_options, _options, args|
    raise InvalidArgument, "Section #{args[0]} already exists" if @wwid.sections.include?(args[0])

    @wwid.content.add_section(args.join(' ').cap_first, log: true)
    @wwid.write(@wwid.doing_file)
  end
end
