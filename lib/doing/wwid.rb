#!/usr/bin/ruby
# frozen_string_literal: true

require 'deep_merge'
require 'open3'
require 'pp'
require 'shellwords'
require 'erb'

require_relative 'wwid/display'
require_relative 'wwid/editor'
require_relative 'wwid/filetools'
require_relative 'wwid/filter'
require_relative 'wwid/guess'
require_relative 'wwid/interactive'
require_relative 'wwid/modify'
require_relative 'wwid/tags'
require_relative 'wwid/timers'
require_relative 'wwid/wwidutil'

module Doing
  ##
  ## Main "What Was I Doing" methods
  ##
  class WWID
    attr_reader   :additional_configs, :current_section, :doing_file, :content, :initial_content

    attr_accessor :config, :config_file, :default_option

    include Color
    include Display
    include Editor
    include FileTools
    include Filter
    include Guess
    include Interactive
    include Modify
    include Tags
    include Timers
    include WWIDUtil
    # include Util

    ##
    ## Initializes the object.
    ##
    def initialize
      @timers = {}
      @recorded_items = []
      @content = Items.new
      Doing.auto_tag = true
    end

    # For backwards compatibility where @wwid.config was accessed instead of Doing.config.settings
    def config
      Doing.config.settings
    end

    ##
    ## Logger
    ##
    ## Responds to :debug, :info, :warn, and :error
    ##
    ## Each method takes a topic, and a message or block
    ##
    ## Example: debug('Hooks', 'Hook 1 triggered')
    ##
    def logger
      @logger ||= Doing.logger
    end

    ##
    ## List sections
    ##
    ## @return     [Array] section titles
    ##
    def sections
      @content.section_titles
    end

    ##
    ## List available views
    ##
    ## @return     [Array] View names
    ##
    def views
      Doing.setting('views') ? Doing.setting('views').keys : []
    end

    ##
    ## Gets a view from configuration
    ##
    ## @param      title  [String] The title of the view to retrieve
    ##
    def get_view(title)
      return Doing.setting(['views', title], nil)

      false
    end

    private

    def run_after
      return unless Doing.setting('run_after')

      _, stderr, status = Open3.capture3(Doing.setting('run_after'))
      return unless status.exitstatus.positive?

      logger.log_now(:error, 'Script error:', "Error running #{Doing.setting('run_after')}")
      logger.log_now(:error, 'STDERR output:', stderr)
    end
  end
end
