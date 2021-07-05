require 'fileutils'
require 'tempfile'
require 'time'

require 'doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingOutputTest < Test::Unit::TestCase
  include DoingHelpers

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
    subject = 'Test new task @tag1'
    doing('now', subject)
    assert_match(/#{subject}\s*$/, doing('last'), 'last task should be task just added')
  end

  def test_view_command
    subject = 'Test new task @tag1'
    doing('done', subject)
    subject2 = 'Test new task 2 @tag2'
    doing('done', subject2)
    result = doing('view', 'done').strip
    assert_equal(result.split("\n").count, 2, 'There should be 2 tasks shown by `view done`')
  end

  def test_show_command
    subject = 'Test new task @tag1'
    doing('now', subject)
    subject2 = 'Test new task 2 @tag2'
    doing('now', subject2)
    result = doing('show').uncolor.strip
    assert_equal(result.split("\n").count, 2, 'There should be 2 tasks shown by `doing show`')
    assert_match(/#{subject}\s*$/, result, 'doing show results should include test task')
    result = doing('show', '@tag1').uncolor.strip
    assert_equal(result.split("\n").count, 1, 'There should be 1 tasks shown by `doing show @tag1`')
    assert_match(/#{subject}\s*$/, result, 'doing show @tag1 results should include test task')
  end

  def test_today_command
    subject = 'Test new task @tag1'
    doing('done', subject)
    subject2 = 'Test new task 2 @tag2'
    doing('now', subject2)
    result = doing('today').uncolor.strip
    assert_equal(result.split("\n").count, 2, 'There should be 2 tasks shown by `doing today`')
  end

  def test_sections_command
    result = doing('sections').uncolor.strip
    assert_match(/^Currently$/, result, 'Currently should be the only section shown')
  end

  def test_recent_command
    # 1:42pm: Did a thing @done(2021-07-05 13:42)
    doing('now', 'Test new task @tag1')
    doing('now', 'Test new task 2 @tag2')
    result = doing('recent').uncolor.strip
    rx = /^ *\d+:\d\d(am|pm): (.*?)$/
    matches = result.scan(rx)
    assert_equal(matches.count, 2, 'There should be 2 tasks shown by `doing recent`')
  end

  def test_on_command
    # 1:42pm: Did a thing @done(2021-07-05 13:42)
    doing('now', 'Test new task @tag1')
    doing('now', 'Test new task 2 @tag2')
    result = doing('--stdout', 'on', 'today').uncolor.strip
    assert_equal(result.split("\n").count, 3, 'There should be 2 entries and a date interpreted line')
  end

  private

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  def doing(*args)
    doing_with_env({}, '--config_file', @config_file, '--doing_file', @wwid_file, *args)
  end
end

