#!/usr/bin/env ruby
# frozen_string_literal: true

current_ver = `git ver`.strip
readme_file = 'README.md'
raise 'README not found' unless File.exist?(readme_file)

readme = IO.read(readme_file).force_encoding('ASCII-8BIT').encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => '?')
readme.sub!(/(?<=\<!--VER-->)(.*?)(?=\<!--END VER-->)/, current_ver)
File.open(readme_file, 'w') { |f| f.puts(readme) }

project_file = '/Users/ttscoff/Sites/dev/bt/source/_projects/doing.md'
raise 'README not found' unless File.exist?(project_file)

contents = readme.dup
jekyll = contents.match(/(?<=\<!--README-->)(.*?)(?=\<!--END README-->)/m)[0]
jekyll.gsub!(/<!--GITHUB-->.*?<!--END GITHUB-->/m, '')
jekyll.gsub!(/<!--JEKYLL(.*?)-->/m, '\1')
project = IO.read(project_file).force_encoding('ASCII-8BIT').encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => '?')
project.sub!(/(?<=\<!--README-->)(.*?)(?=\<!--END README-->)/m, jekyll)
project.sub!(/^updated: \d{4}-\d{2}-\d{2}/, "updated: #{Time.now.strftime('%Y-%m-%d')}")
File.open(project_file, 'w') { |f| f.puts(project) }
