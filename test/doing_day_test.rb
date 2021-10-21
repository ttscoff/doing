require 'fileutils'
require 'tempfile'
require 'time'
require 'yaml'

require 'doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingDayTest < Test::Unit::TestCase
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

  def test_today_command
    subject = 'Test new entry @tag1'
    doing('done', subject)
    subject2 = 'Test new entry 2 @tag2'
    doing('now', subject2)
    subject3 = 'Yesterday should not show up'
    doing('done', '--back', '24h', subject3)
    res = doing('today')
    assert_count_entries(2, res, 'There should be 2 entries shown by `doing today`')
    assert_no_match(/#{subject3}/, res, 'Entry from yesterday should not be shown')
  end

  def test_yesterday_command
    subject1 = 'Adding an entry finished yesterday'
    subject2 = 'Today should not show up'
    subject3 = 'Neither should 2 days ago'
    doing('done', subject1, '--took', '30m', '--back', 'yesterday 3pm')
    doing('now', subject2)
    doing('done', subject3, '--back', '48h')
    res = doing('yesterday')
    assert_count_entries(1, res, 'There should be 1 entry shown by `doing yesterday`')
    assert_no_match(/#{subject2}/, res, 'Entry from today should not be shown')
    assert_no_match(/#{subject3}/, res, 'Entry from 2 days ago should not be shown')
  end

  def test_since_command
    subject1 = 'Adding an entry finished yesterday'
    subject2 = 'Adding an entry from today'
    subject3 = 'An entry from 2 days ago'
    doing('done', subject1, '--took', '30m', '--back', 'yesterday 3pm')
    doing('now', subject2)
    doing('done', subject3, '--back', '48h')
    res = doing('since', 'yesterday')
    assert_count_entries(2, res, 'There should be 1 entry shown by `doing since yesterday`')
    assert_no_match(/#{subject3}/, res, 'Entry from 2 days ago should not be shown')
  end

  def test_on_command
    # 1:42pm: Did a thing @done(2021-07-05 13:42)
    doing('now', 'Test new entry @tag1')
    doing('now', 'Test new entry 2 @tag2')
    result = doing('--stdout', 'on', 'today')
    assert_count_entries(2, result, 'There should be 2 entries')
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
    doing_with_env({}, '--config_file', @config_file, '--doing_file', @wwid_file, *args)
  end
end

