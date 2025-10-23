#!/usr/bin/env ruby
# frozen_string_literal: true

require 'tty-spinner'
require 'tty-progressbar'
require 'open3'
require 'shellwords'
require 'fileutils'

$LOAD_PATH.unshift File.join(__dir__, '..')
require 'doing'
require 'helpers/threaded_tests_string'

class ThreadedTests
  include Doing::Color
  include ThreadedTestString

  def run(pattern: '*', max_threads: 8, max_tests: 0)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @results = File.expand_path('results.log')

    max_threads = 1000 if max_threads.to_i.zero?

    c = Doing::Color
    c.coloring = true

    shuffle = false

    if pattern =~ /shuffle/i
      pattern = 'test/doing_*_test.rb'
      shuffle = true
    else
      pattern = "test/doing_*#{pattern}*_test.rb"
    end

    tests = Dir.glob(pattern)

    tests.shuffle! if shuffle

    tests = tests.slice(0, max_tests.to_i - 1) if max_tests.to_i.positive?

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
                                           clear: true,
                                           hide_cursor: true)
    @children = []
    tests.each do |t|
      test_name = File.basename(t, '.rb').sub(/doing_(.*?)_test/, '\1')
      new_sp = progress.register("[#{':bar'.cyan}] #{test_name.bold.white}:status",
                                 total: tests.count + 8,
                                 width: 1,
                                 head: ' ',
                                 unknown: ' ',
                                 hide_cursor: true,
                                 clear: true)
      status = ': waiting'.dark.yellow.reset
      @children.push([test_name, new_sp, status])
      # new_sp.advance(status: ': waiting'.dark.yellow.reset)
    end

    @elapsed = 0.0
    @test_total = 0
    @assrt_total = 0
    @error_out = []
    # progress.start
    @threads = []
    @running_tests = []

    begin
      finish_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      while @children.count.positive?

        slices = @children.slice!(0, max_threads)
        slices.each { |c| c[1].start }
        slices.each do |s|
          @threads << Thread.new do
            run_test(s)
            finish_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end
        end

        @threads.each(&:join)
      end

      finish_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      progress.finish
    rescue StandardError
      progress.stop
    ensure
      msg = @running_tests.map do |t|
        t[1].format.uncolor.sub(/^\[:bar\] (.*?):status/, "#{c.bold}#{c.white}\\1#{c.reset}#{t[2]}")
      end.join("\n")

      Doing::Prompt.clear_screen(msg)

      output = []
      output << if @error_out.count.positive?
                  c.boldred("#{@error_out.count} Issues")
                else
                  c.green('Success')
                end
      output << c.green("#{@test_total} tests")
      output << c.cyan("#{@assrt_total} assertions")
      output << c.yellow("#{(finish_time - start_time).round(3)}s")
      puts output.join(', ')

      if @error_out.count.positive?
        res = Doing::Prompt.yn('Display error report?', default_response: false)
        Doing::Pager.paginate = true
        Doing::Pager.page(@error_out.join("\n----\n".boldwhite)) if res
        Process.exit 1
      end
    end
  end

  def run_test(s)
    bar = s[1]
    s[2] = ": #{'running'.green}"
    bar.advance(status: s[2])

    if @running_tests.count.positive?
      @running_tests.each do |b|
        prev_bar = b[1]
        if prev_bar.complete?
          prev_bar.reset
          prev_bar.advance(status: b[2])
          prev_bar.finish
        else
          prev_bar.update(head: ' ', unfinished: ' ')
          prev_bar.advance(status: b[2])
        end
      end
    end

    @running_tests.push(s)
    out, _err, status = Open3.capture3(ENV, 'rake', "test:#{s[0]}", stdin_data: nil)
    time = out.match(/^Finished in (?<time>\d+\.\d+) seconds\./)
    count = out.match(/^(?<tests>\d+) tests, (?<assrt>\d+) assertions, (?<fails>\d+) failures, (?<errs>\d+) errors/)

    unless status.success? && !count['fails'].to_i.positive? && !count['errs'].to_i.positive?
      s[2] = if count
               ": #{count['fails'].bold.red} #{'failures'.red}, #{count['errs'].bold.red} #{'errors'.red}"
             else
               ": #{'Unknown Error'.bold.red}"
             end
      bar.update(head: '✖'.boldred)
      bar.advance(head: '✖'.boldred, status: s[2])

      # errs = out.scan(/(?:Failure|Error): [\w_]+\((?:.*?)\):(?:.*?)(?=\n=======)/m)
      @error_out.push(out.highlight_errors)
      bar.finish

      next_test
      Thread.exit
    end

    s[2] = [
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
    bar.advance(head: '✔'.boldgreen, status: s[2])
    @test_total += count['tests'].to_i
    @assrt_total += count['assrt'].to_i
    @elapsed += time['time'].to_f

    bar.finish

    next_test
  end

  def next_test
    return unless @children.count.positive?

    t = Thread.new do
      s = @children.shift
      # s[1].start
      # s[1].advance(status: ": #{'running'.green}")
      run_test(s)
    end

    t.join
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
