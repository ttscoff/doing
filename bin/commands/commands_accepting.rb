# frozen_string_literal: true

# @@commands_accepting
arg_name 'OPTION'
command :commands_accepting do |c|
  c.desc 'Output in single column for completion'
  c.switch %i[c column]

  c.action do |g, o, a|
    a.each do |option|
      cmds = []
      commands.each do |cmd, v|
        v.flags.merge(v.switches).each do |_, flag|
          cmds.push(cmd) if flag.name == option.to_sym || flag.aliases&.include?(option.to_sym)
        end
      end

      if o[:column]
        puts cmds.sort
      else
        puts "Commands accepting --#{option}: #{cmds.sort.join(', ')}"
      end
    end
  end
end
