require 'fileutils'
require 'tempfile'
require 'time'

require 'doing-helpers'
require 'test_helper'

# Tests for natural language date processing
class DoingChronifyTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_TS_REGEX = /\s*(?<ts>[^|]+) \s*\|/.freeze
  ENTRY_DONE_REGEX = /@done\((?<ts>.*?)\)/.freeze

  def setup
    @tmpdirs = []
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_back_rejects_empty_args
    assert_raises(RuntimeError) { doing('now', '--back', '', 'should fail') }
  end

  def test_back_interval
    now = Time.now
    doing('now', '--back', '20m', 'test interval format')
    m = doing('show').match(ENTRY_TS_REGEX)
    assert(m)
    assert_equal(Time.parse(m['ts']).round_time(1), (now - (20 * 60)).round_time(1),
                 'New task should be equal to the nearest minute')
  end

  def test_back_strftime
    ts = '2016-03-15 15:32:04 EST'
    doing('now', '--back', ts, 'test strftime format')
    m = doing('show').match(ENTRY_TS_REGEX)
    assert(m)
    assert_equal(Time.parse(m['ts']).round_time(1), Time.parse(ts).round_time(1),
                 'New task should be equal to the nearest minute')
  end

  def test_back_semantic
    yesterday = (Time.now - (60 * 60 * 24)).strftime('%Y-%m-%d 18:30 %Z')
    doing('now', '--back', 'yesterday 6:30pm', 'test semantic format')
    m = doing('show').match(ENTRY_TS_REGEX)
    assert(m)
    task_time = Time.parse(m['ts']).strftime('%Y-%m-%d 18:30 %Z')
    assert_equal(task_time, yesterday, 'new task is the wrong time')
  end

  def test_finish_took
    subject = 'Test new task @tag1'
    doing('now', subject)
    doing('finish', '--took=60m')
    r = doing('show').uncolor.strip
    t = r.match(ENTRY_TS_REGEX)
    d = r.match(ENTRY_DONE_REGEX)
    assert(d, "#{r} should have @done timestamp")
    start = Time.parse(t['ts'])
    assert_equal((start + (60 * 60)).round_time(2), Time.parse(d['ts']).round_time(2),
                 'Finished time should be 60 minutes after start')
  end

  def test_done_took
    now = Time.now
    finish = (now - (30 * 60)).round_time(2)
    doing('now', '--back', '1h', 'test interval format')
    doing('done', '--took', '30m')
    r = doing('show').uncolor.strip
    d = r.match(ENTRY_DONE_REGEX)
    assert(d, 'Entry should have done date')
    end_time = Time.parse(d['ts']).round_time(2)
    assert_equal(end_time, finish,
                 'Finish time should be equal to the nearest minute')
  end

  def test_done_back_took
    now = Time.now
    start = (now - (30 * 60)).round_time(2)
    finish = start + (10 * 60)
    doing('done', '--back', '30m', '--took', '10m', 'Test task')
    r = doing('show').uncolor.strip
    t = r.match(ENTRY_TS_REGEX)
    d = r.match(ENTRY_DONE_REGEX)
    assert(t, "Entry should have timestamp")
    assert(d, 'Entry should have @done with timestamp')
    start_time = Time.parse(t['ts']).round_time(2)
    end_time = Time.parse(d['ts']).round_time(2)
    assert_equal(start_time, start,
                 'Start time should be equal to the nearest minute')
    assert_equal(end_time, finish,
                 'Finish time should be equal to the nearest minute')
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
