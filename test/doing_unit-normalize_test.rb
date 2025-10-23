# frozen_string_literal: true

require 'helpers/doing-helpers'
require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing'
# require 'gli'

# Tests for Item class
class DoingUnitNormalizeTest < Test::Unit::TestCase
  def test_normalize_case
    assert_equal(:smart, :smar.normalize_case)
    assert_equal(:sensitive, 'case'.normalize_case)
    assert_equal(:smart, 's'.normalize_case)
  end

  def test_normalize_tag_sort
    assert_equal(:name, 'name'.normalize_tag_sort)
    assert_equal(:time, :t.normalize_tag_sort)
  end

  def test_normalize_age
    assert_equal(:oldest, 'old'.normalize_age)
    assert_equal(:newest, :newest.normalize_age)
  end

  def test_normalize_bool
    assert_equal(:and, 'AND'.normalize_bool)
    assert_equal(:or, :any.normalize_bool)
    assert_equal(:not, :not.normalize_bool)
    assert_equal(:not, 'none'.normalize_bool)
  end
end
