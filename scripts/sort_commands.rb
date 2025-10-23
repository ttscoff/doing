#!/usr/bin/env ruby
# frozen_string_literal: true

require 'awesome_print'

input = $stdin.read.force_encoding('utf-8')

commands = input.split(/^# @@/).delete_if(&:empty?).sort
# commands.each do |cmd|
#   puts cmd.split(/^(\w+)(.*)$/m)[1]
# end
indexes = %w[
  again
  cancel
  done
  finish
  later
  mark
  meanwhile
  note
  now
  reset
  select
  tag
  choose
  grep
  last
  recent
  show
  tags
  today
  view
  yesterday
  open
  config
  archive
  import
  rotate
  colors
  completion
  plugins
  sections
  template
  views
  undo
  redo
  add_section
  tag_dir
  changelog
]

result = Array.new(indexes.count)

commands.each do |cmd|
  key = cmd.match(/^(\w+)/)[1]
  idx = indexes.index(key)
  result[idx] = "#@@#{cmd}"
  # puts commands.join('# @@')
end

puts result.join('')
