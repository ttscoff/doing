# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'time'
require 'yaml'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingResumeTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_TS_REGEX = /\s*(?<ts>[^|]+) \s*\|/.freeze
  ENTRY_DONE_REGEX = /@done\((?<ts>.*?)\)/.freeze

  def setup
    @tmpdirs = []
    @result = ''
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @backup_dir = File.join(@basedir, 'doing_backup')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
    @config = YAML.safe_load(IO.read(@config_file))
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_resume_entry
    subject = 'Test entry'
    doing('done', subject)
    result = doing('--stdout', '--debug', 'again')

    assert_match(/New entry: added "(.*?)?: #{subject}" to #{@config['current_section']}/, result,
                 'Entry should be added again')
  end

  def test_resume_tag
    3.times { |i| doing('done', '--back', "#{i + 5}m", "Entry #{i + 1} with @tag#{i + 1}") }
    result = doing('--stdout', '--debug', 'again', '--tag', 'tag2')
    assert_match(/New entry: added "(.*?)?: Entry 2 with @tag2"/, result, 'Entry 2 should be repeated')

    result = doing('last').uncolor.strip

    assert_match(/Entry 2 with @tag2/, result, 'Entry 2 should be added again')
    assert_no_match(ENTRY_DONE_REGEX, result, 'Entry 2 should not be @done')
  end

  def test_finish_and_resume
    doing('now', '--back', '5m', 'Entry 4 with @tag4')
    doing('again')
    result = doing('show', '@done').uncolor.strip
    assert_match(/Entry 4 with @tag4 @done/, result, 'Entry 4 should be completed')
    result = doing('last').uncolor.strip
    assert_no_match(ENTRY_DONE_REGEX, result, 'New Entry 4 should not be @done')
  end

  private

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
