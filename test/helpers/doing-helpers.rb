require 'open3'
require 'time'

class Time
  def round_time(min = 1)
    t = self
    Time.at(t.to_i - (t.to_i % (min * 60)))
  end
end

class String
  def uncolor
    gsub(/\\e\[[\d;]+m/,'')
  end

  def uncolor!
    replace uncolor
  end
end

module DoingHelpers
  DOING_EXEC = File.join(File.dirname(__FILE__), '..', '..', 'bin', 'doing')

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
end
