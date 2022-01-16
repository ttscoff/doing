# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'yaml'
require 'helpers/doing-helpers'
require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing'
# require 'gli'

# Tests for archive commands
class DoingUtilTest < Test::Unit::TestCase
  include DoingHelpers
  # include GLI::App
  include Doing

  def setup
    @tmpdirs = []
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
    @config = Util.safe_load_file(@config_file)
    @backup_dir = File.join(@basedir, 'doing_backup')
    import_file = File.join(File.dirname(__FILE__), 'All Activities 2.json')
    doing('import', '--type', 'timing', import_file)
    @wwid = WWID.new
    config = Doing.config_with(@config_file, { ignore_local: true })
    @wwid.config = config.settings
    @wwid.init_doing_file(@wwid_file)
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_format_time
    item = @wwid.content.in_section(@wwid.config['current_section'])[0]
    distance = (item.end_date - item.date).to_i
    interval = @wwid.get_interval(item, formatted: false, record: false)
    assert_equal(distance, interval, 'Interval should match')
    minutes = interval / 60 % 60
    res = interval.format_time
    assert_equal(minutes, res[2], 'Interval array should match')
  end

  def test_link_urls
    res = 'Raw https://brettterpstra.com url'.link_urls
    assert_match(%r{<a href="https://brettterpstra.com" title="Link to brettterpstra.com">\[brettterpstra.com\]</a>},
                 res, 'Raw URL should be linked matching syntax')
    res = 'Quoted "https://brettterpstra.com" url'.link_urls
    assert_no_match(/<a href/, res, 'Quoted URL should not be linked')
    res = 'Markdown [test](https://brettterpstra.com) url'.link_urls
    assert_no_match(/<a href/, res, 'Markdown URL should not be linked')
  end

  def test_exec_available
    assert(Util.exec_available('ls'), 'ls should be available on any system')
  end

  private

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  def doing(*args)
    doing_with_env({ 'DOING_DEBUG' => 'true', 'DOING_CONFIG' => @config_file, 'DOING_BACKUP_DIR' => @backup_dir }, '--doing_file', @wwid_file, *args)
  end
end

