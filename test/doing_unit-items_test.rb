# frozen_string_literal: true

require 'helpers/doing-helpers'
require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing'
require 'doing/item/item'
require 'doing/items/items'
# require 'gli'

# Tests for Item class
class DoingItemsTest < Test::Unit::TestCase
  include DoingHelpers
  include Doing

  def setup
    @wwid = WWID.new
    @sections = ['Currently', 'temp section 1', 'temp_section 2'].map { |s| Section.new(s, original: "#{s.to_s}:") }
    @tags = %w[tag1 tag2 tag3 tag4 tag5 tag6]
    @content = generate_items
  end

  def teardown
  end

  def generate_items(max = 6)
    items = Items.new

    max.times do |i|
      section = @sections[i % 3]
      items.add_section(section) unless items.section?(section)
      start_time = Time.now - (600 * i)
      item = Item.new(start_time, "Test item #{i} @#{@tags[i]}", section)
      items.push(item)
    end

    items
  end

  def test_diff_items
    other = Marshal.load(Marshal.dump(@content))

    other[2].date = Time.now - 3600
    other[1].title = 'Modified entry'
    diff = @content.diff(other)
    puts
    pp [@content, other, diff]
    assert_equal(2, diff[:deleted].count, '2 items should be added')
  end

  def test_all_tags
    all_tags = @content.all_tags
    @tags.each do |tag|
      assert(all_tags.include?(tag), "Tags should include #{tag}")
    end
  end

  def test_in_section
    section_items = @content.in_section(@sections[1])
    assert_equal(2, section_items.count, "There should be 2 items in section #{@sections[1]}")
  end

  def test_delete_item
    item = @content[2]
    @content.delete_item(item)
    assert_not_equal(true, @content.include?(item), 'Items should not include deleted item')
  end

  def test_update_item
    new_title = 'This is the updated item'
    item = @content[2]
    new_item = item.dup
    new_item.title = new_title
    @content.update_item(item, new_item)
    assert_equal(new_title, @content[2].title, 'Item 2 should have a new title')
  end

  def test_add_section
    new_section = 'Test Section Added'
    @content.add_section(new_section)
    assert(@content.sections.map { |s| s.title }.include?(new_section), 'Section 1 should have been added from String input')

    @content.add_section(Section.new('Test Section 2'))
    assert(@content.sections.map { |s| s.title }.include?('Test Section 2'), 'Section 2 should have been added from Section input')
  end

  def test_search_id
    item = @content[2].clone
    id = item.id
    assert(item.equal?(@content.find_id(id)), 'Located item should be equal')
    assert_equal(2, @content.index_for_id(id), 'Located item should be at index 2')
  end
end
