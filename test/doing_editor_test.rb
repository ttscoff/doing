require 'fileutils'
require 'tempfile'
require 'test_helper'
require 'doing-helpers'

class NoteEditorTest < Test::Unit::TestCase
  include DoingHelpers

  def setup
    @tmpdirs = []
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_new_entry_via_editor
    # doing now without argument should open editor
    subject = 'Test new entry via editor'
    editor_note = 'I would type this into my editor'
    doing_env({ 'EDITOR' => mk_replacing_editor(subject, editor_note) }, 'now')
    assert_match(/#{subject}/, doing('show'), 'should have added task')

    # repeat with -e flag and no note
    subject = 'Testing again via editor'
    editor_note = ''
    doing_env({ 'EDITOR' => mk_replacing_editor(subject, editor_note) }, 'now', '--editor')
    assert_match(/#{subject}/, doing('show'), 'should have added task')
  end

  def test_new_note_via_editor
    # Add a note to the task and replace it
    subject = 'Test new note via editor'
    doing('now', subject)
    assert_match(/#{subject}\s*$/, doing('show'), 'should have added task')

    editor_note = 'I would type this into my editor'
    doing_env({ 'EDITOR' => mk_replacing_editor(subject, editor_note) }, 'note', '-e')

    assert_match(/#{editor_note}\s*$/, doing('show'), 'should add first note')
  end

  def test_replace_note_via_editor
    # Add a note to the task and replace it
    subject = 'Test replace note via editor'
    doing('now', subject)
    assert_match(/#{subject}\s*$/, doing('show'), 'should have added task')

    # Add 2 notes
    note1 = 'add new note #1'
    note2 = 'append new note #2'
    doing('note', note1)
    doing('note', note2)
    assert_doing_shows([
                         [/#{note1}\s*$/, 'Should add note #1'],
                         [/#{note2}\s*$/, 'Should add note #2']
                       ])

    # Replace should replace both
    replacer_note = 'replaced #1 and #2'
    editor = mk_replacing_editor(subject, replacer_note)
    doing_env({ 'EDITOR' => editor }, 'note', '-e')
    assert_doing_shows([
                         [/#{replacer_note}\s*$/, 'replacer note should be visible'],
                         [/#{note1}\s*$/, 'note #1 should have been replaced', :refute],
                         [/#{note2}\s*$/, 'note #2 should have been replaced', :refute]
                       ])
  end

  private

  def assert_doing_shows(matches)
    shown = doing('show').uncolor.strip
    matches.each do |regexp, msg, opt_refute|
      if opt_refute
        refute_match(regexp, shown, msg)
      else
        assert_match(regexp, shown, msg)
      end
    end
  end

  def doing(*args)
    doing_with_env({'DOING_CONFIG' => @config_file}, '--doing_file', @wwid_file, *args)
  end

  def doing_env(env, *args)
    doing_with_env(env, '--config_file', @config_file, '--doing_file', @wwid_file, *args)
  end

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  # Returns path to an executable that takes a file path as input and overwrites
  # the contents of that file with `replace_text`
  def mk_replacing_editor(entry_content, replace_text)
    editor = File.join(@basedir, 'editor')
    File.open(editor, 'w') do |f|
      f.puts <<~FAKE_EDITOR
        #!/bin/sh
        FILE=$1
        echo -e "#{entry_content}\n#{replace_text}" > $FILE
      FAKE_EDITOR
    end
    FileUtils.chmod('+x', editor)
    editor
  end
end
