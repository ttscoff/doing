require 'fileutils'
require 'tempfile'
require 'time'
require 'yaml'

require 'doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingShowTest < Test::Unit::TestCase
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
    @import_file = File.join(File.dirname(__FILE__), 'All Activities 2.json')
    @config = YAML.load(IO.read(@config_file))
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

  def first_last_times(res)
    entries = res.strip.split(/\n/)
    first = get_start_date(entries.first.strip)
    last = get_start_date(entries.last.strip)
    [first, last]
  end

  def test_show_sort
    doing('import', '--type', 'timing', @import_file)
    res = doing('show')
    first, last = first_last_times(res)
    assert(first < last, 'Default sort should have first entry earlier than last')

    res = doing('show', '--sort', 'asc')
    first, last = first_last_times(res)
    assert(first < last, 'First entry should be earlier than last')

    res = doing('show', '--sort', 'desc')
    first, last = first_last_times(res)
    assert(first > last, 'First entry should be later than last')
  end

  def test_show_age
    doing('import', '--type', 'timing', @import_file)
    res = doing('show', '--count', '0')
    oldest, newest = first_last_times(res)

    res = doing('show', '--age', 'oldest', '--count', '5')
    first, last = first_last_times(res)
    assert(first == oldest, 'First entry shown should be the oldest entry')
    assert(last < newest, 'Last entry shown should be older than newest')

    res = doing('show', '--age', 'newest', '--count', '5')
    first, last = first_last_times(res)
    assert(last == newest, 'Last entry shown should be the newest entry')
    assert(first > oldest, 'First entry shown should be newer than oldest')
  end

  def test_show_from
    doing('import', '--type', 'timing', @import_file)
    raw = IO.read(@wwid_file)
    date_matches = raw.scan(/^\t+- 2021-09-15/).count
    res = doing('show', '--from', '9/15')
    assert_count_entries(date_matches, res, "There should be #{date_matches} entries shown")
  end

  def test_show_from_range
    doing('import', '--type', 'timing', @import_file)
    raw = IO.read(@wwid_file)
    date_matches = raw.scan(/^\t+- 2021-09-1[456]/).count
    res = doing('show', '--from', 'sept 14 2021 to sept 16 2021')
    assert_count_entries(date_matches, res, "There should be #{date_matches} entries shown")
  end

  def test_show_before
    doing('import', '--type', 'timing', @import_file)
    res = doing('show', '--before', '9/16/21')
    _, last = first_last_times(res)
    cutoff = Time.parse('2021-09-17 00:00:00')
    assert(last < cutoff, 'Last date should be before cutoff')
  end

  def test_show_after
    doing('import', '--type', 'timing', @import_file)
    res = doing('show', '--after', '9/15/21')
    first, _ = first_last_times(res)
    cutoff = Time.parse('2021-09-16 00:00:00')
    assert(first > cutoff, 'Last date should be after cutoff')
  end

  def test_show_before_after
    doing('import', '--type', 'timing', @import_file)
    start = Time.parse('2021-09-13 00:00:00')
    finish = Time.parse('2021-09-14 00:00:00')
    result = doing('show', '--before', '9/14/2021', '--after', '9/12/2021')
    assert_count_entries(5, result, 'There should be 5 entries between specified dates')
    first, last = first_last_times(result)
    assert(first > start, 'First entry should be after start cutoff')
    assert(last < finish, 'Last entry should be before end cutoff')
  end

  def test_show_tag_times
    doing('import', '--type', 'timing', @import_file)
    result = doing('--stdout', 'show', '--count', '0', '--totals')
    totals = result.split(/--- Tag Totals ---/)
    assert(totals[1], 'should have tag totals')
    tags = totals[1].scan(/^\w+:\s+\d{2}:\d{2}:\d{2}$/).count
    assert_equal(11, tags, 'Should be 11 tags listed')
  end

  def test_show_tag_sort
    doing('import', '--type', 'timing', @import_file)
    # Default sort should be name, ascending
    result = doing('--stdout', 'show', '--totals')
    first_tag = result.match(/--- Tag Totals ---\n(\w+?):/)
    assert_match(/badstuff/, first_tag[1], 'First tag should be badstuff')
    # Tag sort by time descending
    result = doing('--stdout', 'show', '--tag_sort=time', '--tag_order=desc', '--totals')
    first_tag = result.match(/--- Tag Totals ---\n(\w+?):/)
    assert_match(/development/, first_tag[1], 'First tag should be development')
    # Tag sort by name ascending
    result = doing('--stdout', 'show', '--tag_sort=name', '--tag_order=asc', '--totals')
    first_tag = result.match(/--- Tag Totals ---\n(\w+?):/)
    assert_match(/badstuff/, first_tag[1], 'First tag should be badstuff')
    # Tag sort by name descending
    result = doing('--stdout', 'show', '--tag_sort=name', '--tag_order=desc', '--totals')
    first_tag = result.match(/--- Tag Totals ---\n(\w+?):/)
    assert_match(/writing/, first_tag[1], 'First tag should be writing')
  end

  def test_show_command_tag_boolean
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

