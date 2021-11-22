require 'fileutils'
require 'tempfile'
require 'time'

require 'helpers/doing-helpers'
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
    assert_within_tolerance(Time.parse(m['ts']), (now - (20 * 60)), tolerance: 2, message: 'New entry should be equal to the nearest minute')
  end

  def test_back_strftime
    ts = '2016-03-15 15:32:04 EST'
    doing('now', '--back', ts, 'test strftime format')
    m = doing('show').match(ENTRY_TS_REGEX)
    assert(m)
    assert_within_tolerance(Time.parse(m['ts']), Time.parse(ts), tolerance: 2, message: 'New entry should be equal to the nearest minute')
  end

  def test_back_semantic
    yesterday = (Time.now - (60 * 60 * 24)).strftime('%Y-%m-%d 18:30 %Z')
    doing('now', '--back', 'yesterday 6:30pm', 'test semantic format')
    m = doing('show').match(ENTRY_TS_REGEX)
    assert(m)
    entry_time = Time.parse(m['ts']).strftime('%Y-%m-%d %H:%M %Z')
    assert_equal(entry_time, yesterday, 'new entry is the wrong time')
  end

  private

  def assert_within_tolerance(t1, t2, message: "Times should be within tolerance of each other", tolerance: 2)
    assert(t1.close_enough?(t2, tolerance: tolerance), message)
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
