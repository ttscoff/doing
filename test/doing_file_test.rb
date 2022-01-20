require 'fileutils'
require 'tempfile'
require 'yaml'
require 'helpers/doing-helpers'
require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing'
# require 'gli'

# Tests for archive commands
class DoingFileTest < Test::Unit::TestCase
  include DoingHelpers
  # include GLI::App

  def setup
    @tmpdirs = []
    @result = ''
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @temp_config = File.join(@basedir, 'temp.doingrc')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
    @backup_dir = File.join(@basedir, 'doing_backup')
    @bad_config = File.join(File.dirname(__FILE__), 'bad.doingrc')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def date_order(file)
    content = IO.read(file)
    dates = content.scan(/(?<=- )(?:\d\d\d\d-\d\d-\d\d \d\d:\d\d)(?= |)/)
    t1 = Time.parse(dates[0])
    t2 = Time.parse(dates[-1])
    t1 < t2 ? 'asc' : 'desc'
  end

  def test_sort_order
    doing('--yes', 'config', 'set', 'doing_file_sort', 'asc')
    setting = doing('config', 'get', 'doing_file_sort', '-o', 'raw').strip
    assert_match(/^asc/, setting, 'doing_file_sort config should be "asc"')
    3.times { |i| doing('now', '--back', "#{i}h", "Test entry #{i}") }
    assert_equal('asc', date_order(@wwid_file), 'File should be in ascending order')

    doing('--yes', 'config', 'set', 'doing_file_sort', 'desc')
    setting = doing('config', 'get', 'doing_file_sort', '-o', 'raw').strip
    assert_match(/^desc/, setting, 'doing_file_sort should be "desc"')
    doing('now', 'Test entry 4')
    assert_equal('desc', date_order(@wwid_file), 'File should be in descending order')

    doing('--yes', 'config', 'set', '-r', 'doing_file_sort')
  end

  private

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  def doing(*args)
    doing_with_env({'DOING_DEBUG' => 'true', 'DOING_CONFIG' => @config_file, 'DOING_BACKUP_DIR' => @backup_dir}, '--doing_file', @wwid_file, *args)
  end
end

