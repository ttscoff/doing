# frozen_string_literal: true

module ThreadedTestString
  class ::String
    include Doing::Color

    def highlight_errors
      cols = `tput cols`.strip.to_i

      string = dup

      errs = string.scan(/(?<==\n)(?:Failure|Error):.*?(?=\n=+)/m)

      errs.map! do |error|
        err = error.dup

        err.gsub!(%r{^(/.*?/)([^/:]+):(\d+):in (.*?)$}) do
          m = Regexp.last_match
          "#{m[1].white}#{m[2].bold.white}:#{m[3].yellow}:in #{m[4].cyan}"
        end
        err.gsub!(/(Failure|Error): (.*?)\((.*?)\):\n  (.*?)(?=\n)/m) do
          m = Regexp.last_match
          [
            m[1].bold.boldbgred.white,
            m[3].bold.boldbgcyan.white,
            m[2].bold.boldbgyellow.black,
            " #{m[4]} ".bold.boldbgwhite.black.reset
          ].join(':'.boldblack.boldbgblack.reset)
        end
        err.gsub!(/(<.*?>) (was expected to) (.*?)\n( *<.*?>)./m) do
          m = Regexp.last_match
          "#{m[1].bold.green} #{m[2].white} #{m[3].boldwhite.boldbgred.reset}\n#{m[4].bold.white}"
        end
        err.gsub!(/(Finished in) ([\d.]+) (seconds)/) do
          m = Regexp.last_match
          "#{m[1].green} #{m[2].bold.white} #{m[3].green}"
        end
        err.gsub!(/(\d+) (failures)/) do
          m = Regexp.last_match
          "#{m[1].bold.red} #{m[2].red}"
        end
        err.gsub!(/100% passed/) do |m|
          m.bold.green
        end

        err
      end

      errs.join("\n#{('=' * cols).blue}\n")
    end
  end
end
