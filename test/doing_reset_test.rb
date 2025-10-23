# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'time'
require 'yaml'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingResetTest < Test::Unit::TestCase
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

  def test_reset_entry
    subject = 'Test entry'
    doing('done', subject)
    result = doing('--stdout', '--debug', 'reset')

    assert_match(/Reset: Reset and resumed "#{subject}" in #{@config['current_section']}/, result,
                 'Entry should be reset and resumed')
  end

  def test_reset_tag
    3.times { |i| doing('done', '--back', "#{i + 5}m", "Entry #{i + 1} with @tag#{i + 1}") }
    result = doing('--stdout', 'reset', '--tag', 'tag2', '--no-resume', '10am')
    assert_match(/Reset: Reset "Entry 2 with @tag2/, result, 'Entry 2 should be reset')

    result = doing('show', '@tag2').uncolor.strip

    assert_match(/10:00 \|/, result, 'Entry 2 time should be 10am')
    assert_match(ENTRY_DONE_REGEX, result, 'Entry 2 should still be @done')
  end

  def test_reset_from
    doing('now', 'Test entry')
    doing('reset', '--from', '8am to 10am')
    result = doing('last').uncolor.strip
    assert_match(/at 8:00am/, result, 'Should have started at 8am')
    assert_match(/@done\(.*?10:00\)/, result, 'Should have @done date of 10am')
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
