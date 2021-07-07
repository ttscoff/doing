#!/usr/bin/env ruby
# frozen_string_literal: true

input = IO.read('doing.rdoc')

input.gsub!(/^===== Options/, "##### Options\n\n")
input.gsub!(/^=== Commands/, "## Commands\n")
input.gsub!(/(?<=\n)===== (.*?)\n+((.|\n)+?)(?=\n=|$)/s) do
  m = Regexp.last_match
  "`#{m[1]}`\n: #{m[2].gsub(/\|/, '\\|')}"
end
input.gsub!(/^==== Command: <tt>(.*?) ( .*?)?<\/tt>\n(.*?)$/) do
  m = Regexp.last_match
  r = "### #{m[1].sub(/\|(.*?)$/, ' (*or* \1)')}"
  r += " #{m[2]}" if m[2]
  r += " {##{m[1].gsub(/\|.*?$/, '')}}\n\n"
  "#{r}**#{m[3]}**{:.description}\n"
end

input.gsub!(/^=== Global Options/, "## Global Options\n")
input.gsub!(/^=== (.*?)\n+(.*?)$/) do
  m = Regexp.last_match
  "`#{m[1]}`\n: #{m[2].gsub(/\|/, '\\|')}"
end
input.gsub!(/^== (.*?) - (.*?)$\n\n(.*?)$/, "**\\1: \\2**\n\n*\\3*\n\n## Table of Contents\n{:.no_toc}\n\n* Table of Contents\n{:toc}")
input.gsub!(/^\[(Default Value|Must Match)\] (.*?)$/, ': *\1:* `\2`')
input.gsub!(/\n  (?=\S)/, ' ')
input.gsub!(/^([^:`\n#*](.*?))$/, "\\1\n")
input.gsub!(/\n{3,}/, "\n\n")
input.gsub!(/^(: .*?)\n\n(:.*?)$/, "\\1\n\\2")
input.gsub!(/^\[Default Command\] (.*?)$/, '## Default Command: [`\1`](#\1)')
puts %(---
layout: page
title: "Doing - All Commands"
comments: false
footer: true
body_id: doingcommands
---
)
puts input
