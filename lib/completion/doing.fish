function __fish_doing_needs_command
  # Figure out if the current invocation already has a command.

  set -l opts h-help config_file= f-doing_file= n-notes v-version stdout d-debug default x-noauto
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

function __fish_doing_export_plugins
  doing plugins --type export -c
end

function __fish_doing_import_plugins
  doing plugins --type import -c
end

function __fish_doing_complete_templates
  doing template -c
end

complete -c doing -f
complete -xc doing -n '__fish_doing_needs_command' -a '(__fish_doing_subcommands)'

complete -f -c doing -n '__fish_doing_using_command show' -a '(__fish_doing_complete_sections)'
complete -f -c doing -n '__fish_doing_using_command view' -a '(__fish_doing_complete_views)'
complete -f -c doing -n '__fish_doing_using_command template' -a '(__fish_doing_complete_templates)'
complete -f -c doing -s t -l type -x -n '__fish_doing_using_command import' -a '(__fish_doing_import_plugins)'

complete -xc doing -n '__fish_seen_subcommand_from help; and not __fish_seen_subcommand_from (doing help -c)' -a "(doing help -c)"

complete -xc doing -n '__fish_doing_needs_command' -a 'add_section' -d Add\ a\ new\ section\ to\ the\ \"doing\"\ file
complete -xc doing -n '__fish_doing_needs_command' -a 'again resume' -d Repeat\ last\ entry\ as\ new\ entry
complete -xc doing -n '__fish_doing_needs_command' -a 'archive move' -d Move\ entries\ between\ sections
complete -xc doing -n '__fish_doing_needs_command' -a 'autotag' -d Autotag\ last\ entry\ or\ filtered\ entries
complete -xc doing -n '__fish_doing_needs_command' -a 'cancel' -d End\ last\ X\ entries\ with\ no\ time\ tracked
complete -xc doing -n '__fish_doing_needs_command' -a 'choose' -d Select\ a\ section\ to\ display\ from\ a\ menu
complete -xc doing -n '__fish_doing_needs_command' -a 'colors' -d List\ available\ color\ variables\ for\ configuration\ templates\ and\ views
complete -xc doing -n '__fish_doing_needs_command' -a 'completion' -d Generate\ shell\ completion\ scripts
complete -xc doing -n '__fish_doing_needs_command' -a 'config' -d Edit\ the\ configuration\ file\ or\ output\ a\ value\ from\ it
complete -xc doing -n '__fish_doing_needs_command' -a 'done did' -d Add\ a\ completed\ item\ with\ @done\(date\)
complete -xc doing -n '__fish_doing_needs_command' -a 'finish' -d Mark\ last\ X\ entries\ as\ @done
complete -xc doing -n '__fish_doing_needs_command' -a 'grep search' -d Search\ for\ entries
complete -xc doing -n '__fish_doing_needs_command' -a 'help' -d Shows\ a\ list\ of\ commands\ or\ help\ for\ one\ command
complete -xc doing -n '__fish_doing_needs_command' -a 'import' -d Import\ entries\ from\ an\ external\ source
complete -xc doing -n '__fish_doing_needs_command' -a 'last' -d Show\ the\ last\ entry
complete -xc doing -n '__fish_doing_needs_command' -a 'later' -d Add\ an\ item\ to\ the\ Later\ section
complete -xc doing -n '__fish_doing_needs_command' -a 'mark flag' -d Mark\ last\ entry\ as\ flagged
complete -xc doing -n '__fish_doing_needs_command' -a 'meanwhile' -d Finish\ any\ running\ @meanwhile\ tasks\ and\ optionally\ create\ a\ new\ one
complete -xc doing -n '__fish_doing_needs_command' -a 'note' -d Add\ a\ note\ to\ the\ last\ entry
complete -xc doing -n '__fish_doing_needs_command' -a 'now next' -d Add\ an\ entry
complete -xc doing -n '__fish_doing_needs_command' -a 'on' -d List\ entries\ for\ a\ date
complete -xc doing -n '__fish_doing_needs_command' -a 'open' -d Open\ the\ \"doing\"\ file\ in\ an\ editor
complete -xc doing -n '__fish_doing_needs_command' -a 'plugins' -d List\ installed\ plugins
complete -xc doing -n '__fish_doing_needs_command' -a 'recent' -d List\ recent\ entries
complete -xc doing -n '__fish_doing_needs_command' -a 'reset begin' -d Reset\ the\ start\ time\ of\ an\ entry
complete -xc doing -n '__fish_doing_needs_command' -a 'rotate' -d Move\ entries\ to\ archive\ file
complete -xc doing -n '__fish_doing_needs_command' -a 'sections' -d List\ sections
complete -xc doing -n '__fish_doing_needs_command' -a 'select' -d Display\ an\ interactive\ menu\ to\ perform\ operations
complete -xc doing -n '__fish_doing_needs_command' -a 'show' -d List\ all\ entries
complete -xc doing -n '__fish_doing_needs_command' -a 'since' -d List\ entries\ since\ a\ date
complete -xc doing -n '__fish_doing_needs_command' -a 'tag' -d Add\ tag\(s\)\ to\ last\ entry
complete -xc doing -n '__fish_doing_needs_command' -a 'template' -d Output\ HTML
complete -xc doing -n '__fish_doing_needs_command' -a 'test' -d Test\ Stuff
complete -xc doing -n '__fish_doing_needs_command' -a 'today' -d List\ entries\ from\ today
complete -xc doing -n '__fish_doing_needs_command' -a 'undo' -d Undo\ the\ last\ change\ to\ the\ Doing\ file
complete -xc doing -n '__fish_doing_needs_command' -a 'view' -d Display\ a\ user-created\ view
complete -xc doing -n '__fish_doing_needs_command' -a 'views' -d List\ available\ custom\ views
complete -xc doing -n '__fish_doing_needs_command' -a 'wiki' -d Output\ a\ tag\ wiki
complete -xc doing -n '__fish_doing_needs_command' -a 'yesterday' -d List\ entries\ from\ yesterday
complete -c doing -F -n '__fish_doing_using_command import'
