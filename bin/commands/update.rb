# frozen_string_literal: true

# @@update

desc 'Update doing to the latest version'
long_desc 'Checks for the latest available version of doing and updates your local install if needed.'
command %i[update] do |c|
  c.example 'doing update', desc: 'Update to the latest version'

  c.desc 'Check for pre-release version'
  c.switch %i[p pre beta], negatable: false, default_value: false

  c.action do |_global_options, options, _args|
    my_version = `doing -v`.match(/doing version (?<v>[\d.]+)(?:\.?pre[,)])?/)['v']
    latest_version = if options[:beta]
                       `gem search doing --pre`.match(/^doing \((?<v>[\d.]+)\.?pre[,)]/)['v']
                     else
                       `gem search doing`.match(/^doing \((?<v>[\d.]+)\)/)['v']
                     end
    my_version = Doing::Version.new(my_version)
    latest_version = Doing::Version.new(latest_version)

    outdated = my_version.compare(latest_version, :older)

    if outdated
      pre = options[:beta] ? '--pre' : ''
      res = `gem install doing #{pre} 2> /dev/null`
      res ||= `sudo gem install doing #{pre}`
      ver = res.match(/doing-(?<v>[\d.]+)\n/)['v']
      if ver
        Doing.logger.info("Version #{ver} installed")
      else
        Doing.logger.error('Error installing latest version')
      end
    else
      Doing.logger.info("You have the latest version (#{my_version}) installed")
    end
  end
end
