# frozen_string_literal: true

module Doing
  class TestImport
    include Doing::Util

    def self.settings
      {
        type: :import,
        trigger: 'tester'
      }
    end

    def self.import(_wwid, path, options: {})
      if path.nil?
        Doing.logger.info('Test with no paths')
      else
        Doing.logger.info("Test with path: #{path}")
      end
      Doing.logger.info('Test Import Plugin Ran')
    end

    Doing::Plugins.register 'tester', :import, self
  end
end
