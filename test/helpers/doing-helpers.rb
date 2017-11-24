require 'open3'

module DoingHelpers
  DOING_EXEC = File.join(File.dirname(__FILE__), '..', '..', 'bin', 'doing')

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
