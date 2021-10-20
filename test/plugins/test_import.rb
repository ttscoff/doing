module Doing
  class TestImport
    include Doing::Util

    def self.settings
      {
        type: :import,
        trigger: 'tester'
      }
    end

    def self.import(wwid, path, options: {})
      if path.nil?
        wwid.results.push('Test with no paths')
      else
        wwid.results.push("Test with path: #{path}")
      end
      wwid.results.push('Test Import Plugin Ran')
    end

    Doing::Plugins.register 'tester', :import, self
  end
end
