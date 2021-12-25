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

    wwid = WWID.new
    wwid.configure
    if filename == wwid.config['doing_file']
      diff = wwid.get_diff(filename)
      puts diff
    end
  end

  Hooks.register :post_entry_added do |wwid, entry|
    break unless wwid.config.key?('day_one_trigger') && entry.tags?(wwid.config['day_one_trigger'], :and)

    logger.info('New entry:', 'Adding to Day One')
    add_to_day_one(entry)
  end

  ##
  ## Add the entry to Day One using the CLI
  ##
  ## @param      entry  The entry to add
  ##
  def add_to_day_one(entry)
    dayone = TTY::Which.which('dayone2')
    flagged = entry.tags?('flagged') ? ' -s' : ''
    tags = entry.tags.map { |t| Shellwords.escape(t) }.join(' ')
    tags = tags.length.positive? ? " -t #{tags}" : ''
    date = " -d '#{entry.date.strftime('%Y-%m-%d %H:%M:%S')}'"
    title = entry.title.tag(@config['day_one_trigger'], remove: true)
    title += "\n#{entry.note}" unless entry.note.empty?
    `echo #{Shellwords.escape(title)} | #{dayone} new#{flagged}#{date}#{tags}`
  end
end
