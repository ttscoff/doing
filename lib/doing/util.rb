module Doing
  module Util
    ##
    ## @brief      Format human readable time from seconds
    ##
    ## @param      seconds  The seconds
    ##
    def fmt_time(seconds)
      return [0, 0, 0] if seconds.nil?

      if seconds =~ /(\d+):(\d+):(\d+)/
        h = Regexp.last_match(1)
        m = Regexp.last_match(2)
        s = Regexp.last_match(3)
        seconds = (h.to_i * 60 * 60) + (m.to_i * 60) + s.to_i
      end
      minutes = (seconds / 60).to_i
      hours = (minutes / 60).to_i
      days = (hours / 24).to_i
      hours = (hours % 24).to_i
      minutes = (minutes % 60).to_i
      [days, hours, minutes]
    end

    ##
    ## @brief      Test if command line tool is available
    ##
    ## @param      cli   The cli
    ##
    def exec_available(cli)
      if File.exist?(File.expand_path(cli))
        File.executable?(File.expand_path(cli))
      else
        system "which #{cli}", out: File::NULL, err: File::NULL
      end
    end
  end
end
