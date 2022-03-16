# frozen_string_literal: true

require 'helpers/doing-helpers'
require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing'
require 'doing/item/item'
# require 'gli'

# Tests for Item class
class DoingItemTest < Test::Unit::TestCase
  include DoingHelpers
  include Doing

  def setup
    @wwid = WWID.new
  end

  def teardown
  end

  # TODO: tests for duration, interval, end_date, overlapping_time?, tags?, tag_values?

  def test_tag_item
    item = Item.new(Time.now - 3600, "Test item @done(#{(Time.now - 1200).strftime('%F %R')})", @wwid.current_section)
    item.tag(%w[testtag1 testtag2])
    assert(item.tags?(%w[testtag1 testtag2], :and), 'Item should have both tags')
    item.tag(['testtag2'], remove: true)
    assert_equal(false, item.tags?(%w[testtag1 testtag2], :and), 'Item should not have both tags')
  end

  def test_search_item
    item = Item.new(Time.now - 3600, "Test item with search string @done(#{(Time.now - 1200).strftime('%F %R')})", @wwid.current_section)
    assert(item.search('search string'), 'Item should match search string')
    assert(item.search('/s.*?ch s.*?g/'), 'Item should match regex query')
    assert_equal(false, item.search('Search String', case_type: :smart), 'Item should not match case')
    assert(item.search('string search'), 'Pattern matching should work')
  end

  def test_value_comparison
    item = Item.new(Time.now - 3600, "Test item with search string @tag1(50%) @tag2(2021-03-03 12:00) @tag3(string value)", @wwid.current_section, ['note content'])
    assert(item.tag_values?(['tag1 > 25']), 'Item should match value comparison')
    assert_equal(false, item.tag_values?(['tag1 < 25']), 'Item should not match value comparison')

    assert(item.tag_values?(['tag2 < 2021-03-04']), 'Item should match date comparison')
    assert_equal(false, item.tag_values?(['tag2 < 2021-03-01']), 'Item should not match date comparison')

    assert(item.tag_values?(['tag3 ^= string']), 'Item should match string comparison')
    assert_equal(false, item.tag_values?(['tag3 $= testing']), 'Item should not match string comparison')
  end

  def test_move_item
    section = 'Test Section'
    item = Item.new(Time.now - 3600, "Test item with search string @done(#{(Time.now - 1200).strftime('%F %R')})", @wwid.current_section)
    item.move_to(section, label: true, log: false)
    assert_equal(section, item.section, 'Section should match')
  end
end

