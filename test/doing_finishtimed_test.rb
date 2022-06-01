require 'fileutils'
require 'tempfile'
require 'time'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for done commands
class DoingFinishTimedTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_REGEX = /^\d{4}-\d\d-\d\d \d\d:\d\d \|/.freeze
  ENTRY_TS_REGEX = /\s*(?<ts>[^|]+) \s*\|/.freeze
  ENTRY_DONE_REGEX = /@done\((?<ts>.*?)\)/.freeze

  def setup
    @tmpdirs = []
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @backup_dir = File.join(@basedir, 'doing_backup')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
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

    assert_within_tolerance((start + (60 * 60)), Time.parse(d['ts']),
                            message: 'Finished time should be 60 minutes after start')

    assert_within_tolerance(start, Time.now - (60 * 60),
                            message: 'Start time should be backdated 60 minutes')
  end

  def test_finish_at
    start_at = Time.now.strftime('%Y-%m-%d 01:45 %Z')
    finish_at = Time.now.strftime('%Y-%m-%d 02:15 %Z')
    doing('now', '--back', '1:45am', 'test finish at')
    doing('finish', '--at', '2:15am', '--search', 'test finish at')
    last = doing('show')
    m = last.match(ENTRY_DONE_REGEX)
    assert(m)
    entry_time = Time.parse(m['ts']).strftime('%Y-%m-%d %H:%M %Z')
    assert_equal(entry_time, finish_at, 'new entry has wrong finish time')
    m = last.match(ENTRY_TS_REGEX)
    assert(m)
    entry_time = Time.parse(m['ts']).strftime('%Y-%m-%d %H:%M %Z')
    assert_equal(entry_time, start_at, 'new entry has wrong start time')
  end

  private

  def assert_count_entries(count, shown, message = 'Should be X entries shown')
    assert_equal(count, shown.uncolor.strip.scan(ENTRY_REGEX).count, message)
  end

  def assert_within_tolerance(t1, t2, message: "Times should be within tolerance of each other", tolerance: 2)
    assert(t1.close_enough?(t2, tolerance: tolerance), message)
  end

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  def doing(*args)
    doing_with_env({'DOING_CONFIG' => @config_file, 'DOING_BACKUP_DIR' => @backup_dir}, '--doing_file', @wwid_file, *args)
  end
end
