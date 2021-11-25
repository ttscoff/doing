# frozen_string_literal: true

Doing::Hooks.register :post_write do |filename|
  if ENV['HOOK_TEST']
    puts "Post write hook! #{filename} written."
  end
end

Doing::Hooks.register :post_read do |wwid|
  if ENV['HOOK_TEST']
    total = 0
    wwid.content.each { |s, v| total += v.items.count }
    puts "Post read hook! Read #{total} items."
  end
end
