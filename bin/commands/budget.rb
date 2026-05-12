# frozen_string_literal: true

# @@budget
desc 'Set, list, and remove tag time budgets'
long_desc %(Manage simple time budgets for tags.

Run without arguments to list configured budgets.

Use `doing budget TAG AMOUNT` to set a budget (e.g. `doing budget dev 100h`).

Use `doing budget TAG --remove` to delete a budget.)
arg_name '[TAG [AMOUNT]]'
command :budget do |c|
  c.example 'doing budget', desc: 'List configured tag budgets'
  c.example 'doing budget dev 100h', desc: 'Set budget for @dev to 100 hours'
  c.example 'doing budget dev --remove', desc: 'Remove budget for @dev'

  c.desc 'Delete specified tag budget'
  c.switch %i[r remove], negatable: false, default_value: false

  c.action do |_global_options, options, args|
    budgets = Doing.setting('budgets') || {}

    budget_fmt = lambda do |secs|
      secs = secs.to_i
      return '0h' if secs <= 0

      minutes = (secs / 60).to_i
      hours = (minutes / 60).to_i
      mins = (minutes % 60).to_i
      return format('%dh', hours) if mins.zero?
      return format('%dm', mins) if hours.zero?

      format('%dh%dm', hours, mins)
    end

    if args.empty?
      if budgets.nil? || budgets.empty?
        puts 'No tag budgets configured'
      else
        budgets.keys.sort.each do |tag|
          secs = budgets[tag].to_i
          duration = budget_fmt.call(secs)
          puts "#{tag}: #{duration}"
        end
      end
      next
    end

    tag = args.shift.sub(/^@/, '').downcase

    config_file = Doing.config.choose_config(create: true, local: false)
    cfg = Doing::Util.safe_load_file(config_file) || {}
    path = ['budgets', tag]

    if options[:remove]
      if cfg.dig(*path).nil? && (budgets[tag].nil?)
        Doing.logger.log_now(:warn, 'Budget:', "No budget found for tag @#{tag}")
      else
        cfg.deep_set(path, nil)
        Doing.settings['budgets']&.delete(tag)
        Doing.logger.log_now(:warn, 'Budget:', "Removed budget for tag @#{tag}")
      end

      Doing::Util.write_to_file(config_file, YAML.dump(cfg), backup: true)
      next
    end

    raise InvalidArgument, 'Budget requires TAG and AMOUNT' if args.empty?

    amount = args.join(' ')
    seconds = amount.chronify_qty
    raise InvalidArgument, "Invalid budget amount: #{amount}" if seconds.zero?

    cfg.deep_set(path, seconds)
    Doing::Util.write_to_file(config_file, YAML.dump(cfg), backup: true)

    Doing.settings['budgets'] ||= {}
    Doing.settings['budgets'][tag] = seconds

    Doing.logger.log_now(:warn, 'Budget:',
                         "Set budget for tag @#{tag} to #{budget_fmt.call(seconds)}")
  end
end

