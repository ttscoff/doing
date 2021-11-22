require 'fileutils'
require 'tempfile'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingUndoTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_REGEX = /^\d{4}-\d\d-\d\d \d\d:\d\d \|/.freeze

  def setup
    @tmpdirs = []
    @result = ''
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_undo_command
    subject = 'Test new entry @tag1'
    subject2 = 'Test new entry @tag2'
    subject3 = 'Test new entry @tag3'
    doing('now', subject)
    assert_count_entries(1, doing('show'), 'There should be 1 entries shown')
    doing('now', subject2)
    assert_count_entries(2, doing('show'), 'There should be 2 entries shown')
    doing('now', subject3)
    assert_count_entries(3, doing('show'), 'There should be 3 entries shown')
    doing('undo')
    assert_count_entries(2, doing('show'), 'There should be 2 entries shown after undoing last command')
  end

  private

  def assert_count_entries(count, shown, message = 'Should be X entries shown')
    assert_equal(count, shown.uncolor.strip.scan(ENTRY_REGEX).count, message)
  end

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  def doing(*args)
    doing_with_env({'DOING_CONFIG' => @config_file}, '--doing_file', @wwid_file, *args)
  end
end

