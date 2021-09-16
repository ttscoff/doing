require 'fileutils'
require 'tempfile'
require 'time'
require 'json'

require 'doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingTagTest < Test::Unit::TestCase
  include DoingHelpers

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

  ##
  ## @brief      Test tagging via text and tag search
  ##             results. Imports a Timing.app report.
  ##
  def test_tag_search_results
    json = JSON.parse(IO.read(@import_file))
    search_term = 'oracle'
    test_tag = 'testtag'
    test_tag_2 = 'othertag'
    rx = /#{search_term}/i
    matches = json.select do |entry|
      entry['project'] =~ rx || (entry.key?('activityTitle') && entry['activityTitle'] =~ rx)
    end
    target = matches.size

    doing('import', @import_file)
    # Add a tag to items matching search term
    result = doing('--stdout', 'tag', '--search', search_term, '-c', '0', '--force', test_tag)
    assert_equal(target, result.strip.split(/\n/).size, 'The number of affected items should be the same as were in the imported file')
    # Add a second tag to items matching a tag search for previous tag
    result = doing('--stdout', 'tag', '--tag', test_tag, '-c', '0', '--force', test_tag_2)
    assert_equal(target, result.strip.split(/\n/).size, 'The number of affected items should be the same as the number of search results')
    # Remove the first tag from items matching a tag search for the second tag
    result = doing('--stdout', 'tag', '--tag', test_tag_2, '-r', '-c', '0', '--force', test_tag)
    assert_equal(target, result.strip.split(/\n/).size, 'The number of affected items should be the same as the tag results')
  end

  def test_tag_date
    doing('now', 'testing tagging with timestamp')
    doing('tag', '--date', 'ermygerd')
    result = doing('show', '@ermygerd')
    assert_match(/@ermygerd\(\d{4}-\d{2}-\d{2} \d{2}:\d{2}\)/, result, 'Result should contain new tag with datestamp')
  end

  private

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  def doing(*args)
    doing_with_env({}, '--config_file', @config_file, '--doing_file', @wwid_file, *args)
  end
end

