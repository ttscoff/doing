# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'time'
require 'yaml'
require 'json'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for entry modifying commands
class DoingOutputTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_REGEX = /^\d{4}-\d\d-\d\d \d\d:\d\d \|/.freeze
  ENTRY_TS_REGEX = /\s*(?<ts>[^|]+) \s*\|/.freeze
  ENTRY_DONE_REGEX = /@done\((?<ts>.*?)\)/.freeze

  def setup
    @tmpdirs = []
    @result = ''
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @backup_dir = File.join(@basedir, 'doing_backup')
    @config_file = File.join(File.dirname(__FILE__), 'test.doingrc')
    @import_file = File.join(File.dirname(__FILE__), 'All Activities 2.json')
    @config = YAML.safe_load(IO.read(@config_file))
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_invalid_output_format
    # doing('import', '--type', 'timing', @import_file)
    assert_raises(RuntimeError) { doing('show', '-c', '10', '-o', 'falafel') }
  end

  def test_markdown_output
    doing('import', '--type', 'timing', @import_file)
    result = doing('show', '-c', '10', '-o', 'markdown')
    md_rx = /^- \[x?\] (.*?)( \[\*\*\d\d:\d\d:\d\d\*\*\])?/
    assert_equal(10, result.scan(md_rx).count, 'There should be 10 Markdown-formatted entries shown')
  end

  def test_taskpaper_output
    doing('import', '--type', 'timing', @import_file)
    result = doing('show', '-c', '10', '-o', 'taskpaper')
    md_rx = /^- \S.*?@date\(\d\d\d\d-\d\d-\d\d \d\d:\d\d\)$/
    assert_equal(10, result.scan(md_rx).count, 'There should be 10 TaskPaper-formatted entries shown')
  end

  def test_csv_output
    doing('import', '--type', 'timing', @import_file)
    result = doing('show', '-c', '9', '-o', 'csv')
    md_rx = /^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\s[+-]\d{4},.*?,.*?,\d+,[^,]+$/
    assert_equal(9, result.scan(md_rx).count, 'There should be 9 CSV-formatted entries shown')
  end

  def test_html_output
    doing('import', '--type', 'timing', @import_file)
    result = doing('show', '-c', '10', '-o', 'html')
    md_rx = /^<div class='entry'>$/
    assert_equal(10, result.scan(md_rx).count, 'There should be 10 HTML-formatted entries shown')
  end

  def test_timeline_output
    doing('import', '--type', 'timing', @import_file)
    result = doing('show', '-c', '10', '-o', 'timeline')
    md_rx = /"start":"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}"/
    assert_equal(10, result.scan(md_rx).count, 'There should be 10 JSON-formatted entries shown')
    assert_match(/var timeline = new vis.Timeline/, result, 'Output should contain Vis script')
  end

  def test_json_output
    doing('import', '--type', 'timing', @import_file)
    result = doing('show', '-c', '10', '-o', 'json')
    data = JSON.parse(result)
    assert(data, 'Output should be JSON parseable')
    assert_equal(10, data['items'].count, 'There should be 10 items in JSON data')
  end

  def test_user_export_plugin
    doing('import', '--type', 'timing', @import_file)
    result = doing('--stdout', 'show', '-c', '10', '-o', 'trizzer')
    assert_match(/TEST PLUGIN\. On/, result)
  end

  def test_sections_command
    result = doing('sections').uncolor.strip
    assert_match(/^#{@config['current_section']}$/, result,
                 "#{@config['current_section']} should be the only section shown")
  end

  def test_plugins_command
    result = doing('plugins')
    assert_match(/Import plugins:/, result, 'Output should contain import plugins')
    assert_match(/Export plugins:/, result, 'Output should contain export plugins')
    result = doing('plugins', '--type=export')
    assert_match(/\w+\t\w+\t\w+/, result, 'Output should contain tab-separated list')
    result = doing('plugins', '--type=export', '--column')
    assert_match(/\w+\n\w+\n\w+/, result, 'Output should contain newline-separated list')
  end

  def test_recent_command
    # 1:42pm: Did a thing @done(2021-07-05 13:42)
    doing('now', 'Test new entry @tag1')
    doing('now', 'Test new entry 2 @tag2')
    result = doing('recent').uncolor.strip
    rx = /^ *\d+:\d\d(am|pm): (.*?)$/
    matches = result.scan(rx)
    assert_equal(matches.count, 2, 'There should be 2 entries shown by `doing recent`')
  end

  def test_template_command
    result = doing('template', 'haml')
    assert_match(/^!!!\s*\n%html/, result, 'Output should be a HAML template')
    result = doing('template', 'css')
    assert_match(/^body \{/, result, 'Output should be a CSS template')
    result = doing('template', 'markdown')
    assert_match(/^# <%=/, result, 'Output should be an ERB template')
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
    doing_with_env({ 'DOING_CONFIG' => @config_file, 'DOING_BACKUP_DIR' => @backup_dir }, '--doing_file', @wwid_file,
                   *args)
  end
end
