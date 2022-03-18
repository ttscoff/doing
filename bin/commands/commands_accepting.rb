# frozen_string_literal: true

module Doing
  # commands_accepting command methods
  class CommandsAcceptingCommand
    def flags?(options, args, bool)
      case bool
      when :and
        all_flags?(options, args)
      when :not
        no_flags?(options, args)
      else
        any_flags?(options, args)
      end
    end

    def all_flags?(options, args)
      args.each do |arg|
        has_flag = false
        options.flags.merge(options.switches).each do |_, flag|
          if flag.name == arg.to_sym || flag.aliases&.include?(arg.to_sym)
            has_flag = true
            break
          end
        end
        return false unless has_flag
      end

      true
    end

    def any_flags?(options, args)
      args.each do |option|
        options.flags.merge(options.switches).each do |_, flag|
          return true if flag.name == option.to_sym || flag.aliases&.include?(option.to_sym)
        end
      end

      false
    end

    def no_flags?(options, args)
      args.each do |option|
        options.flags.merge(options.switches).each do |_, flag|
          return false if flag.name == option.to_sym || flag.aliases&.include?(option.to_sym)
        end
      end

      true
    end
  end
end

# @@commands_accepting
arg_name 'OPTION'
command :commands_accepting do |c|
  c.desc 'Output in single column for completion'
  c.switch %i[c column]

  c.desc 'Join multiple arguments using boolean (AND|OR|NOT)'
  c.flag [:bool], must_match: REGEX_BOOL,
                  default_value: :and,
                  type: BooleanSymbol

  c.action do |_g, o, a|
    cac = Doing::CommandsAcceptingCommand.new
    cmds = []
    commands.each { |cmd, v| cmds.push(cmd) if cac.flags?(v, a, o[:bool]) }

    if o[:column]
      puts cmds.sort
    else
      description = 'Commands '
      description += 'not ' if o[:bool] == :not
      description += 'accepting '
      description += a.map { |arg| "--#{arg}" }.join(o[:bool] == :and ? ' and ' : ' or ')
      puts "#{description}: #{cmds.sort.join(', ')}"
    end
  end
end
