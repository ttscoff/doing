require 'fileutils'
require 'tempfile'
require 'time'

require 'doing-helpers'
require 'test_helper'

# Tests for natural language date processing
class DoingDoneTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_REGEX = /^\d{4}-\d\d-\d\d \d\d:\d\d \|/.freeze
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

  def test_finish
    subject = 'Test new entry @tag1'
    doing('now', subject)
    doing('finish')
    r = doing('show').uncolor.strip
    m = r.match(ENTRY_DONE_REGEX)
    assert(m, "Entry should have @done timestamp")
    now = Time.now.round_time(1)
    assert_equal(Time.parse(m['ts']).round_time(1), now,
                 'Finished time should be equal to the nearest minute')
  end

  def test_finish_tag
    doing('now', 'Test new entry @tag1')
    doing('now', 'Another new entry @tag2')
    doing('finish', '--tag', 'tag1')
    t1 = doing('show', '@tag1').uncolor.strip
    assert_match(ENTRY_DONE_REGEX, t1, "@tag1 entry should have @done timestamp")
    t2 = doing('show', '@tag2').uncolor.strip
    assert_no_match(ENTRY_DONE_REGEX, t2, "@tag2 entry should not have @done timestamp")
  end

  def test_finish_unfinished
    doing('now', '--back=15m', 'Adding an unfinished entry')
    doing('done', 'Adding a finished entry')
    result = doing('--stdout', 'finish', '--unfinished')
    assert_match(/Added @done: "Adding an unfinished entry/, result, "Earlier unfinished task should be marked @done")
  end

  def test_finish_took
    subject = 'Test new entry @tag1'
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

  def test_finish_count
    subject = 'Test finish entry '
    4.times do |i|
      doing('now', "#{subject} #{i}")
    end

    doing('finish', '3')
    assert_count_entries(4, doing('show'), 'Should be 4 total entries')
    assert_count_entries(3, doing('show', '@done'), 'Should be 3 done entries')
  end

  def test_done_no_args
    subject = 'Test new entry @tag1'
    doing('now', subject)
    doing('done')
    r = doing('show').uncolor.strip
    d = r.match(ENTRY_DONE_REGEX)
    assert(d, "Entry should have @done timestamp")
  end

  def test_done_with_args
    subject = 'Test finished entry @tag1'
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

  def test_done_back
    now = Time.now
    start = (now - (65 * 60)).round_time(2)
    doing('done', '--back', '65m', 'Test entry')
    r = doing('show').uncolor.strip
    t = r.match(ENTRY_TS_REGEX)
    d = r.match(ENTRY_DONE_REGEX)
    assert(d, 'Entry should have @done timestamp')
    start_time = Time.parse(t['ts']).round_time(2)
    end_time = Time.parse(d['ts']).round_time(2)
    assert_equal(start_time, start,
                 'Start time should be equal to the nearest minute')
    assert_equal(end_time, start,
                 'Finish time should be the same as start time')
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
    doing('done', '--back', '30m', '--took', '10m', 'Test entry')
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
