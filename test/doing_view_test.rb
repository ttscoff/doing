require 'fileutils'
require 'tempfile'
require 'time'
require 'json'

require 'doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingViewTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_REGEX = /^\d{4}-\d\d-\d\d \d\d:\d\d \| DOING TEST/.freeze
  ENTRY_TS_REGEX = /\s*(?<ts>[^|]+) \s*\|/.freeze
  ENTRY_DONE_REGEX = /@done\((?<ts>.*?)\)/.freeze

  def setup
    @tmpdirs = []
    @result = ''
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
    @import_file = File.join(File.dirname(__FILE__), 'All Activities 2.json')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_views_command
    views = doing('views').strip.split(/\s+/).delete_if {|v| v.strip == ''}
    assert_equal(5, views.length, 'Should have 3 views as defined in test configuration')
  end

  def test_view_command
    doing('now', 'Adding a test entry')
    entries = doing('view', 'test')
    assert_count_entries(1, entries, '1 entry should be listed containing DOING TEST (added by the view)')
  end

  def test_view_from_config
    doing('import', '--type', 'timing', @import_file)
    doing('done', '--no-date', 'Adding untimed entry')
    result = doing('--stdout', 'view', 'test2')
    assert_count_entries(6, result, '6 entries should be shown')
    assert_matches([
                   [/Tag Totals/, 'Should contain tag totals', false],
                   [/untimed entry/, 'Should not show untimed entry', true],
                   [/\d\d:\d\d:\d\d/, 'Entries should contain interval', false]
                   ], result)

    result = doing('--stdout', 'view', 'test3')
    assert_count_entries(6, result, '6 entries should be shown')
    assert_matches([
                   [/Tag Totals/, 'Should not contain tag totals', true],
                   [/untimed entry/, 'Should show untimed entry', false],
                   [/\d\d:\d\d:\d\d/, 'Entries should contain interval', false]
                   ], result)
  end

  def test_view_flag_override
    doing('import', '--type', 'timing', @import_file)
    doing('done', '--no-date', 'Adding untimed entry')
    result = doing('--stdout', 'view', '-c', '4', '--totals', '--only_timed', 'test3')
    assert_count_entries(4, result, '4 entries should be shown')
    assert_matches([
                   [/Tag Totals/, 'Should contain tag totals', false],
                   [/untimed entry/, 'Should not show untimed entry', true],
                   [/\d\d:\d\d:\d\d/, 'Entries should contain interval', false]
                   ], result)

    result = doing('--stdout', 'view', '--no-times', 'test3')
    assert_matches([
                   [/\d\d:\d\d:\d\d/, 'Entries should not contain intervals', true]
                   ], result)
  end

  def test_view_tag_sort
    doing('import', '--type', 'timing', @import_file)
    result = doing('--stdout', 'view', 'test2')
    first_tag = result.match(/--- Tag Totals ---\n(\w+?):/)
    assert_match(/development/, first_tag[1], 'First tag should be development')

    result = doing('--stdout', 'view', '--tag_sort=name', '--tag_order=asc', 'test2')
    first_tag = result.match(/--- Tag Totals ---\n(\w+?):/)
    assert_match(/bunch/, first_tag[1], 'First tag should be bunch')
  end

  def test_view_date_limit
    doing('import', '--type', 'timing', @import_file)
    result = doing('view', '--before', '9/14/2021', '--after', '9/12/2021', 'test2')
    assert_count_entries(5, result, 'There should be 5 entries between specified dates')
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
    doing_with_env({'DOING_CONFIG' => @config_file}, '--doing_file', @wwid_file, *args)
  end
end

