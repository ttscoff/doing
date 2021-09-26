require 'stringio'
require 'time'
require 'fileutils'

module GLI
  module Commands
    # DocumentListener class for GLI documentation generator
    class MarkdownDocumentListener
      def initialize(_global_options, _options, _arguments, app)
        @exe = app.exe_name
        if File.exist?('COMMANDS.md') # Back up existing README
          FileUtils.mv('COMMANDS.md', 'COMMANDS.bak')
          $stderr.puts "Backing up existing COMMANDS.md"
        end
        @io = File.new('COMMANDS.md', 'w')
        @nest = '#'
        @arg_name_formatter = GLI::Commands::HelpModules::ArgNameFormatter.new
        @parent_command = []
      end

      def beginning
      end

      # Called when processing has completed
      def ending
        if File.exist?('CREDITS.md')
          @io.puts IO.read('CREDITS.md')
          @io.puts
        end

        if File.exist?('AUTHORS.md')
          @io.puts IO.read('AUTHORS.md')
          @io.puts
        end

        if File.exist?('LICENSE.md')
          @io.puts IO.read('LICENSE.md')
          @io.puts
        end
        @io.puts
        @io.puts "Documentation generated #{Time.now.strftime('%Y-%m-%d %H:%M')}"
        @io.puts
        @io.close
      end

      # Gives you the program description
      def program_desc(desc)
        @io.puts "# #{@exe} CLI"
        @io.puts
        @io.puts desc
        @io.puts
      end

      def program_long_desc(desc)
        @io.puts "> #{desc}"
        @io.puts
      end

      # Gives you the program version
      def version(version)
        @io.puts "*v#{version}*"
        @io.puts
        # Hacking in the overview file
        if File.exist?('OVERVIEW.md')
          @io.puts IO.read('OVERVIEW.md')
          @io.puts
        end
      end

      def options
        if @nest.size == 1
          @io.puts "## Global Options"
        else
          @io.puts header("Options", 1)
        end
        @io.puts
      end

      # Gives you a flag in the current context
      def flag(name, aliases, desc, long_desc, default_value, arg_name, must_match, _type)
        invocations = ([name] + Array(aliases)).map { |_| "`" + add_dashes(_) + "`" }.join(' | ')
        usage = "#{invocations} #{arg_name || 'arg'}"
        @io.puts header(usage, 2)
        @io.puts
        @io.puts String(desc).strip
        @io.puts "\n*Default Value:* `#{default_value || 'None'}`\n" unless default_value.nil?
        @io.puts "\n*Must Match:* `#{must_match.to_s}`\n" unless must_match.nil?
        cmd_desc = String(long_desc).strip
        @io.puts "> #{cmd_desc}\n" unless cmd_desc.length == 0
        @io.puts
      end

      # Gives you a switch in the current context
      def switch(name, aliases, desc, long_desc, negatable)
        if negatable
          name = "[no-]#{name}" if name.to_s.length > 1
          aliases = aliases.map { |_|  _.to_s.length > 1 ? "[no-]#{_}" : _ }
        end
        invocations = ([name] + aliases).map { |_| "`" + add_dashes(_).strip + "`" }.join('|')
        @io.puts header("#{invocations}", 2)
        @io.puts
        @io.puts String(desc).strip
        cmd_desc = String(long_desc).strip
        @io.puts "\n> #{cmd_desc}\n" unless cmd_desc.length == 0
        @io.puts
      end

      def end_options
      end

      def commands
        @io.puts header("Commands", 1)
        @io.puts
        increment_nest
      end

      # Gives you a command in the current context and creates a new context of this command
      def command(name, aliases, desc, long_desc, arg_name, arg_options)
        @parent_command.push ([name] + aliases).join('|')
        arg_name_fmt = @arg_name_formatter.format(arg_name, arg_options, [])
        arg_name_fmt = " `#{arg_name_fmt.strip}`" if arg_name_fmt
        @io.puts header("`$ #{@exe}` <mark>`#{@parent_command.join(' ')}`</mark>#{arg_name_fmt}", 1)
        @io.puts
        @io.puts "*#{String(desc).strip}*"
        @io.puts
        cmd_desc = String(long_desc).strip.split("\n").map { |_| "> #{_}" }.join("\n")
        @io.puts "#{cmd_desc}\n\n" unless cmd_desc.length == 0
        increment_nest
      end

      # Ends a command, and "pops" you back up one context
      def end_command(_name)
        @parent_command.pop
        decrement_nest
        @io.puts "* * * * * *\n\n" unless @nest.size > 2
      end

      # Gives you the name of the current command in the current context
      def default_command(name)
        @io.puts "#### [Default Command] #{name}" unless name.nil?
      end

      def end_commands
        decrement_nest
      end

      private

      def add_dashes(name)
        name = "-#{name}"
        name = "-#{name}" if name.length > 2
        name
      end

      def header(content, increment)
        if @nest.size + increment > 6
          "**#{content}**"
        else
          "#{@nest}#{'#'*increment} #{content}"
        end
      end

      def increment_nest(increment=1)
        @nest = "#{@nest}#{'#'*increment}"
      end

      def decrement_nest(increment=1)
        @nest.gsub!(/#{'#'*increment}$/, '')
      end
    end
  end
end

GLI::Commands::Doc::FORMATS['markdown'] = GLI::Commands::MarkdownDocumentListener
