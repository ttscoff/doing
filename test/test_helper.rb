# frozen_string_literal: true

require 'test/unit'

# Add test libraries you want to use here, e.g. mocha

module Test
  module Unit
    class TestCase
      ENV['TZ'] = 'UTC'
      # Add global extensions to the test case class here
    end
  end
end
