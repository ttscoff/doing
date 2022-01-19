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
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
    @backup_dir = File.join(@basedir, 'doing_backup')
    @config = YAML.load(IO.read(@config_file))
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_new_entry
    # Add an entry
    subject = 'Test new entry @tag1'
    doing('now', subject)
    assert_match(/#{subject}\s*$/, doing('show', '-c', '1'), 'should have added entry')
    assert_valid_file(@wwid_file)
  end

  def test_new_entry_finishing_last
    subject = 'Test new entry'
    subject2 = 'Another entry'
    doing('now', subject)
    doing('now', '--finish_last', subject2)
    assert_matches([
      [/#{subject} @done/, 'First entry should be @done'],
      [/#{subject2}\s*$/, 'Second entry should be added']
    ], doing('show'))
    assert_valid_file(@wwid_file)
  end

  def test_section_rejects_empty_args
    assert_raises(RuntimeError) { doing('now', '--section') }
  end

  def test_guess_section
    doing('add_section', 'Test Section')
    res = doing('--stdout', '--debug', 'show', 'Test').strip
    assert_match(/Assuming "Test Section"/, res, 'Should have guessed Test Section')
    assert_valid_file(@wwid_file)
  end

  def test_invalid_section
    assert_raises(RuntimeError, 'Should be invalid section') { doing('--default', 'show', 'Invalid Section') }
  end

  def test_add_section
    doing('add_section', 'Test Section')
    assert_match(/^Test Section$/, doing('sections', '-c'), 'should have added section')
    assert_valid_file(@wwid_file)
  end

  def test_add_to_section
    section = 'Test Section'
    subject = 'Test entry @testtag'
    doing('add_section', section)
    doing('now', '--section', section, subject)
    assert_match(/#{subject}/, doing('show', section), 'Entry should exist in new section')
    assert_valid_file(@wwid_file)
  end

  def test_later_entry
    subject = 'Test later entry'
    result = doing('--stdout', '--yes', 'later', subject)
    assert_matches([
      [/New entry: added "(.*?)?: #{subject}" to Later/, 'should have added entry to Later section']
    ], result)
    assert_count_entries(1, doing('show', 'later'), 'There should be one later entry')
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

