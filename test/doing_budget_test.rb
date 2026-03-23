# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'time'
require 'yaml'

require 'helpers/doing-helpers'
require 'test_helper'

# Tests for budget command and budget-aware displays
class DoingBudgetTest < Test::Unit::TestCase
  include DoingHelpers

  def setup
    @tmpdirs = []
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @backup_dir = File.join(@basedir, 'doing_backup')

    base_config = YAML.safe_load(IO.read(File.join(File.dirname(__FILE__), 'test.doingrc')))
    @config_file = File.join(@basedir, 'test.budget.doingrc')
    File.write(@config_file, YAML.dump(base_config))

    @import_file = File.join(File.dirname(__FILE__), 'All Activities 2.json')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_budget_set_and_list
    doing('--yes', 'budget', 'dev', '100h')

    list = doing('--stdout', 'budget').strip
    assert_match(/^dev:\s*100h$/, list, 'Budget list should show dev: 100h')
  end

  def test_budget_affects_tag_totals_and_footer
    doing('import', '--type', 'timing', @import_file)
    doing('--yes', 'budget', 'development', '100h')

    result = doing('--stdout', 'show', '--count', '0', '--totals')
    totals = result.split(/--- Tag Totals ---/)[1]
    assert(totals, 'Tag totals block should be present')

    assert_match(/development:\s+\d{2}:\d{2}:\d{2} \(budget left \d+h(?:\d+m)?\)/,
                 totals,
                 'development tag line should include remaining budget')

    assert_match(/Total tracked: \d{2}:\d{2}:\d{2} \(total budgets left \d+h(?:\d+m)?\)/,
                 result,
                 'Totals footer should include total budgets left')
  end

  def test_totals_format_from_config_and_cli_override
    doing('import', '--type', 'timing', @import_file)

    cfg = YAML.safe_load(File.read(@config_file))
    cfg['totals_format'] = 'hmclock'
    File.write(@config_file, YAML.dump(cfg))

    config_result = doing('--stdout', 'show', '--count', '0', '--totals')
    assert_match(/Total tracked: \d{2,}:\d{2}/, config_result, 'Config totals_format should affect totals output')

    cli_result = doing('--stdout', 'show', '--count', '0', '--totals', '--totals_format', 'clock')
    assert_match(/Total tracked: \d{2}:\d{2}:\d{2}/, cli_result, 'CLI totals_format should override config setting')
  end

  def test_budget_affects_byday_output_footer
    doing('import', '--type', 'timing', @import_file)
    doing('--yes', 'budget', 'development', '100h')

    result = doing('--stdout', 'show', '--output', 'byday')

    assert_match(/Total: \d{2}:\d{2}:\d{2} \(total budgets left \d+h(?:\d+m)?\)/,
                 result,
                 'Byday daily total should include total budgets left when budgets are defined')

    assert_match(/Grand Total: \d{2}:\d{2}:\d{2} \(total budgets left \d+h(?:\d+m)?\)/,
                 result,
                 'Byday grand total should include total budgets left when budgets are defined')
  end

  private

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

