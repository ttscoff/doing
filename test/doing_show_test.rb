require 'fileutils'
require 'tempfile'
require 'time'
require 'yaml'

require 'helpers/doing-helpers'
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

  # combined to save imports, no command modifies import file
  def test_show_options
    doing('import', '--type', 'timing', @import_file)

    # Test show --sort
    res = doing('show')
    first, last = first_last_times(res)
    assert(first < last, 'Default sort should have first entry earlier than last')

    res = doing('show', '--sort', 'asc')
    first, last = first_last_times(res)
    assert(first < last, 'First entry should be earlier than last')

    res = doing('show', '--sort', 'desc')
    first, last = first_last_times(res)
    assert(first > last, 'First entry should be later than last')

    # Test show --age
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

    # test show --totals
    result = doing('--stdout', 'show', '--count', '0', '--totals')
    totals = result.split(/--- Tag Totals ---/)
    assert(totals[1], 'should have tag totals')
    tags = totals[1].scan(/^\w+:\s+\d{2}:\d{2}:\d{2}$/).count
    assert_equal(11, tags, 'Should be 11 tags listed')

    # test show --tag_sort
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

  def first_last_times(res)
    entries = res.strip.split(/\n/)
    first = get_start_date(entries.first.strip)
    last = get_start_date(entries.last.strip)
    [first, last]
  end

  def doing(*args)
    doing_with_env({'DOING_CONFIG' => @config_file}, '--doing_file', @wwid_file, *args)
  end
end

