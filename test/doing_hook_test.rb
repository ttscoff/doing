require 'fileutils'
require 'tempfile'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for archive commands
class DoingHookTest < Test::Unit::TestCase
  include DoingHelpers
  
  def setup
    @tmpdirs = []
    @result = ''
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @backup_dir = File.join(@basedir, 'doing_backup')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_hook_register
    assert_matches([
        [/Hook Manager: Registered post_write hook/, "Should have registered a post_write hook", false],
        [/Hook Manager: Registered post_read hook/, "Should have registered a post_read hook", false]
      ],
      doing('last'))
  end

  def test_read_hook

    assert_matches([[/Post read hook!/, 'Should have triggered post_read hook', false],
                   [/Post write hook!/, 'Should not have triggered post_write hook', true]
                 ], doing('last'))
  end

  def test_write_hook
    assert_matches([[/Post write hook!/, 'Should have triggered post_write hook', false]], doing('now', 'testing hooks'))
  end


  private

  def assert_matches(matches, shown)
    matches.each do |regexp, msg, opt_refute|
      if opt_refute
        assert_no_match(regexp, shown, msg)
      else
        assert_match(regexp, shown, msg)
      end
    end
  end

  def assert_count_entries(count, shown, message = 'Should be X entries shown')
    assert_equal(count, shown.uncolor.strip.scan(ENTRY_REGEX).count, message)
  end

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  def doing(*args)
    doing_with_env({'HOOK_TEST' => 'true', 'DOING_PLUGIN_DEBUG' => 'true', 'DOING_CONFIG' => @config_file, 'DOING_BACKUP_DIR' => @backup_dir}, '--doing_file', @wwid_file, '--stdout', *args)
  end
end
