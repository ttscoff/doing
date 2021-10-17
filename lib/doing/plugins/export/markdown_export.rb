$wwid.register_plugin({
  name: 'markdown',
  type: :export,
  class: 'MarkdownExport',
  trigger: 'markdown|md|gfm',
  config: {
    'html_template' => { 'markdown' => nil }
  }
})

class MarkdownRenderer
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

class MarkdownExport
  include Util

  def render(items, variables: {})
    return if items.nil?

    opt = variables[:options]

    all_items = []
    items.each do |i|
      if String.method_defined? :force_encoding
        title = i['title'].force_encoding('utf-8').link_urls({format: :markdown})
        note = i['note'].map { |line| line.force_encoding('utf-8').strip.link_urls({format: :markdown}) } if i['note']
      else
        title = i['title'].link_urls({format: :markdown})
        note = i['note'].map { |line| line.strip.link_urls({format: :markdown}) } if i['note']
      end

      title = "#{title} @project(#{i['section']})" unless variables[:is_single]

      interval = get_interval(i, record: false) if i['title'] =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/ && opt[:times]
      interval ||= false

      done = i['title'] =~ /(?<= |^)@done/ ? 'x' : ' '

      all_items << {
        date: i['date'].strftime('%a %-I:%M%p'),
        shortdate: i['date'].relative_date,
        done: done,
        note: note,
        section: i['section'],
        time: interval,
        title: title.strip
      }
    end

    template = if $wwid.config['html_template']['markdown'] && File.exist?(File.expand_path($wwid.config['html_template']['markdown']))
                 IO.read(File.expand_path($wwid.config['html_template']['markdown']))
               else
                 $wwid.markdown_template
               end

    totals = opt[:totals] ? $wwid.tag_times(format: :markdown, sort_by_name: opt[:sort_tags], sort_order: opt[:tag_order]) : ''

    mdx = MarkdownRenderer.new(variables[:page_title], all_items, totals)
    engine = ERB.new(template)
    @out = engine.result(mdx.get_binding)
  end
end
