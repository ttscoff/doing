# Ensure we require the local version and not one we might have installed already
require './lib/doing/version.rb'
spec = Gem::Specification.new do |s|
  s.name = 'doing'
  s.version = Doing::VERSION
  s.author = 'Brett Terpstra'
  s.email = 'me@brettterpstra.com'
  s.homepage = 'http://brettterpstra.com/project/doing/'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A command line tool for managing What Was I Doing reminders'
  s.description = [
    'A tool for managing a TaskPaper-like file of recent activites.',
    'Perfect for the late-night hacker on too much caffeine to remember',
    'what they accomplished at 2 in the morning.'
  ].join(' ')
  s.license = 'MIT'
  s.files = `git ls-files -z`.split("\x0").reject { |f| f.strip =~ %r{^((test|spec|features)/|\.git|buildnotes)} }
  s.require_paths << 'lib'
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options << '--title' << 'doing' << '--main' << 'README.md' << '--markup' << 'markdown'
  s.bindir = 'bin'
  s.executables << 'doing'
  s.add_development_dependency('github-markup', '~> 4.0', '>= 4.0.0')
  s.add_development_dependency('parallel_tests', '~> 3.7', '>= 3.7.3')
  s.add_development_dependency('rake', '~> 13.0', '>= 13.0.1')
  s.add_development_dependency('rdoc', '~> 6.3.1')
  s.add_development_dependency('redcarpet', '~> 3.5', '>= 3.5.1')
  s.add_development_dependency('test-unit', '~> 3.4.4')
  s.add_development_dependency('tty-spinner', '~> 0.9', '>= 0.9.3')
  s.add_development_dependency('yard', '~> 0.9', '>= 0.9.36')
  s.add_runtime_dependency('chronic', '~> 0.10', '>= 0.10.2')
  s.add_runtime_dependency('deep_merge', '~> 1.2', '>= 1.2.1')
  s.add_runtime_dependency('gli', '~> 2.20', '>= 2.20.1')
  s.add_runtime_dependency('haml', '~>5.0.0', '>= 5.0.0')
  s.add_runtime_dependency('parslet', '~> 2.0', '>= 2.0.0')
  s.add_runtime_dependency('plist', '~> 3.6', '>= 3.6.0')
  s.add_runtime_dependency('safe_yaml', '~> 1.0')
  s.add_runtime_dependency('tty-link', '~> 0.1', '>= 0.1.1')
  s.add_runtime_dependency('tty-markdown', '~> 0.7', '>= 0.7.0')
  s.add_runtime_dependency('tty-progressbar', '~> 0.18', '>= 0.18.2')
  s.add_runtime_dependency('tty-reader', '~> 0.9', '>= 0.9.0')
  s.add_runtime_dependency('tty-screen', '~> 0.8', '>= 0.8.1')
  s.add_runtime_dependency('tty-which', '~> 0.5', '>= 0.5.0')

  # s.add_runtime_dependency('amatch', '~> 0.4', '>= 0.4.0')
end
