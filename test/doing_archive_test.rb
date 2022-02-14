require 'fileutils'
require 'tempfile'
require 'time'
require 'json'
require 'yaml'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for archive commands
class DoingArchiveTest < Test::Unit::TestCase
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
    import_file = File.join(File.dirname(__FILE__), 'All Activities.json')
    doing('import', '--type', 'timing', import_file)
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_archive
    entries = doing('show').scan(ENTRY_REGEX).count
    result = doing('--stdout', 'archive')
    assert_match(/Archived: #{entries} items from #{@config['current_section']} to Archive/, result, "Should have archived #{entries} items")
    assert_valid_file(@wwid_file)
  end

  def test_archive_tag
    entries = doing('show').scan(ENTRY_REGEX).count
    result = doing('--stdout', 'archive', '--tag', 'podcasting')
    assert_match(/Archived: 2 items/, result, "Should have archived 2 items")
    result = doing('--stdout', 'archive', '--tag', 'writing,bunch', '--bool', 'or')
    assert_match(/Archived: 3 items/, result, "Should have archived 3 items")
    assert_count_entries(5, doing('show', 'archive'), 'Archive should contain 5 items')
    assert_count_entries(entries - 5, doing('show'), "Currently shoud contain #{entries - 5} items")
    assert_valid_file(@wwid_file)
  end

  def test_archive_search
    entries = doing('show').scan(ENTRY_REGEX).count

    result = doing('--stdout', 'archive', '--search', 'Overtired 446')
    assert_match(/New section: "Archive"/, result, 'Archive section should have been added')
    assert_no_match(/Archived: 2 items/, result, 'Case sensitive search should have been triggered and failed')

    result = doing('--stdout', 'archive', '--search', 'overtired 446')
    assert_match(/Archived: 2 items/, result, 'Should have archived 2 items')

    result = doing('--stdout', 'archive', '--search', '/cont.*?ion/')
    assert_match(/Archived: 1 item/, result, 'Regex search should have matched 1 items')

    assert_count_entries(entries - 3, doing('show'), 'Current section should have 3 fewer items items')

    assert_count_entries(3, doing('show', 'archive'), 'Archive should have 3 items')
    assert_valid_file(@wwid_file)
  end

  def test_archive_date
    result = doing('--stdout', 'archive', '--from', '2021-07-19 12am to 2021-07-20 12AM')
    assert_match(/Archived: 2 items/, result, 'Should have archived 2 items')

    result = doing('--stdout', 'archive', '--before', '2021-07-19')
    assert_match(/Archived: 3 items/, result, 'Should have archived 3 items')

    result = doing('--stdout', 'archive', '--after', '2021-07-20')
    assert_match(/Archived: 3 items/, result, 'Should have archived 3 items')
  end

  def test_archive_keep
    result = doing('--stdout', 'archive', '--keep', '5')
    assert_match(/Archived: 3 items/, result, 'Should have archived 3 items')
  end

  def test_archive_destination
    entries = doing('show').scan(ENTRY_REGEX).count
    doing('add_section', 'Testing')
    result = doing('--stdout', 'archive', '-t', 'Testing')
    assert_match(/Moved: #{entries} items from #{@config['current_section']} to Testing/, result, "Should have archived #{entries} items to destination Testing")
  end

  def test_rotate
    rotate_file = @wwid_file.sub(/(\.\w+)$/, "_#{Time.now.strftime('%Y-%m-%d')}\\1")
    doing('rotate', '--keep', '5')
    assert(File.exist?(rotate_file), 'Rotate file should exist')
    assert_count_entries(5, doing('show'), 'Should have 5 entries remaining')
    res = doing_with_env({'DOING_CONFIG' => @config_file}, '--doing_file', rotate_file, 'show')
    assert_count_entries(3, res, 'Rotate file should have 3 entries')
    assert_valid_file(@wwid_file)
    assert_valid_file(rotate_file)
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
    doing_with_env({ 'DOING_CONFIG' => @config_file, 'DOING_BACKUP_DIR' => @backup_dir }, '--doing_file', @wwid_file, *args)
  end
end
