##
## @brief      Creates Markdown export
##
class MarkdownExport
  attr_accessor :items, :page_title, :totals

  def initialize(page_title, items, totals)
    @page_title = page_title
    @items = items
    @totals = totals
  end

  def get_binding
    binding()
  end
end
