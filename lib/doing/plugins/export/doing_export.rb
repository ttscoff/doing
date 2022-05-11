# frozen_string_literal: true

# title: Doing File Export
# description: Export Doing format data
# author: Brett Terpstra
# url: https://brettterpstra.com
module Doing
  class DoingExport
    def self.settings
      {
        trigger: 'doing'
      }
    end

    def self.render(wwid, items, variables: {})
      return if items.nil?

      content = Doing::Items.new
      items.each do |item|
        content.add_section(item.section, log: false)
        content.push(item)
      end

      out = []
      content.sections.each do |section|
        out.push(section.original)
        is = content.in_section(section.title).sort_by { |i| [i.date, i.title] }
        is.reverse! if Doing.setting('doing_file_sort').normalize_order == :desc
        is.each { |item| out.push(item.to_s) }
      end

      Doing::Pager.page out.join("\n")
    end

    Doing::Plugins.register 'doing', :export, self
  end
end
