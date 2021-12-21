require 'rake/clean'
require 'rubygems'
require 'rubygems/package_task'
require 'rdoc'
require 'rdoc/task'
require 'rake/testtask'
require 'open3'
require 'yard'
require 'parallel_tests'
require 'parallel_tests/tasks'

YARD::Rake::YardocTask.new do |t|
 t.files = ['lib/doing/*.rb']
 t.options = ['--markup-provider=redcarpet', '--markup=markdown', '--no-private', '-p', 'yard_templates']
 # t.stats_options = ['--list-undoc']
end

task :doc, [*Rake.application[:yard].arg_names] => [:yard]

Rake::RDocTask.new do |rd|
  rd.main = 'README.md'
  rd.rdoc_files.include('README.md', 'lib/**/*.rb', 'bin/**/*')
  rd.title = 'doing'
  rd.markup = 'markdown'
end

spec = eval(File.read('doing.gemspec'))

Gem::PackageTask.new(spec) do |pkg|
end

# Rake::TestTask.new do |t|
#   t.libs << ['test', 'test/helpers']
#   t.test_files = FileList['test/*_test.rb']
#   t.verbose = ENV['VERBOSE'] =~ /(true|1)/i ? true : false
# end

namespace :test do

  FileList['test/*_test.rb'].each do |rakefile|
    test_name = File.basename(rakefile, '.rb').sub(/^.*?_(.*?)_.*?$/, '\1')

    Rake::TestTask.new(:"#{test_name}") do |t|
      t.libs << ['test', 'test/helpers']
      t.pattern = rakefile
      t.verbose = ENV['VERBOSE'] =~ /(true|1)/i ? true : false
    end
    # Define default task for :test
    task default: test_name
  end
end

desc 'Run tests in Docker'
task :dockertest, :version do |_, args|
  args.with_defaults(version: '2.7')
  file = case args[:version]
         when /^3/
          'Dockerfile-3.0'
        when /6$/
          'Dockerfile-2.6'
        when /7$/
          'Dockerfile-2.7'
        else
          'Dockerfile'
        end
  `docker build --file #{file} . -t doingtest`
  `docker run -it doingtest`
end

desc 'Run all tests'
task test: 'test:default'

desc 'Run one test verbosely'
task :test_one, :test do |_, args|
  args.with_defaults(test: '*')
  puts `bundle exec rake test TESTOPTS="-v" TEST="test/doing_#{args[:test]}_test.rb"`
end

desc 'Install the gem in the current ruby'
task :install, :all do |_t, args|
  args.with_defaults(all: false)
  if args[:all]
    sh 'rvm all do gem install pkg/*.gem'
    sh 'sudo gem install pkg/*.gem'
  else
    sh 'gem install pkg/*.gem'
  end
end

desc 'Development version check'
task :ver do
  gver = `git ver`
  cver = IO.read(File.join(File.dirname(__FILE__), 'CHANGELOG.md')).match(/^#+ (\d+\.\d+\.\d+(\w+)?)/)[1]
  res = `grep VERSION lib/doing/version.rb`
  version = res.match(/VERSION *= *['"](\d+\.\d+\.\d+(\w+)?)/)[1]
  puts "git tag: #{gver}"
  puts "version.rb: #{version}"
  puts "changelog: #{cver}"
end

desc 'Changelog version check'
task :cver do
  puts IO.read(File.join(File.dirname(__FILE__), 'CHANGELOG.md')).match(/^#+ (\d+\.\d+\.\d+(\w+)?)/)[1]
end

desc 'Bump incremental version number'
task :bump, :type do |_, args|
  args.with_defaults(type: 'inc')
  version_file = 'lib/doing/version.rb'
  content = IO.read(version_file)
  content.sub!(/VERSION = '(?<major>\d+)\.(?<minor>\d+)\.(?<inc>\d+)(?<pre>\S+)?'/) do
    m = Regexp.last_match
    major = m['major'].to_i
    minor = m['minor'].to_i
    inc = m['inc'].to_i
    pre = m['pre']

    case args[:type]
    when /^maj/
      major += 1
      minor = 0
      inc = 0
    when /^min/
      minor += 1
      inc = 0
    else
      inc += 1
    end

    $stdout.puts "At version #{major}.#{minor}.#{inc}#{pre}"
    "VERSION = '#{major}.#{minor}.#{inc}#{pre}'"
  end
  File.open(version_file, 'w+') { |f| f.puts content }
end

task default: %i[clobber yard package]
