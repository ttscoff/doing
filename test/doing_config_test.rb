require 'fileutils'
require 'tempfile'
require 'yaml'
require 'helpers/doing-helpers'
require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing'
# require 'gli'

# Tests for archive commands
class DoingConfigTest < Test::Unit::TestCase
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

  def test_missing_config
    res = doing_with_env({'DOING_DEBUG' => 'true', 'DOING_CONFIG' => @temp_config}, '--stdout', '--doing_file', @wwid_file)
    assert_match(/Config file written to .*?#{File.basename(@temp_config)}/, res, 'Missing config file should have been written')
  end

  # def test_bad_config
  #   res = doing_with_env({'DOING_DEBUG' => 'true', 'DOING_CONFIG' => @bad_config}, '--stdout', 'config', '-d', 'doing_file')
  #   assert_match(/Error reading default configuration/, res, 'Non-YAML file should log an error')
  #   assert_match(/what_was_i_doing.md/, res, 'Default config should have been loaded')
  # end

  def test_user_config
    user_config = YAML.load(IO.read(@config_file))
    path = ['plugins', 'say', 'say_voice']
    setting = user_config.dig(*path)
    res = doing('config', '--dump', "#{path.join('.')}")
    assert_match(/#{setting}/, res, 'Correct config setting should be returned to STDOUT')
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

