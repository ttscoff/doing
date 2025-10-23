# frozen_string_literal: true

# title: Export plugin example
# description: Speak the most recent entry (macOS)
# author: Brett Terpstra
# url: https://brettterpstra.com

# Example
#
# doing show -o sayit
#
# ## Configuration
#
# Change what the plugin says by generating a template with
# `doing template --type say`, saving it to a file, and
# putting the path to that file in `export_templates->say` in
# config.yml.
#
# export_templates:
#   say: /path/to/template.txt
#
# Use a different voice by adding a `say_voice` key to your
# config.yml. Use `say -v ?` to see available voices.
#
# say_voice: Zarvox

module Doing
  ##
  ## Plugin class
  ##
  class SayExport
    include Doing::Util

    #-------------------------------------------------------
    ## Plugin Settings. A plugin must have a self.settings
    ## method that returns a hash with plugin settings.
    ##
    ## trigger:   (required) Regular expression to match
    ## FORMAT when used with `--output FORMAT`. Registered
    ## name of plugin must be able to match the trigger, but
    ## alternatives can be included
    ##
    ## templates: (optional) Array of templates this plugin
    ## can export (plugin must have :template method)
    ##
    ##   Each template is a hash containing:
    ##               - name: display name for template
    ##               - trigger: regular expression for
    ##                 `template --type FORMAT`
    ##               - format: a descriptor of the file format (erb, haml, stylus, etc.)
    ##               - filename: a default filename used when the template is written to disk
    ##
    ##   If a template is included, a config key will
    ##   automatically be added for the user to override
    ##   The config key will be available at:
    ##
    ##       Doing.config.settings['export_templates'][PLUGIN_NAME]
    ##
    ## config:    (optional) A Hash which will be
    ## added to the main configuration in the plugins section.
    ## Options defined here are included when config file is
    ## created or updated with `config --update`. Use this to
    ## add new configuration keys, not to override existing
    ## ones.
    ##
    ##   The configuration keys will be available at:
    ##
    ##      Doing.config.settings['plugins'][PLUGIN_NAME][KEY]
    ##
    ## Method to return plugin settings (required)
    ##
    ## @return     Hash of settings for this plugin
    ##
    def self.settings
      {
        trigger: 'say(?:it)?',
        templates: [
          { name: 'say', trigger: 'say(?:it)?', format: 'text', filename: 'say.txt' }
        ],
        config: {
          'say_voice' => 'Fiona'
        }
      }
    end

    #-------------------------------------------------------
    ## Output a template. Only required if template(s) are
    ## included in settings. The method should return a
    ## string (not output it to the STDOUT).
    ##
    ## Method to return template (optional)
    ##
    ## @param      trigger  The trigger passed to the
    ##                      template function. When this
    ##                      method defines multiple
    ##                      templates, the trigger can be
    ##                      used to determine which one is
    ##                      output.
    ##
    ## @return     [String] template contents
    ##
    def self.template(trigger)
      return unless trigger =~ /^say(it)?$/

      'On %date, you were %title, recorded in section %section%took'
    end

    ##
    ## Render data received from an output
    ##             command
    ##
    ## @param      wwid       The wwid object with config
    ##                        and public methods
    ## @param      items      An array of items to be output
    ##                        { <Date>date, <String>title,
    ##                        <String>section, <Array>note }
    ## @param      variables  Additional variables including
    ##                        flags passed to command
    ##                        (variables[:options])
    ##
    ## @return     [String] Rendered output
    ##
    def self.render(_wwid, items, variables: {})
      return unless items.good?

      config = Doing.config.settings

      # the :options key includes the flags passed to the
      # command that called the plugin use `puts
      # variables.inspect` to see properties and methods
      # when run
      opt = variables[:options]

      # This plugin just grabs the last item in the `items`
      # list (which could be the oldest or newest, depending
      # on the sort order of the command that called the
      # plugin). Most of the time you'll want to use :each
      # or :map to generate output.
      i = items[-1]

      # Format the item. Items are an object with 4 methods:
      # date, title, section (parent section), and note.
      # Start time is in item.date. The wwid object has some
      # methods for calculation and formatting, including
      # wwid.item.end_date to convert the @done timestamp to
      # an end date.
      if opt[:times]
        interval = i.interval

        if interval
          took = '. You finished on '
          finished_at = i.end_date
          took += finished_at.strftime('%A %B %e at %I:%M%p')

          took += ' and it took'
          took += interval.time_string(format: :natural)
        end
      end

      date = i.date.strftime('%A %B %e at %I:%M%p')
      title = i.title.gsub(/@/, 'hashtag ')
      tpl = template('say')

      if config['export_templates'].key?('say')
        cfg_tpl = config['export_templates']['say']
        tpl = cfg_tpl if cfg_tpl.good?
      end
      output = tpl.dup
      output.gsub!(/%date/, date)
      output.gsub!(/%title/, title)
      output.gsub!(/%section/, i.section)
      output.gsub!(/%took/, took || '')

      # Debugging output
      # warn "Saying: #{output}"

      # To provide results on the command line after the
      # command runs, use Doing.logger, which responds to
      # :debug, :info, :warn, and :error. e.g.:
      #
      # Doing.logger.info("This plugin has run")
      # Doing.logger.error("This message will be displayed even if run in --quiet mode.")
      #
      # Results are
      # provided on STDERR unless doing is run with
      # `--stdout` or non-interactively.
      Doing.logger.info('Spoke the last entry. Did you hear it?')

      # This export runs a command for fun, most plugins won't
      voice = config['plugins']['say']['say_voice'] || 'Alex'
      `say -v "#{voice}" "#{output}"`

      # Return the result (don't output to terminal with puts or print)
      output
    end

    # Register the plugin with doing.
    # Doing::Plugins.register 'NAME', TYPE, Class
    #
    # Name should be lowercase, no spaces
    #
    # TYPE is :import or :export
    #
    # Class is the plugin class (e.g. Doing::SayExport), or
    # self if called within the class
    Doing::Plugins.register 'say', :export, self
  end
end
