#!/usr/bin/env ruby

require 'tty-spinner'
require 'tty-cursor'
require 'pastel'
require 'fileutils'

pastel = Pastel.new
format = "[#{pastel.yellow(':spinner')}] " + pastel.white("Release Gem")
spinners = TTY::Spinner::Multi.new(format, format: :dots, success_mark: pastel.green('✔'), error_mark: pastel.red('✖'))
sp_v = spinners.register "[#{pastel.cyan(':spinner')}] :msg"
sp_t = spinners.register "[#{pastel.cyan(':spinner')}] Run tests :msg"
sp_c = spinners.register "[#{pastel.cyan(':spinner')}] Generate completions"
sp_d = spinners.register "[#{pastel.cyan(':spinner')}] Generate docs"
sp_w = spinners.register "[#{pastel.cyan(':spinner')}] Update wiki :msg"
spinners.auto_spin

$version = nil
sp_v.update(msg: 'Get version')
sp_t.update(msg: '')
sp_w.update(msg: '')
sp_v.run do |spinner|
  spinner.update(msg: 'Getting version')
  versions = `rake ver`.strip
  version = versions.match(/version\.rb: ([\d.]+(\w+\d*)?)/)[1]
  changelog_version = versions.match(/changelog: ([\d.]+(\w+\d*)?)/)[1]
  git_version = versions.match(/git tag: ([\d.]+(\w+\d*)?)/)[1]

  if git_version == version
    spinner.update(msg: "Error: Git version (#{git_version}) is the same as version.rb (#{version})")
    spinner.error
    spinners.stop
    Process.exit
  end

  unless version == changelog_version
    spinner.update(msg: "Error: version.rb (#{version}) and Changelog (#{changelog_version}) do not match")
    spinner.error
    spinners.stop
    Process.exit
  end

  $version = version

  spinner.update(msg: "Version #{version}")
  spinner.success
end


sp_t.run do |spinner|
  spinner.update(msg: '')
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  unless system('rake parallel:test &> results.log')
    spinner.update(msg: '- Unit tests failed')
    spinner.error
    spinners.stop
    Process.exit
  end

  finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  spinner.update(msg: "- passed in #{(finish - start).round(4)} seconds")
  spinner.success
end

sp_c.auto_spin
`./generate_completions.sh &> results.log`
sp_c.success

sp_d.auto_spin
`bundle exec bin/doing _doc &> results.log`
`./rdoc_to_mmd.rb > /Users/ttscoff/Sites/dev/bt/source/doing_all_commands.md`
`rake yard &> results.log`
sp_d.success


sp_w.run do |spinner|
  spinner.update(msg: '- Updating All Commands')
  `./rdoc_to_mmd.rb > /Users/ttscoff/Desktop/Code/doing.wiki/commands.source`
  prev_dir = Dir.pwd
  Dir.chdir('/Users/ttscoff/Desktop/Code/doing.wiki/')
  `./reformat_commands.rb &> results.log`
  spinner.update(msg: '- Committing and Pushing')
  `git commit -a -m "#{$version} update" &> results.log`
  `git pull &> results.log`
  `FORCE_PUSH=true git push &> results.log`
  spinner.update(msg: '- Tagging Release')
  `git release create -m "v#{$version}" $version &> results.log`
  spinner.update(msg: '- Done')
  Dir.chdir(prev_dir)
  sp_w.success
end

sp_r = spinners.register "[:spinner] Releasing gem :msg"

sp_r.run do |spinner|
  spinner.update(msg: '- Preparing git release')
  `git commit -a -m "#{$version} release prep" &> results.log`
  `git pull &> results.log`
  `FORCE_PUSH=true git push &> results.log`
  spinner.update(msg: '- Running releasegem script')
  `/Users/ttscoff/scripts/releasegem &> results.log`
  spinner.update(msg: '- Bumping gem version')
  `rake bump[patch] &> results.log`
  sp_r.success
end

FileUtils.rm('results.log')
