# frozen_string_literal: true

module Doing
  class TestExport
    def self.settings
      {
        trigger: 'trizzer',
        templates: [
          { name: 'trizzer', trigger: 'tr(.*?)' }
        ],
        config: {
          'trizzle' => 'test value'
        }
      }
    end

    def self.template(trigger)
      return unless trigger =~ /^tr/

      "This was triggered with #{trigger}: %content"
    end

    def self.render(wwid, items, variables: {})
      return if items.nil? || items.empty?

      opt = variables[:options]

      i = items[-1]

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
      tpl = template('trizzer')

      if wwid.config['export_templates'].key?('trizzer')
        cfg_tpl = wwid.config['export_templates']['trizzer']
        tpl = cfg_tpl unless cfg_tpl.nil? || cfg_tpl.empty?
      end
      content = "TEST PLUGIN. On #{date} you were #{i.title}#{took}"
      output = tpl.dup
      output.gsub!(/%content/, content)

      value = wwid.config['plugins']['trizzer']['trizzle'] || 'NO CONFIG'
      Doing.logger.info("Test export plugin complete. Config value: #{value}")

      output
    end

    Doing::Plugins.register 'trizzer', :export, self
  end
end
