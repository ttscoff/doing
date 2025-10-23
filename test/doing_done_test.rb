# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'time'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for done commands
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
    @backup_dir = File.join(@basedir, 'doing_backup')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_done_at
    today = Time.now
    start_at = today.strftime('%Y-%m-%d 13:30 %Z')
    finish_at = today.strftime('%Y-%m-%d 15:00 %Z')
    doing('done', '--at', '3pm', '--took', '1:30', 'test semantic format')
    last = doing('show', '-c', '1')
    m = last.match(ENTRY_DONE_REGEX)
    assert(m)
    entry_time = Time.parse(m['ts']).strftime('%Y-%m-%d %H:%M %Z')
    assert_equal(entry_time, finish_at, 'new entry has wrong finish time')
    m = last.match(ENTRY_TS_REGEX)
    assert(m)
    entry_time = Time.parse(m['ts']).strftime('%Y-%m-%d %H:%M %Z')
    assert_equal(entry_time, start_at, 'new entry has wrong start time')
  end

  def test_done_no_args
    subject = 'Test new entry @tag1'
    doing('now', subject)
    doing('done')
    r = doing('show').uncolor.strip
    d = r.match(ENTRY_DONE_REGEX)
    assert(d, 'Entry should have @done timestamp')
  end

  def test_done_with_args
    subject = 'Test finished entry @tag1'
    now = Time.now
    doing('done', subject)
    r = doing('show').uncolor.strip
    t = r.match(ENTRY_TS_REGEX)
    d = r.match(ENTRY_DONE_REGEX)

    assert(d, "#{r} should have @done tag with timestamp")

    assert_equal(t['ts'], d['ts'], 'Timestamp and @done timestamp should match')
    assert_within_tolerance(Time.parse(d['ts']), now,
                            message: 'Finished time should be equal to the nearest minute')
  end

  def test_done_back
    now = Time.now
    start = (now - (65 * 60))
    doing('done', '--back', '65m', 'Test entry')
    r = doing('show').uncolor.strip
    t = r.match(ENTRY_TS_REGEX)
    d = r.match(ENTRY_DONE_REGEX)
    assert(d, 'Entry should have @done timestamp')
    start_time = Time.parse(t['ts'])
    end_time = Time.parse(d['ts'])
    assert_within_tolerance(start_time, start,
                            message: 'Start time should be equal to the nearest minute')
    assert_within_tolerance(end_time, now,
                            message: 'Finish time should be the current time')
  end

  def test_done_new_with_took
    now = Time.now
    finish = now
    start = (now - (30 * 60))
    doing('done', 'Started half an hour ago and just finished', '--took', '30m')
    r = doing('show').uncolor.strip
    t = r.match(ENTRY_TS_REGEX)
    d = r.match(ENTRY_DONE_REGEX)
    assert(d, 'Entry should have @done timestamp')
    start_time = Time.parse(t['ts'])
    end_time = Time.parse(d['ts'])
    assert_within_tolerance(start, start_time,
                            message: 'Start time should be 30 minutes ago')
    assert_within_tolerance(finish, end_time,
                            message: 'Finish time should be now')
  end

  def test_done_complete_with_took
    now = Time.now
    start = (now - (60 * 60))
    finish = (now - (30 * 60))

    doing('now', '--back', '1h', 'test interval format')
    r = doing('show').uncolor.strip
    d = r.match(ENTRY_TS_REGEX)
    start_time = Time.parse(d['ts'])
    assert_within_tolerance(start, start_time, message: 'Start time should be one hour ago')

    doing('done', '--took', '30m')
    r = doing('show').uncolor.strip
    d = r.match(ENTRY_DONE_REGEX)
    assert(d, 'Entry should have done date')
    end_time = Time.parse(d['ts'])
    assert_within_tolerance(end_time, finish,
                            message: 'Finish time should be 30 minutes ago')
  end

  def test_done_back_took
    now = Time.now
    start = (now - (30 * 60))
    finish = start + (10 * 60)
    doing('done', '--back', '30m', '--took', '10m', 'Test entry')
    r = doing('show').uncolor.strip
    t = r.match(ENTRY_TS_REGEX)
    d = r.match(ENTRY_DONE_REGEX)
    assert(t, 'Entry should have timestamp')
    assert(d, 'Entry should have @done with timestamp')
    start_time = Time.parse(t['ts'])
    end_time = Time.parse(d['ts'])
    assert_within_tolerance(start_time, start,
                            message: 'Start time should be equal to the nearest minute')
    assert_within_tolerance(end_time, finish,
                            message: 'Finish time should be equal to the nearest minute')
  end

  private

  def assert_count_entries(count, shown, message = 'Should be X entries shown')
    assert_equal(count, shown.uncolor.strip.scan(ENTRY_REGEX).count, message)
  end

  def assert_within_tolerance(t1, t2, message: 'Times should be within tolerance of each other', tolerance: 2)
    assert(t1.close_enough?(t2, tolerance: tolerance), message)
  end

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  def doing(*args)
    doing_with_env({ 'DOING_CONFIG' => @config_file, 'DOING_BACKUP_DIR' => @backup_dir }, '--doing_file', @wwid_file,
                   *args)
  end
end
