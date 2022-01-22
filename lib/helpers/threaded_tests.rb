#!/usr/bin/env ruby

require 'tty-spinner'
require 'tty-progressbar'
require './lib/doing'
require 'open3'
require 'shellwords'

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

class ThreadedTests
  include Doing::Color

  def run(pattern: '*', max_threads: 8, max_tests: 0)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    max_threads = 1000 if max_threads == 0

    c = Doing::Color
    c.coloring = true

    pattern = "test/doing_*#{pattern}*_test.rb"

    tests = Dir.glob(pattern)

    if max_tests > 0
      tests = tests.slice(0, max_tests - 1)
    end

    puts "#{tests.count} test files".boldcyan

    banner = [
      'Running tests '.bold.white,
      '['.black,
      ':bar'.boldcyan,
      '] '.black,
      'T'.green,
      '/'.white,
      'A'.cyan,
      ' ('.white,
      max_threads.to_s.bold.magenta,
      ' threads)'.white
    ].join('')
    progress = TTY::ProgressBar::Multi.new(banner,
                                           width: 12,
                                           hide_cursor: true)
    @children = []
    tests.each do |t|
      test_name = File.basename(t, '.rb').sub(/doing_(.*?)_test/, '\1')
      new_sp = progress.register("[#{':bar'.cyan}] #{test_name.bold.white}:status",
                                 total: 4, width: 1, head: ' ', unknown: ' ', hide_cursor: true, clear: true)
      @children.push([test_name, new_sp, nil])
    end

    @elapsed = 0.0
    @test_total = 0
    @assrt_total = 0
    @error_out = []
    # progress.start
    @threads = []
    @running_tests = []

    begin
      while @children.count.positive?

        slices = @children.slice!(0, max_threads)
        slices.each { |c| c[1].start }
        slices.each do |s|
          @threads << Thread.new do
            run_test(s)
          end
        end

        @threads.each { |t| t.join }
      end

      finish_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      progress.finish

      output = []
      if @error_out.count.positive?
        output << c.boldred("#{@error_out.count} Issues")
      else
        output << c.green('Success')
      end
      output << c.green("#{@test_total} tests")
      output << c.cyan("#{@assrt_total} assertions")
      output << c.yellow("#{(finish_time - start_time).round(3)}s")
      puts output.join(', ')

      puts @error_out.join("\n----\n".boldwhite) if @error_out.count.positive?
    rescue
      progress.stop
    end
  end

  def run_test(s)

    bar = s[1]
    bar.advance(status: ": #{'running'.green}")

    if @running_tests.count.positive?
      prev_bar = @running_tests[-1][1]
      unless prev_bar.complete?
        prev_bar.update(head: ' ', unfinished: ' ')
        prev_bar.advance(status: ": #{'running'.green}")
      end
    end

    @running_tests.push(s)


    out, _err, status = Open3.capture3(ENV, 'rake', "test:#{s[0]}", stdin_data: nil)
    unless status.success?
      m = out.match(/(?<fail>\d+) failures, (?<err>\d+) errors/)
      status = ": #{m['fail'].bold.red} #{'failures'.red}, #{m['err'].bold.red} #{'errors'.red}"
      bar.update(head: '✖'.boldred)
      bar.advance(head: '✖'.boldred, status: status)

      # errs = out.scan(/(?:Failure|Error): [\w_]+\((?:.*?)\):(?:.*?)(?=\n=======)/m)
      @error_out.push(out.highlight_errors)
      bar.finish

      next_test
      Thread.exit
    end

    time = out.match(/^Finished in (?<time>\d+\.\d+) seconds\./)
    count = out.match(/^(?<tests>\d+) tests, (?<assrt>\d+) assertions, (?<fails>\d+) failures, (?<errs>\d+) errors/)
    status = [
      ': ',
      count['tests'].green,
      '/',
      count['assrt'].cyan,
      # ' (',
      # count['fails'].to_i == 0 ? '-'.dark.white.reset : count['fails'].bold.red,
      # '/',
      # count['errs'].to_i == 0 ? '-'.dark.white.reset : count['errs'].bold.red,
      # ') ',
      ' ',
      time['time'].to_f.round(3).to_s.yellow,
      's'
    ].join('')
    bar.update(head: '✔'.boldgreen)
    bar.advance(head: '✔'.boldgreen, status: status)
    @test_total += count['tests'].to_i
    @assrt_total += count['assrt'].to_i
    @elapsed += time['time'].to_f

    bar.finish

    next_test
  end

  def next_test
    if @children.count.positive?
      t = Thread.new do
        s = @children.shift
        # s[1].start
        # s[1].advance(status: ": #{'running'.green}")
        run_test(s)
      end

      t.join
    end
  end
end


# require 'pastel'
### Individual tests, multiple spinners
# pastel = Pastel.new
# format = "[#{pastel.yellow(':spinner')}] #{pastel.white("Running tests")} (#{pastel.green('tests')}/#{pastel.cyan('assertions')} #{pastel.yellow('time')})"
# spinners = TTY::Spinner::Multi.new(format, format: :dots, success_mark: pastel.green('✔'), error_mark: pastel.red('✖'))
# children = []
# tests = Dir.glob('test/doing_*_test.rb').each do |t|
#   test_name = File.basename(t, '.rb').sub(/doing_(.*?)_test/, '\1')
#   new_sp = spinners.register "[#{pastel.cyan(':spinner')}] #{test_name}:msg"
#   new_sp.update(msg: '')
#   children.push([test_name, new_sp])
# end

# @elapsed = 0.0
# @test_total = 0
# @assrt_total = 0
# spinners.auto_spin

# children.each do |spinner|
#   spinner[1].run do |s|
#     out, _err, status = Open3.capture3(ENV, 'rake', "test:#{spinner[0]}", stdin_data: nil)
#     unless status.success?
#       s.update(msg: "#{pastel.red('- FAILURE:')} #{pastel.bold.white(func)} in #{pastel.bold.yellow(tst)}")
#       s.error
#       s.stop
#       puts `echo #{Shellwords.escape(out)} | colout '^(/.*?/)([^/:]+):(\d+):in (.*?)$' white,yellow,green,magenta | colout 'Failure: (.*?)\\((.*?)\\)' red,green | colout '(.*?) (was expected to be)' green,red | colout '(Finished in) ([\d.]+) (seconds)' green,white,green | colout '(\d+ failures)' red | colout '(100% passed)' green`
#       Process.exit
#     end

#     time = out.match(/^Finished in (?<time>\d+\.\d+) seconds\./)
#     count = out.match(/^(?<tests>\d+) tests, (?<assrt>\d+) assertions/)
#     s.update(msg: ": #{pastel.green(count['tests'])}/#{pastel.cyan(count['assrt'])} #{pastel.yellow(time['time'].to_f.round(3))}s")
#     @test_total += count['tests'].to_i
#     @assrt_total += count['assrt'].to_i
#     @elapsed += time['time'].to_f
#     s.success
#   end
# end

# output = []
# output << pastel.green('Success')
# output << pastel.green("#{@test_total} tests")
# output << pastel.cyan("#{@assrt_total} assertions")
# output << pastel.yellow("#{@elapsed.round(4)}s")
# puts output.join(', ')

### Parallel test single spinner
# pastel = Pastel.new
# format = "[#{pastel.yellow(':spinner')}] #{pastel.white('Running parallel tests')} :msg"
# spinner = TTY::Spinner.new(format, format: :dots, success_mark: pastel.green('✔'), error_mark: pastel.red('✖'))

# spinner.run do |sp|
#   sp.update(msg: '')
#   out, err, status = Open3.capture3(ENV, 'rake', 'parallel:test', stdin_data: nil)

#   unless status.success?
#     failure = out.match(/^Failure: (.*?)\(([A-Z].*?)\)/)
#     func = failure[1]
#     tst = failure[2]
#     sp.update(msg: "#{pastel.red('- FAILURE:')} #{pastel.bold.white(func)} in #{pastel.bold.yellow(tst)}")
#     sp.error
#     sp.stop
#     puts `echo #{Shellwords.escape(out)} | colout '^(/.*?/)([^/:]+):(\d+):in (.*?)$' white,yellow,green,magenta | colout 'Failure: (.*?)\\((.*?)\\)' red,green | colout '(.*?) (was expected to be)' green,red | colout '(Finished in) ([\d.]+) (seconds)' green,white,green | colout '(\d+ failures)' red | colout '(100% passed)' green`
#     Process.exit
#   end

#   sp.update(msg: pastel.green('- All tests passed'))
#   sp.success
# end
