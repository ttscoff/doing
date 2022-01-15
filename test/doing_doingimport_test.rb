require 'fileutils'
require 'tempfile'
require 'time'
require 'json'
require 'yaml'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for import commands
class DoingImportTest < Test::Unit::TestCase
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
    @timing_import_file = File.join(File.dirname(__FILE__), 'All Activities.json')
    @doing_import_file = File.join(File.dirname(__FILE__), 'wwid_import.md')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  ## Doing Import

  def test_doing_import
    result = doing('--stdout', '--debug', 'import', '--type', 'doing', @doing_import_file)
    assert_match(/Imported: 126 items/, result, "Should have imported 126 entries")
    result = doing('--stdout', '--debug', 'import', '--type', 'doing', @doing_import_file)
    assert_match(/Skipped: 126 duplicate items/, result, "Should have skipped 126 duplicate entries")
  end

  def test_doing_import_date_range
    result = doing('--stdout', '--debug', 'import', '--type', 'doing', '--from', '9/29/21', @doing_import_file)
    assert_match(/Imported: 2 items/, result, "Should have imported 2 entries")
  end

  def test_doing_import_search_filter
    result = doing('--stdout', '--debug', 'import', '--type', 'doing', '--search', 'cool.devo.build', @doing_import_file)
    assert_match(/Imported: 3 items/, result, "Should have imported 3 entries")
  end

  def test_doing_import_no_overlap
    doing('done', '--back="2021-10-08 13:00"', '--took="30m"', 'Testing overlapping entry')
    result = doing('--stdout', '--debug', 'import', '--type', 'doing', '--no-overlap', @doing_import_file)
    assert_match(/Skipped: 1 items/, result, "Should have skipped 1 duplicate entries")
    assert_match(/Imported: 125 items/, result, "Should have imported 125 entries")
  end

  def test_user_plugin
    result = doing('--stdout', 'import', '--type', 'tester', @doing_import_file)
    assert_match(/Test with path/, result, 'Test plugin should output success message')
    result = doing('--stdout', 'import', '--type', 'tester')
    assert_match(/Test with no paths/, result, 'Test plugin should output success message')
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

