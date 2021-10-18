# frozen_string_literal: true

# title: TaskPaper Export
# description: Export TaskPaper-friendly data
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class TaskPaperExport
    include Doing::Util

    def self.settings
      {
        trigger: 'task(?:paper)?|tp'
      }
    end

    def self.render(wwid, items, variables: {})
      return if items.nil?

      options = variables[:options]

      options[:highlight] = false
      options[:wrap_width] = 0
      options[:tags_color] = false
      options[:output] = 'template'
      options[:template] = '- %title @date(%date)%note'

      @out = wwid.list_section(options)
    end

    Doing::Plugins.register 'taskpaper', :export, self
  end
end
