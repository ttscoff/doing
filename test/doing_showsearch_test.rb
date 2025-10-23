# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'time'
require 'yaml'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingShowSearchTest < Test::Unit::TestCase
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
    @import_file = File.join(File.dirname(__FILE__), 'All Activities 2.json')
    @config = YAML.safe_load(IO.read(@config_file))
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_show_command
    subject = 'Test new entry @tag1'
    doing('now', subject)
    subject2 = 'Test new entry 2 @tag2'
    doing('now', subject2)
    result = doing('show').uncolor.strip
    assert_count_entries(2, result, 'There should be 2 entries shown by `doing show`')
    assert_match(/#{subject}\s*$/, result, 'doing show results should include test entry')
    result = doing('show', '@tag1').uncolor.strip
    assert_count_entries(1, result, 'There should be 1 entries shown by `doing show @tag1`')
    assert_match(/#{subject}\s*$/, result, 'doing show @tag1 results should include test entry')
  end

  def test_date_name_sort
    doing('now', '--back', '12pm', 'Z this should be last')
    doing('now', '--back', '12pm', 'AX this should be where?')
    doing('now', '--back', '12pm', 'B this should be third')
    doing('now', '--back', '12pm', '2 this should be first')
    doing('now', '--back', '12pm', 'A this should be second')
    res = doing('show').split(/\n/)
    assert_match(/first/, res[0], 'Number should be first')
    assert_match(/last/, res[-1], 'Z should be last')
  end

  def test_show_tag_boolean
    subject = 'Test new entry @tag1'
    doing('now', subject)
    subject2 = 'Test new entry 2 @tag2'
    doing('now', subject2)
    subject3 = 'Test new entry 3 @tag1 @tag2 @tag3'
    doing('now', subject3)

    result = doing('show', '--tag', 'tag1,tag2', '--bool', 'and').uncolor.strip
    assert_count_entries(1, result, 'There should be 1 entry shown with both @tag1 and @tag2')
    assert_match(/#{subject3}\s*$/, result, 'doing show results should include entry with both @tag1 and @tag2')

    result = doing('show', '--tag', 'tag1,tag2', '--bool', 'or').uncolor.strip
    assert_count_entries(3, result, 'There should be 3 entries shown with either @tag1 or @tag2')
    result = doing('show', '--tag', 'tag2', '--bool', 'not').uncolor.strip
    assert_count_entries(1, result, 'There should be 1 entry shown without @tag2')
    assert_match(/#{subject}\s*$/, result, 'doing show results should include entry without @tag2')
  end

  def test_show_search
    subject = '1 Test entry unique string'
    doing('now', subject)
    subject2 = '2 Test entry Barley hooP'
    doing('now', subject2)
    subject3 = '3 Test entry barley hoop'
    doing('now', subject3)

    result = doing('show', '--search', 'barley hoop')
    assert_count_entries(2, result, 'Search should be case insensitive and match 2 entries')

    result = doing('show', '--search', 'Barley hooP')
    assert_count_entries(1, result, 'Search should be case sensitive (smart case) and match 1 entry')

    result = doing('show', '--search', 'barley hoop', '--case', 'c')
    assert_count_entries(1, result, 'Search should be case sensitive and match 1 entry')

    result = doing('show', '--search', 'barley', '--not')
    assert_count_entries(1, result, 'Search should ignore 2 entries')
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
    doing_with_env({ 'DOING_CONFIG' => @config_file, 'DOING_BACKUP_DIR' => @backup_dir }, '--doing_file', @wwid_file,
                   *args)
  end
end
