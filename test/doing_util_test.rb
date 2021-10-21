require 'fileutils'
require 'tempfile'
require 'yaml'
require 'doing-helpers'
require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing/string'
require 'doing/array'
require 'doing/symbol'
require 'doing/time'
require 'doing/item'
require 'doing/note'
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
    item = @wwid.content[@wwid.current_section]['items'][0]
    interval = @wwid.get_interval(item, formatted: false, record: false)
    assert_equal(720, interval, 'Interval should match')
    minutes = interval / 60 % 60
    res = @wwid.fmt_time(interval)
    assert_equal(minutes, res[2], 'Interval array should match')
  end

  def test_link_urls
    res = 'Raw https://brettterpstra.com url'.link_urls
    assert_match(%r{<a href="https://brettterpstra.com" title="Link to brettterpstra.com">\[brettterpstra.com\]</a>}, res, 'Raw URL should be linked matching syntax')
    res = 'Quoted "https://brettterpstra.com" url'.link_urls
    assert_no_match(/<a href/, res, 'Quoted URL should not be linked')
    res = 'Markdown [test](https://brettterpstra.com) url'.link_urls
    assert_no_match(/<a href/, res, 'Markdown URL should not be linked')
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

