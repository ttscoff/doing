# frozen_string_literal: true

class TaskPaperExport
  include Doing::Util

  def render(wwid, items, variables: {})
    return if items.nil?

    options = variables[:options]

    options[:highlight] = false
    options[:wrap_width] = 0
    options[:tags_color] = false
    options[:output] = 'template'
    options[:template] = '- %title @date(%date)%note'

    @out = wwid.list_section(options)
  end
end

Doing::Plugins.register_plugin({
  name: 'taskpaper',
  type: :export,
  class: 'TaskPaperExport',
  trigger: 'task(?:paper)?|tp'
})
