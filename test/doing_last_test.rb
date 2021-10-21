require 'fileutils'
require 'tempfile'
require 'time'
require 'yaml'

require 'doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingLastTest < Test::Unit::TestCase
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

  def test_last_command
    subject = 'Test new entry @tag1'
    doing('import', @import_file)
    doing('now', subject)
    assert_match(/#{subject} \(at .*?\)\s*$/, doing('last'), 'last entry should be entry just added')
  end

  def test_last_search_and_tag
    unique_keyword = 'jumping jesus'
    unique_tag = 'balloonpants'
    doing('now', "Test new entry @#{unique_tag} sad monkey")
    doing('now', "Test new entry @tag2 #{unique_keyword}")
    doing('now', 'Test new entry @tag3 burly man')

    assert_match(/#{unique_keyword}/, doing('last', '--search', unique_keyword), 'returned entry should contain unique keyword')
    assert_match(/@#{unique_tag}/, doing('last', '--tag', unique_tag), 'returned entry should contain unique tag')
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

