# frozen_string_literal: true

require 'aruba/cucumber'

ENV['PATH'] = "#{File.expand_path("#{File.dirname(__FILE__)}/../../bin")}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
LIB_DIR = File.join(__dir__, '..', '..', 'lib')

Before do
  # Using "announce" causes massive warnings on 1.9.2
  @puts = true
  @original_rubylib = ENV['RUBYLIB']
  ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
end

After do
  ENV['RUBYLIB'] = @original_rubylib
end
