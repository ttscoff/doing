# frozen_string_literal: true

require 'helpers/doing-helpers'
require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing'
# require 'gli'

# Tests for Item class
class DoingUnitGoodTest < Test::Unit::TestCase
  def test_good
    good_string = 'has content'
    empty_string = ''
    nil_string = nil
    good_array = %w[has content]
    empty_array = []
    true_bool = true
    false_bool = false
    good_hash = { has: 'content' }
    empty_hash = {}

    assert_equal(true, good_string.good?)
    assert_equal(true, good_array.good?)
    assert_equal(true, good_hash.good?)
    assert_equal(true, true_bool.good?)

    assert_not_equal(true, empty_string.good?)
    assert_not_equal(true, nil_string.good?)
    assert_not_equal(true, empty_array.good?)
    assert_not_equal(true, empty_hash.good?)
    assert_not_equal(true, false_bool.good?)
  end

  def test_truthy
    assert_equal(true, 'yes'.truthy?)
    assert_equal(true, 'Y'.truthy?)
    assert_equal(true, 'true'.truthy?)
    assert_equal(true, 'TRUE'.truthy?)
    assert_equal(true, '1'.truthy?)

    assert_not_equal(true, 'no'.truthy?)
    assert_not_equal(true, 'N'.truthy?)
    assert_not_equal(true, 'false'.truthy?)
    assert_not_equal(true, 'FALSE'.truthy?)
    assert_not_equal(true, '0'.truthy?)
  end
end
