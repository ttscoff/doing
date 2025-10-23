# frozen_string_literal: true

require 'time'
require 'fileutils'
require 'tempfile'
require 'yaml'
require 'helpers/doing-helpers'
require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing'
require 'doing/errors'
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
    @wwid = WWID.new
    config = Doing.config_with(@config_file, { ignore_local: true })
    @wwid.config = config.settings
    @wwid.init_doing_file(@wwid_file)
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_tag_strings
    tag_array = '@test1 +test2 test3 test4(value)'.to_tags.map(&:uncolor)
    assert_equal(['+@test2', '@test1', '@test3', '@test4(value)'], tag_array, 'String should be converted to array of @tags')
    assert_equal('+@test2, @test1, @test3, @test4(value)', tag_array.log_tags.uncolor, 'Array should be output as comma-separated string')
    assert_equal(['+test2', 'test1', 'test3', 'test4(value)'], tag_array.tags_to_array, 'Array should have @ symbols removed')
    assert_equal(tag_array, tag_array.to_tags, 'Array should not be changed')
    assert_equal('@testtag', 'testtag'.add_at, '@ symbol should be added')
    assert_equal('@testtag', '@testtag'.add_at, '@ symbol should not be duped')
    assert_equal('testtag', '@testtag'.remove_at, '@ symbol should be removed')
  end

  def test_format_time
    item = Doing::Item.new(Time.now - 3600, "Test item @done(#{(Time.now - 1200).strftime('%F %R')})",
                           @wwid.current_section)
    distance = (item.end_date - item.date).to_i
    interval = @wwid.get_interval(item, formatted: false, record: false)
    assert_equal(distance, interval, 'Interval should match')
    minutes = interval / 60 % 60
    res = interval.format_time
    assert_equal(minutes, res[2], 'Interval array should match')
  end

  def test_format_time_string
    res = [0, 0, 15].time_string(format: :clock)
    assert_equal('00:00:15', res, 'Format should match')

    res = [0, 0, 15].time_string(format: :natural)
    assert_equal('15 minutes', res, 'Format should match')

    res = [0, 1, 15].time_string(format: :natural)
    assert_equal('1 hour, 15 minutes', res, 'Format should match')

    res = [1, 2, 15].time_string(format: :natural)
    assert_equal('1 day, 2 hours, 15 minutes', res, 'Format should match')

    res = [1, 2, 15].time_string(format: :dhm)
    assert_equal('1d 2h 15m', res, 'Format should match')

    res = [1, 2, 15].time_string(format: :hm)
    assert_equal('  26h 15m', res, 'Format should match')
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

  def test_file_write
    file = File.join(mktmpdir, 'file_write_test.txt')
    content = 'FILE WRITE TEST'
    Util.write_to_file(file, content)
    assert(File.exist?(file), 'Temp file should exist')
    assert_match(/#{content}/, IO.read(file), 'File should contain test content')
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
    doing_with_env({ 'DOING_DEBUG' => 'true', 'DOING_CONFIG' => @config_file, 'DOING_BACKUP_DIR' => @backup_dir },
                   '--doing_file', @wwid_file, *args)
  end
end
