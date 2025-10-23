# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'time'
require 'yaml'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingShowDateTest < Test::Unit::TestCase
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

  def test_show_date
    doing('import', '--type', 'timing', @import_file)
    raw = IO.read(@wwid_file)
    # test show --from
    date_matches = raw.scan(/^\t+- 2021-09-15/).count
    res = doing('show', '--from', '9/15/21')
    assert_count_entries(date_matches, res, "There should be #{date_matches} entries shown")

    # test show --from range
    date_matches = raw.scan(/^\t+- 2021-09-1[456]/).count
    res = doing('show', '--from', 'sept 14 2021 to sept 16 2021')
    assert_count_entries(date_matches, res, "There should be #{date_matches} entries shown")

    # test show --before
    res = doing('show', '--before', '9/16/21')
    _, last = first_last_times(res)
    cutoff = Time.parse('2021-09-17 00:00:00')
    assert(last < cutoff, 'Last date should be before cutoff')

    # test show --after
    res = doing('show', '--after', '9/15/21')
    first, = first_last_times(res)
    cutoff = Time.parse('2021-09-16 00:00:00')
    assert(first > cutoff, 'Last date should be after cutoff')

    # test show --before --after
    start = Time.parse('2021-09-13 00:00:00')
    finish = Time.parse('2021-09-14 00:00:00')
    result = doing('show', '--before', '9/14/2021', '--after', '9/12/2021')
    assert_count_entries(5, result, 'There should be 5 entries between specified dates')
    first, last = first_last_times(result)
    assert(first > start, 'First entry should be after start cutoff')
    assert(last < finish, 'Last entry should be before end cutoff')
  end

  private

  def first_last_times(res)
    entries = res.strip.split(/\n/)
    first = get_start_date(entries.first.strip)
    last = get_start_date(entries.last.strip)
    [first, last]
  end

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
