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

  ## Timing import

  def test_timing_import
    json = JSON.parse(IO.read(@timing_import_file))
    target = json.count
    result = doing('--stdout', '--debug', 'import', '--type', 'timing', @timing_import_file)
    assert_match(/Imported: #{target} items/, result, "Should have imported #{target} entries")
    result = doing('--stdout', '--debug', 'import', '--type', 'timing', @timing_import_file)
    assert_match(/Skipped: #{target} overlapping items/, result, "Should have skipped #{target} duplicate entries")
  end

  def test_timing_import_no_arg
    assert_raises(RuntimeError) { doing('import', '--type', 'timing') }
  end

  def test_timing_import_autotag
    whitelist_word = 'overtired'
    synonym_word = 'guntzel'
    synonym_tag = 'terpzel'

    json = JSON.parse(IO.read(@timing_import_file))
    whitelisted_entries = json.select { |entry| entry['activityTitle'] =~ /#{whitelist_word}/i }.length
    synonym_entries = json.select { |entry| entry['activityTitle'] =~ /#{synonym_word}/i }.length

    doing('import', '--autotag', '--type', 'timing', @timing_import_file)
    whitelisted = doing('show', "@#{whitelist_word}")
    assert_count_entries(whitelisted_entries, whitelisted,
                         "Should have tagged #{whitelisted_entries} entries with @#{whitelist_word}")
    synonyms = doing('show', "@#{synonym_tag}")
    assert_count_entries(synonym_entries, synonyms,
                         "Should have tagged #{synonym_entries} entries with @#{synonym_tag}")
  end

  def test_timing_import_no_overlap
    json = JSON.parse(IO.read(@timing_import_file))
    target = json.count
    doing('done', '--back', '2021-07-22 11:20', '--took', '30m', 'Testing overlapping entry')
    doing('done', '--back', '2021-07-22 15:20', '--took', '30m', 'Testing overlapping entry')
    result = doing('--stdout', '--debug', 'import', '--type', 'timing', '--no-overlap', @timing_import_file)
    assert_match(/Skipped: 1 overlapping item/, result, "Should have skipped #{target} duplicate entries")
    assert_match(/Imported: #{target - 1} items/, result, "Should have imported #{target - 1} entries")
  end

  ## Doing Import

  def test_doing_import
    result = doing('--stdout', '--debug', 'import', '--type', 'doing', @doing_import_file)
    assert_match(/Imported: 126 items/, result, "Should have imported 126 entries")
    result = doing('--stdout', '--debug', 'import', '--type', 'doing', @doing_import_file)
    assert_match(/Skipped: 126 duplicate items/, result, "Should have skipped 126 duplicate entries")
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

