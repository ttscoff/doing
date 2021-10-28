module Doing
  module Util
    class << self
      ##
      ## @brief      Test if command line tool is available
      ##
      ## @param      cli   (String) The name or path of the cli
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
end
