# frozen_string_literal: true

# @@colors
desc 'List available color variables for configuration templates and views'
command :colors do |c|
  c.action do |_global_options, _options, _args|
    bgs = []
    fgs = []
    @colors.attributes.each do |color|
      colname = color.to_s
      colname << " (#{color.to_s.sub(/bold/, 'bright')})" if colname =~ /bold/
      if color.to_s =~ /bg/
        bgs.push("#{@colors.send(color, '    ')}#{@colors.default} <-- #{colname}")
      else
        fgs.push("#{@colors.send(color, 'XXXX')}#{@colors.default} <-- #{colname}")
      end
    end
    out = []
    out << fgs.join("\n")
    out << bgs.join("\n")
    Doing::Pager.page out.join("\n")
  end
end
