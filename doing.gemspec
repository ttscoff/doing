# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','doing','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'doing'
  s.version = Doing::VERSION
  s.author = 'Brett Terpstra'
  s.email = 'me@brettterpstra.com'
  s.homepage = 'http://brettterpstra.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A command line tool for managing What Was I Doing reminders'
# Add your other files here if you make them
  s.files = %w(
bin/doing
lib/doing/version.rb
lib/doing.rb
lib/doing/wwid.rb
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','doing.rdoc']
  s.rdoc_options << '--title' << 'doing' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'doing'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_runtime_dependency('gli','2.7.0')
end
