# frozen_string_literal: true

module Doing
  # Hooks.register :post_config do |wwid|
  #   wwid.config['twizzle'] = 'Fo shizzle'
  #   wwid.write_config(File.expand_path('~/Desktop/wwidconfig.yml'))
  # end

  # Hooks.register :post_read, priority: 10 do |wwid|
  #   Doing.logger.warn('Hook 1:', 'triggered priority 10')
  #   Doing.logger.warn('Hook 2:', wwid.config['twizzle'])
  # end

  # Hooks.register :post_read, priority: 100 do |wwid|
  #   Doing.logger.warn('Hook 2:', 'triggered priority 100')
  # end

  Hooks.register :post_write do |filename|
    res = `/bin/bash /Users/ttscoff/scripts/after_doing.sh`.strip
    Doing.logger.debug('Hooks:', res) unless res =~ /^\.\.\.$/
  end
end
