require 'fileutils'
require 'tempfile'
require 'time'
require 'yaml'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingNoteTest < Test::Unit::TestCase
  include DoingHelpers

  def setup
    @tmpdirs = []
    @result = ''
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @backup_dir = File.join(@basedir, 'doing_backup')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
    @import_file = File.join(File.dirname(__FILE__), 'All Activities 2.json')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_note_add_remove
    subject = 'Test new entry @tag1'
    note = 'This is a test note'
    doing('now', subject)
    doing('note', note)
    assert_match(/#{subject}.*?\n#{note}$/, doing('last'), 'last entry should have a note')
    doing('note', '--remove')
    assert_no_match(/#{subject}.*?\n#{note}$/, doing('last'), 'last note should be removed')
  end

  def test_note_append_replace
    subject = 'Test new entry @tag1'
    note = 'This is a test note'
    note2 = 'This is another test note'
    note3 = 'This is a replaced test note'
    doing('now', subject)
    doing('note', note)
    doing('note', note2)
    assert_match(/#{subject}.*?\n#{note}\s*\n#{note2}\s*$/, doing('last'), 'last entry should have 2 notes')
    doing('note', '--remove', note3)
    assert_match(/#{subject}.*?\n#{note3}\s*$/, doing('last'), 'last entry should only have note 3')
    assert_no_match(/#{note2}/, doing('last'), 'Note 2 should be removed')
  end

  def test_parenthetical_note
    subject = 'Test new entry @tag1'
    note = 'This is a test note'
    entry = "#{subject} (#{note})"
    doing('now', entry)
    assert_match(/#{subject}\n\s*#{note}\s*$/, doing('show'), 'Parenthetical should be a note')
  end

  def test_note_search
    unique_keyword = 'jumping jesus'
    unique_title = "Test new entry #{unique_keyword} sad monkey"
    note = 'This is a test note'
    doing('now', unique_title)
    doing('now', "Test new entry @tag2 koolaid")
    doing('now', 'Test new entry @tag3 burly man')
    doing('note', '--search', unique_keyword, note)
    assert_match(/.*?#{unique_keyword}.*?\n\t#{note}/, doing('show'), 'Tagged entry should contain note')
  end

  def test_note_tag
    unique_tag = 'balloonpants'
    unique_title = "Test new entry @#{unique_tag} sad monkey"
    note = 'This is a test note'
    doing('now', unique_title)
    doing('now', "Test new entry @tag2 jumping jesus")
    doing('now', 'Test new entry @tag3 burly man')
    doing('note', '--tag', unique_tag, note)
    assert_match(/#{unique_title}\n\t#{note}/, doing('show'), 'Tagged entry should contain note')
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
