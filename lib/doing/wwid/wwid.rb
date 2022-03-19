#!/usr/bin/ruby
# frozen_string_literal: true

require 'deep_merge'
require 'open3'
require 'pp'
require 'shellwords'
require 'erb'

require_relative 'display'
require_relative 'editor'
require_relative 'filetools'
require_relative 'filter'
require_relative 'guess'
require_relative 'interactive'
require_relative 'modify'
require_relative 'tags'
require_relative 'timers'
require_relative 'wwidutil'

module Doing
  ##
  ## Main "What Was I Doing" methods
  ##
  class WWID
    # Local configuration files detected at initialization
    attr_reader :additional_configs

    # The Currently section defined in configuration
    attr_reader :current_section

    # The location of the Doing file defined in configuration
    attr_reader :doing_file

    # The Items object into which all entries are read
    attr_reader :content

    # A frozen copy of the content object before any modification
    attr_reader :initial_content

    # The configuration object for the instance
    attr_accessor :config

    # The location of the main config file
    attr_accessor :config_file

    # [Boolean] the default option to provide in Y/N dialogs
    attr_accessor :default_option

    include Color

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
    def get_view(title, fallback: nil)
      Doing.setting(['views', title], fallback)
    end

    def rename_view_keys(view)
      options = view.symbolize_keys
      # options.rename_key(:tags, :tag, keep: true)
      options.rename_key(:output_format, :output)
      options.rename_key(:tags_bool, :bool)
      options.rename_key(:negate, :not)
      options.rename_key(:order, :sort)

      options
    end

    def view_to_options(title)
      view = rename_view_keys(get_view(guess_view(title)))
      view.deep_merge(rename_view_keys(get_view(guess_view(view[:parent]), fallback: {}))) if view.key?(:parent)
      view.deep_merge(rename_view_keys(get_view(view[:config_template], fallback: {}))) if view.key?(:config_template)
      view.deep_merge(Doing.setting('templates.default').symbolize_keys)
      view
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
