# frozen_string_literal: true

Doing::Hooks.register :post_write do |filename|
  puts "Post write hook! #{filename} written." if ENV['HOOK_TEST']
end

Doing::Hooks.register :post_read do |wwid|
  if ENV['HOOK_TEST']
    total = 0
    wwid.content.sections.each { |section| total += wwid.content.in_section(section.title).count }
    puts "Post read hook! Read #{total} items."
  end
end
