# frozen_string_literal: true

module Doing
  class WWID
    ##
    ## Remove items from an array that already exist in
    ## :content based on start and end times
    ##
    ## @param      items       [Array] The items to
    ##                         deduplicate
    ## @param      no_overlap  [Boolean] Remove items with
    ##                         overlapping time spans
    ##
    def dedup(items, no_overlap: false)
      items.delete_if do |item|
        duped = false
        @content.each do |comp|
          duped = no_overlap ? item.overlapping_time?(comp) : item.same_time?(comp)
          break if duped
        end
        logger.count(:skipped, level: :debug, message: '%count overlapping %items') if duped
        # logger.log_now(:debug, 'Skipped:', "overlapping entry: #{item.title}") if duped
        duped
      end
    end

    ##
    ## Imports external entries
    ##
    ## @param      paths  [String] Path to JSON report file
    ## @param      opt    [Hash] Additional Options
    ##
    def import(paths, opt)
      opt ||= {}
      Plugins.plugins[:import].each do |_, options|
        next unless opt[:type] =~ /^(#{options[:trigger].normalize_trigger})$/i

        if paths.count.positive?
          paths.each do |path|
            options[:class].import(self, path, options: opt)
          end
        else
          options[:class].import(self, nil, options: opt)
        end
        break
      end
    end

    ##
    ## Load configuration files and updated the @settings
    ## attribute with a Doing::Configuration object
    ##
    ## @param      filename  [String] (optional) path to
    ##                       alternative config file
    ##
    def configure(filename = nil)
      logger.benchmark(:configure, :start)

      if filename
        Doing.config_with(filename, { ignore_local: true })
      elsif ENV['DOING_CONFIG']
        Doing.config_with(ENV['DOING_CONFIG'], { ignore_local: true })
      end

      logger.benchmark(:configure, :finish)

      Doing.set('backup_dir', ENV['DOING_BACKUP_DIR']) if ENV['DOING_BACKUP_DIR']
    end

    ##
    ## Get difference between current content and last backup
    ##
    ## @param      filename  [String] The file path
    ##
    def get_diff(filename = nil)
      configure if Doing.settings.nil?

      filename ||= Doing.setting('doing_file')
      init_doing_file(filename)
      current_content = @content.clone
      backup_file = Util::Backup.last_backup(filename, count: 1)
      raise DoingRuntimeError, 'No undo history to diff' if backup_file.nil?

      backup = WWID.new
      backup.config = Doing.settings
      backup.init_doing_file(backup_file)
      current_content.diff(backup.content)
    end

    ##
    ## Return a hash of changes between initial file read
    ## and current Items object
    ##
    ## @return     [Hash] Hash containing `added` and
    ##             `removed` keys with arrays of Item
    ##
    def changes
      @content.diff(@initial_content)
    end
  end
end
