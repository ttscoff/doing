require 'fileutils'
require 'tempfile'
require 'time'
require 'json'

require 'doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingViewTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_REGEX = /^\d{4}-\d\d-\d\d \d\d:\d\d \| DOING TEST/.freeze
  ENTRY_TS_REGEX = /\s*(?<ts>[^|]+) \s*\|/.freeze
  ENTRY_DONE_REGEX = /@done\((?<ts>.*?)\)/.freeze

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

  def test_views
    views = doing('views').split(/\s+/).delete_if {|v| v.strip == ''}.map(&:strip)
    assert_equal(3, views.length, 'Should have 3 views in configuration')
  end

  def test_view
    doing('now', 'Adding a test entry')
    entries = doing('view', 'test')
    assert_count_entries(1, entries, '1 entry should be listed containing DOING TEST')
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
    doing_with_env({}, '--config_file', @config_file, '--doing_file', @wwid_file, *args)
  end
end

