require 'fileutils'
require 'tempfile'
require 'time'
require 'json'

require 'doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
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
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
    @import_file = File.join(File.dirname(__FILE__), 'All Activities.json')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_import
    json = JSON.parse(IO.read(@import_file))
    target = json.count
    result = doing('--stdout', 'import', @import_file)
    assert_match(/Imported #{target} items/, result, "Should have imported #{target} entries")
    result = doing('--stdout', 'import', @import_file)
    assert_match(/Skipped #{target} items/, result, "Should have skipped #{target} duplicate entries")
  end

  def test_import_no_overlap
    json = JSON.parse(IO.read(@import_file))
    target = json.count
    doing('done', '--back="2021-07-22 11:20"', '--took="30m"', 'Testing overlapping entry')
    result = doing('--stdout', 'import', '--no-overlap', @import_file)
    assert_match(/Skipped 1 items/, result, "Should have skipped #{target} duplicate entries")
    assert_match(/Imported #{target - 1} items/, result, "Should have imported #{target - 1} entries")
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
    doing_with_env({}, '--config_file', @config_file, '--doing_file', @wwid_file, *args)
  end
end

