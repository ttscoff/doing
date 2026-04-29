# frozen_string_literal: true

require 'test_helper'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'doing'

class DoingTemplateStringTest < Test::Unit::TestCase
  def with_terminal_columns(columns)
    original_columns = TTY::Screen.method(:columns)
    original_console = IO.method(:console)
    original_env_columns = ENV.fetch('COLUMNS', nil)
    without_warnings do
      TTY::Screen.singleton_class.send(:define_method, :columns) { columns }
      IO.singleton_class.send(:define_method, :console) { nil }
    end
    ENV.delete('COLUMNS')
    yield
  ensure
    if original_env_columns.nil?
      ENV.delete('COLUMNS')
    else
      ENV['COLUMNS'] = original_env_columns
    end
    without_warnings do
      TTY::Screen.singleton_class.send(:define_method, :columns, original_columns)
      IO.singleton_class.send(:define_method, :console, original_console)
    end
  end

  def with_console_width(width)
    console = Struct.new(:winsize).new([24, width])
    original_console = IO.method(:console)
    original_tty = $stdout.method(:tty?)

    without_warnings do
      IO.singleton_class.send(:define_method, :console) { console }
      $stdout.singleton_class.send(:define_method, :tty?) { true }
    end
    yield
  ensure
    without_warnings do
      IO.singleton_class.send(:define_method, :console, original_console)
      $stdout.singleton_class.send(:define_method, :tty?, original_tty)
    end
  end

  def without_warnings
    original_verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = original_verbose
  end

  def with_columns_env(columns)
    original_columns = ENV.fetch('COLUMNS', nil)
    ENV['COLUMNS'] = columns.to_s
    yield
  ensure
    if original_columns.nil?
      ENV.delete('COLUMNS')
    else
      ENV['COLUMNS'] = original_columns
    end
  end

  def test_star_title_uses_remaining_width
    with_terminal_columns(30) do
      template = '%date | %*title'
      placeholders = {
        'date' => '2026-01-01',
        'title' => 'alpha beta gamma delta epsilon'
      }

      output = Doing::TemplateString.new(template, placeholders: placeholders, disable_color: true, wrap_width: 0).colored.uncolor
      lines = output.split("\n")

      assert_equal(2, lines.length)
      assert_equal('2026-01-01 | alpha beta gamma ', lines[0])
      assert_equal('             delta epsilon ', lines[1])
    end
  end

  def test_placeholders_without_width_use_natural_width
    with_terminal_columns(30) do
      template = '%date | %*title (%section)'
      placeholders = {
        'date' => '2026-01-01',
        'title' => 'alpha beta gamma',
        'section' => 'ABC'
      }

      output = Doing::TemplateString.new(template, placeholders: placeholders, disable_color: true, wrap_width: 0).colored.uncolor
      lines = output.split("\n")

      assert_equal(2, lines.length)
      assert_equal('2026-01-01 | alpha beta  (ABC)', lines[0])
      assert_equal('             gamma ', lines[1])
    end
  end

  def test_star_title_respects_trailing_negative_minimum_width
    with_terminal_columns(36) do
      template = '%date | %*title | %-10section'
      placeholders = {
        'date' => '2026-01-01',
        'title' => 'alpha beta gamma delta',
        'section' => 'ABC'
      }

      output = Doing::TemplateString.new(template, placeholders: placeholders, disable_color: true, wrap_width: 0).colored.uncolor
      lines = output.split("\n")

      assert_equal(3, lines.length)
      assert_equal('2026-01-01 | alpha beta | ABC       ', lines[0])
      assert_equal('             gamma', lines[1])
      assert_equal('             delta ', lines[2])
      assert_equal(36, lines[0].length)
    end
  end

  def test_numeric_width_behavior_is_unchanged
    with_terminal_columns(200) do
      template = '%date | %10title'
      placeholders = {
        'date' => '2026-01-01',
        'title' => 'alpha beta gamma'
      }

      output = Doing::TemplateString.new(template, placeholders: placeholders, disable_color: true, wrap_width: 0).colored.uncolor
      assert_equal("2026-01-01 | alpha beta\n             gamma ", output)
    end
  end

  def test_negative_width_behavior_is_unchanged
    with_terminal_columns(200) do
      template = '%date | %-10title'
      placeholders = {
        'date' => '2026-01-01',
        'title' => 'abc'
      }

      output = Doing::TemplateString.new(template, placeholders: placeholders, disable_color: true, wrap_width: 0).colored.uncolor
      assert_equal('2026-01-01 | abc       ', output)
    end
  end

  def test_multiple_star_placeholders_split_evenly
    with_terminal_columns(40) do
      template = '%*title -- %*section'
      placeholders = {
        'title' => 'alpha beta gamma delta',
        'section' => 'project-rocket-surgery'
      }

      output = Doing::TemplateString.new(template, placeholders: placeholders, disable_color: true, wrap_width: 0).colored.uncolor
      lines = output.split("\n")

      assert_equal(2, lines.length)
      assert_equal('alpha beta gamma   -- project-rocket-surgery', lines[0])
      assert_equal('delta ', lines[1])
    end
  end

  def test_star_title_ignores_template_color_tokens_for_stretch_width
    with_terminal_columns(55) do
      template = '%reset%magenta%20shortdate %boldwhite║ %*title %dark%boldmagenta[%boldwhite%-10section%boldmagenta]%reset'
      placeholders = {
        'shortdate' => '2026-04-28',
        'title' => 'alpha beta gamma delta epsilon',
        'section' => 'ABC'
      }

      output = Doing::TemplateString.new(template, placeholders: placeholders, disable_color: true, wrap_width: 0).colored.uncolor
      lines = output.split("\n")

      assert_equal(2, lines.length)
      assert_equal('          2026-04-28 ║ alpha beta gamma    [ABC       ]', lines[0])
      assert_equal('                       delta epsilon ', lines[1])
    end
  end

  def test_star_title_does_not_reserve_note_placeholder_natural_width
    with_terminal_columns(80) do
      template = '%shortdate ║ %*title [%section] %_14│ note'
      placeholders = {
        'shortdate' => ' 4:09pm',
        'title' => 'This is a deliberately long title that should remain wide despite note content',
        'section' => 'Currently',
        'note' => ['this note should not reduce title width']
      }

      output = Doing::TemplateString.new(template, placeholders: placeholders, disable_color: true, wrap_width: 80).colored.uncolor
      first_line = output.lines.first.chomp

      assert_match(/deliberately long title/, first_line)
      assert_operator(first_line.length, :>, 60)
    end
  end

  def test_star_note_uses_full_block_width_without_shrinking_title
    with_terminal_columns(40) do
      template = '%*title %*_4│ note'
      placeholders = {
        'title' => 'alpha beta gamma delta epsilon zeta',
        'note' => ['one two three four five six seven eight nine ten']
      }

      output = Doing::TemplateString.new(template, placeholders: placeholders, disable_color: true, wrap_width: 0).colored.uncolor
      lines = output.split("\n")

      assert_equal('alpha beta gamma delta epsilon zeta    ', lines[0])
      assert_equal('    │ one two three four five six seven ', lines[1])
      assert_equal('    │ eight nine ten                    ', lines[2])
    end
  end

  def test_star_note_uses_color_from_its_own_template_line
    with_terminal_columns(80) do
      template = "%reset%magenta%20shortdate %boldwhite║ %*title %dark%boldmagenta[%boldwhite%-10section%boldmagenta]%reset\n" \
                 '      %yellow%interval%boldred%duration%dark%blue%*_14│ note'
      placeholders = {
        'shortdate' => '2026-04-28',
        'title' => 'alpha beta',
        'section' => 'Currently',
        'interval' => '',
        'duration' => '',
        'note' => ['note text here']
      }

      output = without_warnings do
        Doing::TemplateString.new(template, placeholders: placeholders, force_color: true, wrap_width: 0).colored
      end
      note_line = output.lines.find { |line| line.include?('│ note text here') }

      assert_include(note_line, "\e[34m│ note text here", 'Note prefix should use the blue color from the note line')
    end
  end

  def test_star_title_prefers_live_console_width_over_small_tty_fallback
    with_terminal_columns(32) do
      with_console_width(120) do
        template = '%20shortdate | %*title [%-10section]'
        placeholders = {
          'shortdate' => '2026-04-28',
          'title' => 'This title should not wrap at thirty-two columns in an interactive terminal',
          'section' => 'Currently'
        }

        output = Doing::TemplateString.new(template, placeholders: placeholders, disable_color: true, wrap_width: 0).colored.uncolor
        first_line = output.lines.first.chomp

        assert_match(/This title should not wrap at thirty-two columns/, first_line)
        assert_operator(first_line.length, :>, 32)
      end
    end
  end

  def test_star_title_prefers_columns_env_over_live_console_width
    with_terminal_columns(120) do
      with_console_width(120) do
        with_columns_env(40) do
          template = '%20shortdate | %*title [%-10section]'
          placeholders = {
            'shortdate' => '2026-04-28',
            'title' => 'This title should wrap at forty columns despite a wider terminal',
            'section' => 'Currently'
          }

          output = Doing::TemplateString.new(template, placeholders: placeholders, disable_color: true,
                                                       wrap_width: 0).colored.uncolor
          first_line = output.lines.first.chomp

          assert_operator(first_line.length, :<=, 40)
          refute_match(/despite a wider terminal/, first_line)
        end
      end
    end
  end

  def test_prefixed_star_title_reserves_implicit_shortdate_and_prefix_width
    with_terminal_columns(100) do
      template = '%reset%cyan%shortdate %boldwhite%*║ title %dark%boldmagenta[%boldwhite%-15section%boldmagenta]%reset ' \
                 '%yellow%interval%boldred%duration%dark%white%*_15│ note'
      placeholders = {
        'shortdate' => '8:26am',
        'title' => 'optimize @terminalwidgetapp @done(2026-04-29 08:26)',
        'section' => 'Projects',
        'interval' => '',
        'duration' => '',
        'note' => []
      }

      output = Doing::TemplateString.new(template, placeholders: placeholders, disable_color: true, wrap_width: 0).colored.uncolor
      first_line = output.lines.first.chomp

      assert_operator(first_line.length, :<=, 100)
      assert_match(/\[Projects\s+\]/, first_line)
    end
  end
end
