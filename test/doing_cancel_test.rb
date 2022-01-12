require 'fileutils'
require 'tempfile'
require 'time'
require 'yaml'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingEntryTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_REGEX = /^\d{4}-\d\d-\d\d \d\d:\d\d \|/.freeze
  ENTRY_TS_REGEX = /\s*(?<ts>[^|]+) \s*\|/.freeze
  ENTRY_DONE_REGEX = /@done\((?<ts>.*?)\)/.freeze

  def setup
    @tmpdirs = []
    @result = ''
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @backup_dir = File.join(@basedir, 'doing_backup')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
    @config = YAML.load(IO.read(@config_file))
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_cancel_entry
    doing('now', 'Test entry')
    doing('cancel')
    assert_match(/@done$/, doing('show'), 'should have @done tag with no timestamp')
  end

  def test_cancel_search
    unique = 'unique string'
    doing('now', '1 Test entry @tag1')
    doing('now', "3 Test entry #{unique}")
    doing('now', '2 Test entry @tag2')
    res = doing('--stdout', 'cancel', '--tag', 'tag1')
    assert_match(/added tag @done to 1 Test/, res, 'should have cancelled tagged entry')
    res = doing('--stdout', 'cancel', '--search', unique)
    assert_match(/added tag @done to 3 Test/, res, 'should have @done tag with no timestamp')
  end

  def test_cancel_multiple_args
    doing('now', 'Test entry')
    assert_raises(RuntimeError, 'Multiple arguments should cause error') { doing('cancel', '1', 'arg2') }
  end

  private

  def assert_matches(matches, shown)
    matches.each do |regexp, msg, opt_refute|
      if opt_refute
        assert_no_match(regexp, shown, msg)
      else
        assert_match(regexp, shown, msg)
      end
    end
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
    doing_with_env({'DOING_CONFIG' => @config_file, 'DOING_BACKUP_DIR' => @backup_dir}, '--doing_file', @wwid_file, *args)
  end
end

