require 'fileutils'
require 'tempfile'
require 'time'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for done commands
class DoingFZFTest < Test::Unit::TestCase
  include DoingHelpers
  def setup
    @tmpdirs = []
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @backup_dir = File.join(@basedir, 'doing_backup')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_fzf_install
    res = doing('--stdout', 'install_fzf', '--reinstall')
    assert_match(/fzf: installed to/, res, 'Should show successful install message')
  end

  def test_fzf_uninstall
    doing('--stdout', 'install_fzf', '--reinstall')
    res = doing('--stdout', 'install_fzf', '--uninstall')
    assert_match(/fzf: removed/, res, 'Should show successful uninstall message')
  end

  private

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  def doing(*args)
    doing_with_env({'DOING_CONFIG' => @config_file, 'DOING_BACKUP_DIR' => @backup_dir}, '--doing_file', @wwid_file, *args)
  end
end
