require 'fileutils'
require 'tempfile'
require 'time'

require 'doing-helpers'
require 'test_helper'

class DoingTaskTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_TS_REGEX = /\s*(?<ts>[^\|]+) \s*\|/
  ENTRY_DONE_REGEX = /@done\((?<ts>.*?)\)/

  def setup
    @tmpdirs = []
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @config_file = File.join(File.dirname(__FILE__),'test.doingrc')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_section_rejects_empty_args
    assert_raises(RuntimeError) { doing('now', '--section') }
  end

  def test_new_task
    # Add a task
    subject = 'Test new task @tag1'
    doing('now', subject)
    assert_match(/#{subject}\s*$/, doing('show', '-c 1'), 'should have added task')
  end

  # def test_finish_task
  #   doing('finish')
  #   r = uncolor(doing('last')).strip
  #   m = r.match(ENTRY_DONE_REGEX)
  #   assert(m, "#{r} should have @done timestamp")
  #   assert_equal(Time.parse(m['ts']).to_i, trunc_minutes(now - 20 * 60),
  #       'New task should be equal to the nearest minute')
  # end

  private

  def uncolor(string)
    string.gsub(/\\e\[[\d;]+m/,'')
  end

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  def trunc_minutes(ts)
    ts.to_i / 60 * 60
  end

  def doing(*args)
    doing_with_env({}, '--config_file', @config_file, '--doing_file', @wwid_file, *args)
  end
end

