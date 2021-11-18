require 'fileutils'
require 'tempfile'
require 'time'
require 'json'

require 'doing-helpers'
require 'test_helper'

# Tests for tagging commands
class DoingTagTest < Test::Unit::TestCase
  include DoingHelpers

  ENTRY_REGEX = /^\d{4}-\d\d-\d\d \d\d:\d\d \|/.freeze

  def setup
    @tmpdirs = []
    @result = ''
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @config_file = File.join(File.dirname(__FILE__), 'test2.doingrc')
    @import_file = File.join(File.dirname(__FILE__), 'All Activities 2.json')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_default_tags
    # Default tag defined in config
    subject = 'Test new entry'
    doing('now', subject)
    assert_match(/@defaulttag(?=[ (]|$)/, doing('last').uncolor, "should have added @defaulttag to last entry")
  end

  def test_tag_entry
    subject = 'Test new entry'
    tag = 'testtag'
    doing('now', subject)
    doing('tag', tag)
    assert_match(/@#{tag}/, doing('last').uncolor, "should have added @#{tag} to last entry")
  end

  def test_flag_entry
    subject = 'Test new entry'
    doing('now', subject)
    doing('flag')
    assert_match(/@flagged/, doing('last').uncolor, 'should have added @flagged to last entry')
    doing('flag', '-r')
    assert_no_match(/@flagged/, doing('last').uncolor, 'should have removed @flagged from last entry')
  end

  def test_tag_transform
    doing('now', 'testing @deploy @test-4')
    result = doing('show', '-c 1').strip
    assert_match(/@deploy-test\b/, result, 'should have added @deploy-test')
    assert_match(/@dev-test\b/, result, 'should have added @dev-test')
  end

  def test_tag_autotag
    doing('now', 'this should autotag brettterpstra.com')
    result = doing('show', '-c 1').strip
    assert_match(/@autotag\b/, result, 'should have added @autotag from whitelist')
    assert_match(/@bt\b/, result, 'should have added @bt from synonyms')
  end

  ##
  ## Test tagging via text and tag search
  ##             results. Imports a Timing.app report.
  ##
  def test_tag_search_results
    json = JSON.parse(IO.read(@import_file))
    search_term = 'oracle'
    test_tag = 'testtag'
    test_tag2 = 'othertag'
    rx = /#{search_term}/i
    matches = json.select do |entry|
      entry['project'] =~ rx || (entry.key?('activityTitle') && entry['activityTitle'] =~ rx)
    end
    target = matches.size

    doing('import', '--type', 'timing', @import_file)

    # Add a tag to items matching search term
    result = doing('--stdout', '--debug', 'tag', '--search', search_term, '-c', '0', '--force', test_tag)
    assert_match(/@#{test_tag} added to #{target} items/, result,
                 'The number of affected items should be the same as were in the imported file')

    # Add a second tag to items matching a tag search for previous tag
    doing('--stdout', 'tag', '--tag', test_tag, '-c', '0', '--force', test_tag2)
    assert_count_entries(target, doing('show', "@#{test_tag2}"), "Should show #{target} tagged matches")

    # Remove the first tag from items matching a tag search for the second tag
    result = doing('--stdout', '--debug', 'tag', '--tag', test_tag2, '-r', '-c', '0', '--force', test_tag)
    assert_match(/@#{test_tag} removed from #{target} items/, result,
                 'The number of affected items should be the same as the tag results')
  end

  def test_tag_date
    doing('now', 'testing tagging with timestamp')
    doing('tag', '--date', 'ermygerd')
    result = doing('show', '@ermygerd')
    assert_match(/@ermygerd\(\d{4}-\d{2}-\d{2} \d{2}:\d{2}\)/, result, 'Result should contain new tag with datestamp')
  end

  private

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

