require 'fileutils'
require 'tempfile'
require 'time'

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
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_tag_task
    subject = 'Test new task'
    tag = 'testtag'
    doing('now', subject)
    doing('tag', tag)
    assert_match(/@#{tag}/, doing('last').uncolor, "should have added @#{tag} to last task")
  end

  def test_flag_task
    subject = 'Test new task'
    doing('now', subject)
    doing('flag')
    assert_match(/@flagged/, doing('last').uncolor, 'should have added @flagged to last task')
    doing('flag', '-r')
    assert_no_match(/@flagged/, doing('last').uncolor, 'should have removed @flagged from last task')
  end

  def test_tag_transform
    doing('now', 'testing @deploy @test-4')
    result = doing('show', '-c 1').strip
    assert_match(/@deploy-test\b/, result, 'should have added @deploy-test')
    assert_match(/@dev-test\b/, result, 'should have added @dev-test')
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

