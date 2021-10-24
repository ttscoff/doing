require 'open3'
require 'time'
$LOAD_PATH.unshift File.join(__dir__, '..', '..', 'lib')
require 'doing/colors'
require 'doing/string'
require 'doing/errors'

module DoingHelpers
  DOING_EXEC = File.join(File.dirname(__FILE__), '..', '..', 'bin', 'doing')
  TEST_CONFIG = File.join(File.dirname(__FILE__), '..', 'test.doingrc')

  def trunc_minutes(ts)
    ts.to_i / 60 * 60
  end

  def doing_with_env(env, *args)
    pread(env, DOING_EXEC, *args)
  end

  def pread(env, *cmd)
    out, err, status = Open3.capture3(env, *cmd)
    unless status.success?
      raise [
        "Error (#{status}): #{cmd.inspect} failed", "STDOUT:", out.inspect, "STDERR:", err.inspect
      ].join("\n")
    end

    out
  end

  def assert_count_entries(count, shown, message = 'Should be X entries shown')
    assert_equal(count, shown.uncolor.strip.scan(/^\d{4}-\d\d-\d\d \d\d:\d\d \|/).count, message)
  end

  def get_start_date(string)
    date_str = string.match(/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}) *\|/)

    return false unless date_str

    Time.parse(date_str[1])
  end

  ##
  ## @brief      Time helpers
  ##
  class ::Time
    def round_time(min = 1)
      t = self
      Time.at(t.to_i - (t.to_i % (min * 60)))
    end

    def close_enough?(other_time, tolerance: 2)
      t = self
      diff = if t > other_time
               t - other_time
             else
               other_time - t
             end
      diff / 60 < tolerance
    end
  end
end
