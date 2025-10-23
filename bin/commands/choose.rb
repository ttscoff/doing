# frozen_string_literal: true

# @@choose
desc 'Select a section to display from a menu'
command :choose do |c|
  c.action do |_global_options, _options, _args|
    section = @wwid.choose_section

    Doing::Pager.page @wwid.list_section({ section: section.cap_first, count: 0 }) if section
  end
end
