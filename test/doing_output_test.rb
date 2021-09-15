require 'fileutils'
require 'tempfile'
require 'time'

require 'doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingOutputTest < Test::Unit::TestCase
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

  def test_last_command
    subject = 'Test new entry @tag1'
    doing('now', subject)
    assert_match(/#{subject}\s*$/, doing('last'), 'last entry should be entry just added')
  end

  def test_view_command
    subject = 'Test new entry @tag1'
    doing('done', subject)
    subject2 = 'Test new entry 2 @tag2'
    doing('done', subject2)
    assert_count_entries(2, doing('view', 'done'), 'There should be 2 entries shown by `view done`')
  end

  def test_show_command
    subject = 'Test new entry @tag1'
    doing('now', subject)
    subject2 = 'Test new entry 2 @tag2'
    doing('now', subject2)
    result = doing('show').uncolor.strip
    assert_count_entries(2, result, 'There should be 2 entries shown by `doing show`')
    assert_match(/#{subject}\s*$/, result, 'doing show results should include test entry')
    result = doing('show', '@tag1').uncolor.strip
    assert_count_entries(1, result, 'There should be 1 entries shown by `doing show @tag1`')
    assert_match(/#{subject}\s*$/, result, 'doing show @tag1 results should include test entry')
  end

  def test_show_command_tag_boolean
    subject = 'Test new entry @tag1'
    doing('now', subject)
    subject2 = 'Test new entry 2 @tag2'
    doing('now', subject2)
    subject3 = 'Test new entry 3 @tag1 @tag2 @tag3'
    doing('now', subject3)

    result = doing('show', '--tag', 'tag1,tag2', '--bool', 'and').uncolor.strip
    assert_count_entries(1, result, 'There should be 1 entry shown with both @tag1 and @tag2')
    assert_match(/#{subject3}\s*$/, result, 'doing show results should include entry with both @tag1 and @tag2')

    result = doing('show', '--tag', 'tag1,tag2', '--bool', 'or').uncolor.strip
    assert_count_entries(3, result, 'There should be 3 entries shown with either @tag1 or @tag2')
    result = doing('show', '--tag', 'tag2', '--bool', 'not').uncolor.strip
    assert_count_entries(1, result, 'There should be 1 entry shown without @tag2')
    assert_match(/#{subject}\s*$/, result, 'doing show results should include entry without @tag2')
  end

  def test_today_command
    subject = 'Test new entry @tag1'
    doing('done', subject)
    subject2 = 'Test new entry 2 @tag2'
    doing('now', subject2)
    assert_count_entries(2, doing('today'), 'There should be 2 entries shown by `doing today`')
  end

  def test_yesterday_command
    doing('done', 'Adding an entry finished yesterday', '--took', '30m', '--back', 'yesterday 3pm')
    assert_count_entries(1, doing('yesterday'), 'There should be 1 entry shown by `doing yesterday`')
  end

  def test_sections_command
    result = doing('sections').uncolor.strip
    assert_match(/^Currently$/, result, 'Currently should be the only section shown')
  end

  def test_recent_command
    # 1:42pm: Did a thing @done(2021-07-05 13:42)
    doing('now', 'Test new entry @tag1')
    doing('now', 'Test new entry 2 @tag2')
    result = doing('recent').uncolor.strip
    rx = /^ *\d+:\d\d(am|pm): (.*?)$/
    matches = result.scan(rx)
    assert_equal(matches.count, 2, 'There should be 2 entries shown by `doing recent`')
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

