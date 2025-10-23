#!/usr/bin/env ruby
# frozen_string_literal: true

content = IO.read(ARGV[0])

content.gsub!(/Doing.settings((\[.*?\])+)/) do
  m = Regexp.last_match
  keypath = m[0].scan(/\['([^\]]+)'\]/).map { |e| e[0] }.join('.')
  "Doing.setting('#{keypath}')"
end

puts content
