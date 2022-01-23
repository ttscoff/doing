# @@colors
desc 'List available color variables for configuration templates and views'
command :colors do |c|
  c.action do |_global_options, _options, _args|
    bgs = []
    fgs = []
    @colors::attributes.each do |color|
      if color.to_s =~ /bg/
        bgs.push("#{@colors.send(color, "    ")}#{@colors.default} <-- #{color.to_s}")
      else
        fgs.push("#{@colors.send(color, "XXXX")}#{@colors.default} <-- #{color.to_s}")
      end
    end
    out = []
    out << fgs.join("\n")
    out << bgs.join("\n")
    Doing::Pager.page out.join("\n")
  end
end
