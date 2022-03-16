# frozen_string_literal: true

require 'helpers/doing-helpers'
require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing'
require 'doing/time'

# Tests for Item class
class DoingTimeTest < Test::Unit::TestCase
  include DoingHelpers
  include Doing

  def setup
  end

  def teardown
  end

  def test_relative_date
    t = Time.parse("#{Time.now.year - 1}-12-21 15:00")
    assert_match(%r{12/21  3:00pm}, t.relative_date, 'Relative date should match')

    t = Time.parse("#{Time.now.year}-#{Time.now.month}-#{Time.now.day - 1} 12:00")
    assert_match(%r{[a-z]{3} 12:00pm}i, t.relative_date, 'Relative date should match')

    t = Time.parse("#{Time.now.strftime('%F')} 01:00")
    assert_match(%r{^ 1:00am$}, t.relative_date, 'Relative date should match')
  end

  def test_humanize
    assert_match(/4 minutes, 5 seconds/, Time.now.humanize(245), 'String output should match')
  end

  def test_time_ago
    t = Time.now - (2 * 60 * 60) - (54 * 60) - 31
    assert_match(/2 hours, 54 minutes, 3[0-3] seconds ago/, t.time_ago, 'Time ago string should match')
  end
end

