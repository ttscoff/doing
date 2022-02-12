# frozen_string_literal: true

require 'helpers/doing-helpers'
require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing'
# require 'gli'

# Tests for Item class
class DoingUnitNoteTest < Test::Unit::TestCase
  include Doing

  def test_note_with_string
    note = ['This is a test note', 'With a couple lines', '', '  whitespace  ']
    new_note = Note.new(note.join("\n"))
    assert_equal(3, new_note.count, 'Note should have 3 lines')
  end

  def test_note_with_array
    note = ['This is a test note', 'With a couple lines', '', '  whitespace  ']
    new_note = Note.new(note)
    assert_equal(3, new_note.count, 'Note should have 3 lines')
  end

  def test_note_append
    note = ['This is a test note', 'With a couple lines', '', '  whitespace  ']
    new_note = Note.new(note)
    new_note.add('This is another line')
    assert_equal(4, new_note.count, 'Note should have 4 lines')
    new_note.add(['This is an array', 'With two elements'])
    assert_equal(6, new_note.count, 'Note should have 6 lines')
  end

  def test_note_replace
    note = ['This is a test note', 'With a couple lines', '', '  whitespace  ']
    new_note = Note.new(note)
    new_note.add('This is one line', replace: true)
    assert_equal(1, new_note.count, 'Note should have 1 lines')
  end

  def test_note_compare
    note1 = ['This is a test note', 'With a couple lines', '', '  whitespace  ']
    note2 = ['This is a test note', 'With a different couple lines', '', '  whitespace  ']
    new_note = Note.new(note1)
    note_copy = Note.new(note1)
    other_note = Note.new(note2)
    assert_equal(true, new_note.equal?(note_copy), 'Notes should be the same')
    assert_not_equal(true, new_note.equal?(other_note), 'Notes should be different')
  end
end

