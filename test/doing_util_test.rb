require 'fileutils'
require 'tempfile'
require 'yaml'
require 'doing-helpers'
require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing/plugin_manager'
require 'doing/util'
require 'doing/wwid'
# require 'gli'

# Tests for archive commands
class DoingUtilTest < Test::Unit::TestCase
  include DoingHelpers
  # include GLI::App
  include Doing

  def setup
    @tmpdirs = []
    @result = ''
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
    @config = YAML.load(IO.read(@config_file))
    import_file = File.join(File.dirname(__FILE__), 'All Activities 2.json')
    doing('import', import_file)
    @wwid = WWID.new
    @wwid.config_file = @config_file

    @wwid.configure({ ignore_local: true })
    @wwid.init_doing_file(@wwid_file)
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_format_time
    item = @wwid.content[@wwid.current_section]['items'][-1]
    interval = @wwid.get_interval(item, formatted: false, record: false)
    assert_equal(360, interval, 'Interval should match')
    res = @wwid.fmt_time(interval)
    assert_equal([0,0,6], res, 'Interval array should match')
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

