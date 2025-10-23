# frozen_string_literal: true

require 'fileutils'
require 'tempfile'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for done commands
class DoingUndoTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_REGEX = /^\d{4}-\d\d-\d\d \d\d:\d\d \|/.freeze

  def setup
    @tmpdirs = []
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid_undo.md')
    @backup_dir = File.join(@basedir, 'doing_backup')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_undo
    entries = [
      'backlog entry 1',
      'backlog entry 2',
      'Begin history',
      'Test entry 1',
      'Test entry 2'
    ]
    entries.each do |e|
      doing('now', e)
      sleep 0.5
    end

    assert_count_entries(entries.count, doing('show'))

    doing('undo')
    shown = doing('show')
    assert_not_contains_entry('Test entry 2', shown)
    assert_contains_entry('Test entry 1', shown)

    doing('undo')
    shown = doing('show')
    assert_not_contains_entry('Test entry 1', shown)
    assert_contains_entry('Begin history', shown)

    doing('undo', '--redo')
    shown = doing('show')
    assert_contains_entry('Test entry 1', shown)

    doing('undo', '--prune', '0')
    assert_equal(0, Dir.glob('*.md', base: @backup_dir).count)
  end

  private

  def assert_contains_entry(string, shown, message = 'Entry containing string should exist')
    assert_match(/#{string}/, shown, "#{message}: #{string}")
  end

  def assert_not_contains_entry(string, shown, message = 'Entry containing string should exist')
    assert_no_match(/#{string}/, shown, "#{message}: #{string}")
  end

  def assert_count_entries(count, shown, message = 'Should be X entries shown')
    assert_equal(count, shown.uncolor.strip.scan(ENTRY_REGEX).count, message)
  end

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  def doing(*args)
    doing_with_env({ 'DOING_BACKUP_DIR' => @backup_dir, 'DOING_CONFIG' => @config_file }, '--doing_file', @wwid_file,
                   *args)
  end
end
