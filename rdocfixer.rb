#!/usr/bin/env ruby

input = $stdin.read

input.gsub!(/\n\n( +)##\n/, "\n\n")
input.gsub!(/## +/, '## ')
input.gsub!(/## @param +(\w+)(?: +(.*?))?$/, '## - +\1+ -- \2')
input.gsub!(/## @returns? +(.*?)$/, '## Returns \1')
input.gsub!(/(?<= )##(?= |\n)/, '#')

puts input


