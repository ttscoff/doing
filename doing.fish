# show and view completion for Fish (very incomplete for a completion script)
function __fish_doing_needs_command
	# Figure out if the current invocation already has a command.

	set -l opts h-help f-doing_file= n-notes v-version
	set cmd (commandline -opc)
	set -e cmd[1]
	argparse -s $opts -- $cmd 2>/dev/null
	or return 0
	# These flags function as commands, effectively.
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_doing_using_command
	set -l cmd (__fish_doing_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd $argv
	and return 0
end

function __fish_doing_complete_sections
	doing sections -c
end

function __fish_doing_complete_views
	doing views -c
end

function __fish_doing_subcommands
	doing help -c
end

complete -xc doing -n '__fish_doing_needs_command' -a '(__fish_doing_subcommands)'
complete -f -c doing -n '__fish_doing_using_command show' -a '(__fish_doing_complete_sections)'
complete -f -c doing -n '__fish_doing_using_command view' -a '(__fish_doing_complete_views)'
