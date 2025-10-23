# frozen_string_literal: true

require_relative 'lib/doing'
include Doing

@wwid = WWID.new
@wwid.init_doing_file
