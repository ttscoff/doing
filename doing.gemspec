# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','doing','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'doing'
  s.version = Doing::VERSION
  s.author = 'Brett Terpstra'
  s.email = 'me@brettterpstra.com'
  s.homepage = 'http://brettterpstra.com/project/doing/'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A command line tool for managing What Was I Doing reminders'
  s.description = 'A tool for managing a TaskPaper-like file of recent activites. Perfect for the late-night hacker on too much caffeine to remember what they accomplished at 2 in the morning.'
  s.license = 'MIT'
# Add your other files here if you make them
  s.files = Dir.chdir(File.expand_path('..', __FILE__)) do
      `git ls-files -z`.split("\x0").reject { |f|
          f.strip =~ /^((test|spec|features)\/|\.git|buildnotes)/
      }
  end
  s.require_paths << 'lib'

  s.extra_rdoc_files = ['README.md']
  s.rdoc_options << '--title' << 'doing' << '--main' << 'README.md' << '--markup' << 'markdown'
  s.bindir = 'bin'
  s.executables << 'doing'
  s.add_runtime_dependency('safe_yaml', '~> 1.0')
  s.add_development_dependency 'rake', '~> 13.0', '>= 13.0.1'
  s.add_development_dependency 'rdoc', '~> 6.3.1'
  s.add_development_dependency 'aruba', '~> 1.0.2'
  s.add_development_dependency 'test-unit', '~> 3.4.4'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'github-markup'
  s.add_runtime_dependency('gli', '~> 2.19', '>= 2.19.2')
  s.add_runtime_dependency('haml','~>5.0.0', '>= 5.0.0')
  s.add_runtime_dependency('chronic','~> 0.10', '>= 0.10.2')
  s.add_runtime_dependency 'deep_merge', '~> 1.2', '>= 1.2.1'


end
