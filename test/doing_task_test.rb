require 'fileutils'
require 'tempfile'
require 'time'

require 'doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingTaskTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_TS_REGEX = /\s*(?<ts>[^|]+) \s*\|/.freeze
  ENTRY_DONE_REGEX = /@done\((?<ts>.*?)\)/.freeze

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

  def test_section_rejects_empty_args
    assert_raises(RuntimeError) { doing('now', '--section') }
  end

  def test_new_task
    # Add a task
    subject = 'Test new task @tag1'
    doing('now', subject)
    assert_match(/#{subject}\s*$/, doing('show', '-c 1'), 'should have added task')
  end

  def test_done_task
    subject = 'Test finished task @tag1'
    now = Time.now.round_time(1)
    doing('done', subject)
    r = doing('show').uncolor.strip
    t = r.match(ENTRY_TS_REGEX)
    d = r.match(ENTRY_DONE_REGEX)

    assert(d, "#{r} should have @done tag with timestamp")

    assert_equal(t['ts'], d['ts'], 'Timestamp and @done timestamp should match')
    assert_equal(Time.parse(d['ts']).round_time(1), now,
                 'Finished time should be equal to the nearest minute')
  end

  def test_finish_task
    subject = 'Test new task @tag1'
    doing('now', subject)
    doing('finish')
    r = doing('show').uncolor.strip
    m = r.match(ENTRY_DONE_REGEX)
    assert(m, "#{r} should have @done timestamp")
    now = Time.now.round_time(1)
    assert_equal(Time.parse(m['ts']).round_time(1), now,
                 'Finished time should be equal to the nearest minute')
  end

  def test_later_task
    subject = 'Test later task'
    result = doing('--stdout', 'later', subject)
    assert_match(/Added section "Later"/, result, 'should have added Later section')
    assert_match(/Added "#{subject}" to Later/, result, 'should have added task to Later section')
    assert_equal(1, doing('show', 'later').uncolor.strip.split("\n").count, 'Later section should have 1 entry')
  end

  def test_cancel_task
    doing('now', 'Test task')
    doing('cancel')
    result = doing('show')
    assert_match(/@done$/, result, 'should have @done tag with no timestamp')
  end

  def test_resume_task
    subject = 'Test task'
    doing('done', subject)
    result = doing('--stdout', 'again')

    assert_match(/Added "#{subject}" to Currently/, result, 'Task should be added again')
  end

  def test_archive_task
    subject = 'Test task'
    doing('done', subject)
    result = doing('--stdout', 'archive')

    assert_match(/Added section "Archive"/, result, 'Archive section should have been added')
    assert_match(/#{subject}/, doing('show', 'Archive'), 'Archive section should contain test task')
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

