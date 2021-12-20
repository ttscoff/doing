function __fish_doing_needs_command
  # Figure out if the current invocation already has a command.

  set -l opts color h-help config_file= f-doing_file= n-notes v-version stdout debug default x-noauto no p-pager q-quiet yes
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
complete -xc doing -n '__fish_doing_needs_command' -a 'changelog changes' -d List\ recent\ changes\ in\ Doing
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
complete -xc doing -n '__fish_doing_needs_command' -a 'tags' -d List\ all\ tags\ in\ the\ current\ Doing\ file
complete -xc doing -n '__fish_doing_needs_command' -a 'template' -d Output\ HTML
complete -xc doing -n '__fish_doing_needs_command' -a 'test' -d Test\ Stuff
complete -xc doing -n '__fish_doing_needs_command' -a 'today' -d List\ entries\ from\ today
complete -xc doing -n '__fish_doing_needs_command' -a 'undo' -d Undo\ the\ last\ X\ changes\ to\ the\ Doing\ file
complete -xc doing -n '__fish_doing_needs_command' -a 'view' -d Display\ a\ user-created\ view
complete -xc doing -n '__fish_doing_needs_command' -a 'views' -d List\ available\ custom\ views
complete -xc doing -n '__fish_doing_needs_command' -a 'wiki' -d Output\ a\ tag\ wiki
complete -xc doing -n '__fish_doing_needs_command' -a 'yesterday' -d List\ entries\ from\ yesterday
complete -c doing -l bool  -f -r -n '__fish_doing_using_command again resume' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l case  -f -r -n '__fish_doing_using_command again resume' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command again resume' -d Edit\ duplicated\ entry\ with\ vim\ before\ adding
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command again resume' -d Select\ item\ to\ resume\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l in  -f -r -n '__fish_doing_using_command again resume' -d Add\ new\ entry\ to\ section
complete -c doing -l note -s n -f -r -n '__fish_doing_using_command again resume' -d Note
complete -c doing -l not  -f  -n '__fish_doing_using_command again resume' -d Resume\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command again resume' -d Get\ last\ entry\ from\ a\ specific\ section
complete -c doing -l search  -f -r -n '__fish_doing_using_command again resume' -d Repeat\ last\ entry\ matching\ search
complete -c doing -l tag  -f -r -n '__fish_doing_using_command again resume' -d Repeat\ last\ entry\ matching\ tags
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command again resume' -d Force\ exact\ search\ string\ matching
complete -c doing -l before  -f -r -n '__fish_doing_using_command archive move' -d Archive\ entries\ older\ than\ date
complete -c doing -l bool  -f -r -n '__fish_doing_using_command archive move' -d Tag\ boolean
complete -c doing -l case  -f -r -n '__fish_doing_using_command archive move' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l keep -s k -f -r -n '__fish_doing_using_command archive move' -d How\ many\ items\ to\ keep
complete -c doing -l label  -f  -n '__fish_doing_using_command archive move' -d Label\ moved\ items\ with\ @from\(SECTION_NAME\)
complete -c doing -l not  -f  -n '__fish_doing_using_command archive move' -d Show\ items\ that\ \*don\'t\*\ match\ search\ string
complete -c doing -l search  -f -r -n '__fish_doing_using_command archive move' -d Search\ filter
complete -c doing -l to -s t -f -r -n '__fish_doing_using_command archive move' -d Move\ entries\ to
complete -c doing -l tag  -f -r -n '__fish_doing_using_command archive move' -d Tag\ filter
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command archive move' -d Force\ exact\ search\ string\ matching
complete -c doing -l bool  -f -r -n '__fish_doing_using_command autotag' -d Boolean
complete -c doing -l count -s c -f -r -n '__fish_doing_using_command autotag' -d How\ many\ recent\ entries\ to\ autotag
complete -c doing -l force  -f  -n '__fish_doing_using_command autotag' -d Don\'t\ ask\ permission\ to\ autotag\ all\ entries\ when\ count\ is\ 0
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command autotag' -d Select\ item\(s\)\ to\ tag\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command autotag' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command autotag' -d Autotag\ entries\ matching\ search\ filter
complete -c doing -l tag  -f -r -n '__fish_doing_using_command autotag' -d Autotag\ the\ last\ X\ entries\ containing\ TAG
complete -c doing -l unfinished -s u -f  -n '__fish_doing_using_command autotag' -d Autotag\ last\ entry
complete -c doing -l archive -s a -f  -n '__fish_doing_using_command cancel' -d Archive\ entries
complete -c doing -l bool  -f -r -n '__fish_doing_using_command cancel' -d Boolean
complete -c doing -l case  -f -r -n '__fish_doing_using_command cancel' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command cancel' -d Select\ item\(s\)\ to\ cancel\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l not  -f  -n '__fish_doing_using_command cancel' -d Finish\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command cancel' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command cancel' -d Cancel\ the\ last\ X\ entries\ matching\ search\ filter
complete -c doing -l tag  -f -r -n '__fish_doing_using_command cancel' -d Cancel\ the\ last\ X\ entries\ containing\ TAG
complete -c doing -l unfinished -s u -f  -n '__fish_doing_using_command cancel' -d Cancel\ last\ entry
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command cancel' -d Force\ exact\ search\ string\ matching
complete -c doing -l file -s f -f -r -n '__fish_doing_using_command completion' -d File\ to\ write\ output\ to
complete -c doing -l type -s t -f -r -n '__fish_doing_using_command completion' -d Shell\ to\ generate\ for
complete -c doing -l dump -s d -f  -n '__fish_doing_using_command config' -d DEPRECATED
complete -c doing -l update -s u -f  -n '__fish_doing_using_command config' -d DEPRECATED
complete -c doing -l archive -s a -f  -n '__fish_doing_using_command done did' -d Immediately\ archive\ the\ entry
complete -c doing -l at  -f -r -n '__fish_doing_using_command done did' -d Set\ finish\ date\ to\ specific\ date/time
complete -c doing -l started  -f -r -n '__fish_doing_using_command done did' -d Backdate\ start\ date\ by\ interval\ or\ set\ to\ time\ \[4pm\|20m\|2h\|\"yesterday\ noon\"\]
complete -c doing -l date  -f  -n '__fish_doing_using_command done did' -d Include\ date
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command done did' -d Edit\ entry\ with\ vim
complete -c doing -l note -s n -f -r -n '__fish_doing_using_command done did' -d Include\ a\ note
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command done did' -d Remove\ @done\ tag
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command done did' -d Section
complete -c doing -l took -s t -f -r -n '__fish_doing_using_command done did' -d Set\ completion\ date\ to\ start\ date\ plus\ interval
complete -c doing -l unfinished -s u -f  -n '__fish_doing_using_command done did' -d Finish\ last\ entry\ not\ already\ marked\ @done
complete -c doing -l archive -s a -f  -n '__fish_doing_using_command finish' -d Archive\ entries
complete -c doing -l at  -f -r -n '__fish_doing_using_command finish' -d Set\ finish\ date\ to\ specific\ date/time
complete -c doing -l auto  -f  -n '__fish_doing_using_command finish' -d Auto-generate\ finish\ dates\ from\ next\ entry\'s\ start\ time
complete -c doing -l back -s b -f -r -n '__fish_doing_using_command finish' -d Backdate\ completed\ date\ to\ date\ string\ \[4pm\|20m\|2h\|yesterday\ noon\]
complete -c doing -l bool  -f -r -n '__fish_doing_using_command finish' -d Boolean
complete -c doing -l case  -f -r -n '__fish_doing_using_command finish' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l date  -f  -n '__fish_doing_using_command finish' -d Include\ date
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command finish' -d Select\ item\(s\)\ to\ finish\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l not  -f  -n '__fish_doing_using_command finish' -d Finish\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command finish' -d Remove\ done\ tag
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command finish' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command finish' -d Finish\ the\ last\ X\ entries\ matching\ search\ filter
complete -c doing -l took -s t -f -r -n '__fish_doing_using_command finish' -d Set\ the\ completed\ date\ to\ the\ start\ date\ plus\ XX\[hmd\]
complete -c doing -l tag  -f -r -n '__fish_doing_using_command finish' -d Finish\ the\ last\ X\ entries\ containing\ TAG
complete -c doing -l unfinished -s u -f  -n '__fish_doing_using_command finish' -d Finish\ last\ entry
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command finish' -d Force\ exact\ search\ string\ matching
complete -c doing -l after  -f -r -n '__fish_doing_using_command grep search' -d Search\ entries\ newer\ than\ date
complete -c doing -l before  -f -r -n '__fish_doing_using_command grep search' -d Search\ entries\ older\ than\ date
complete -c doing -l case  -f -r -n '__fish_doing_using_command grep search' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l duration  -f  -n '__fish_doing_using_command grep search' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l from  -f -r -n '__fish_doing_using_command grep search' -d Date\ range\ to\ show
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command grep search' -d Display\ an\ interactive\ menu\ of\ results\ to\ perform\ further\ operations
complete -c doing -l not  -f  -n '__fish_doing_using_command grep search' -d Show\ items\ that\ \*don\'t\*\ match\ search\ string
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command grep search' -d Output\ to\ export\ format
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command grep search' -d Only\ show\ items\ with\ recorded\ time\ intervals
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command grep search' -d Section
complete -c doing -l times -s t -f  -n '__fish_doing_using_command grep search' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command grep search' -d Sort\ tags\ by
complete -c doing -l totals  -f  -n '__fish_doing_using_command grep search' -d Show\ intervals\ with\ totals\ at\ the\ end\ of\ output
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command grep search' -d Force\ exact\ string\ matching
complete -c doing -F -n '__fish_doing_using_command import'
complete -c doing -l after  -f -r -n '__fish_doing_using_command import' -d Import\ entries\ newer\ than\ date
complete -c doing -l autotag  -f  -n '__fish_doing_using_command import' -d Autotag\ entries
complete -c doing -l before  -f -r -n '__fish_doing_using_command import' -d Import\ entries\ older\ than\ date
complete -c doing -l case  -f -r -n '__fish_doing_using_command import' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l from -s f -f -r -n '__fish_doing_using_command import' -d Date\ range\ to\ import
complete -c doing -l not  -f  -n '__fish_doing_using_command import' -d Import\ items\ that\ \*don\'t\*\ match\ search/tag/date\ filters
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command import' -d Only\ import\ items\ with\ recorded\ time\ intervals
complete -c doing -l overlap  -f  -n '__fish_doing_using_command import' -d Allow\ entries\ that\ overlap\ existing\ times
complete -c doing -l prefix  -f -r -n '__fish_doing_using_command import' -d Prefix\ entries\ with
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command import' -d Target\ section
complete -c doing -l search  -f -r -n '__fish_doing_using_command import' -d Only\ import\ items\ matching\ search
complete -c doing -l tag  -f -r -n '__fish_doing_using_command import' -d Tag\ all\ imported\ entries
complete -c doing -l type  -f -r -n '__fish_doing_using_command import' -d Import\ type
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command import' -d Force\ exact\ search\ string\ matching
complete -c doing -l bool  -f -r -n '__fish_doing_using_command last' -d Tag\ boolean
complete -c doing -l case  -f -r -n '__fish_doing_using_command last' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l duration  -f  -n '__fish_doing_using_command last' -d Show\ elapsed\ time\ if\ entry\ is\ not\ tagged\ @done
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command last' -d Edit\ entry\ with\ vim
complete -c doing -l not  -f  -n '__fish_doing_using_command last' -d Show\ items\ that\ \*don\'t\*\ match\ search\ string\ or\ tag\ filter
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command last' -d Specify\ a\ section
complete -c doing -l search  -f -r -n '__fish_doing_using_command last' -d Search\ filter
complete -c doing -l tag  -f -r -n '__fish_doing_using_command last' -d Tag\ filter
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command last' -d Force\ exact\ search\ string\ matching
complete -c doing -l back -s b -f -r -n '__fish_doing_using_command later' -d Backdate\ start\ time\ to\ date\ string\ \[4pm\|20m\|2h\|yesterday\ noon\]
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command later' -d Edit\ entry\ with\ vim
complete -c doing -l note -s n -f -r -n '__fish_doing_using_command later' -d Note
complete -c doing -l bool  -f -r -n '__fish_doing_using_command mark flag' -d Boolean
complete -c doing -l count -s c -f -r -n '__fish_doing_using_command mark flag' -d How\ many\ recent\ entries\ to\ tag
complete -c doing -l case  -f -r -n '__fish_doing_using_command mark flag' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l date -s d -f  -n '__fish_doing_using_command mark flag' -d Include\ current\ date/time\ with\ tag
complete -c doing -l force  -f  -n '__fish_doing_using_command mark flag' -d Don\'t\ ask\ permission\ to\ flag\ all\ entries\ when\ count\ is\ 0
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command mark flag' -d Select\ item\(s\)\ to\ flag\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l not  -f  -n '__fish_doing_using_command mark flag' -d Flag\ items\ that\ \*don\'t\*\ match\ search/tag/date\ filters
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command mark flag' -d Remove\ flag
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command mark flag' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command mark flag' -d Flag\ the\ last\ entry\ matching\ search\ filter
complete -c doing -l tag  -f -r -n '__fish_doing_using_command mark flag' -d Flag\ the\ last\ entry\ containing\ TAG
complete -c doing -l unfinished -s u -f  -n '__fish_doing_using_command mark flag' -d Flag\ last\ entry
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command mark flag' -d Force\ exact\ search\ string\ matching
complete -c doing -l archive -s a -f  -n '__fish_doing_using_command meanwhile' -d Archive\ previous\ @meanwhile\ entry
complete -c doing -l back -s b -f -r -n '__fish_doing_using_command meanwhile' -d Backdate\ start\ date\ for\ new\ entry\ to\ date\ string\ \[4pm\|20m\|2h\|yesterday\ noon\]
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command meanwhile' -d Edit\ entry\ with\ vim
complete -c doing -l note -s n -f -r -n '__fish_doing_using_command meanwhile' -d Note
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command meanwhile' -d Section
complete -c doing -l bool  -f -r -n '__fish_doing_using_command note' -d Boolean
complete -c doing -l case  -f -r -n '__fish_doing_using_command note' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command note' -d Edit\ entry\ with\ vim
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command note' -d Select\ item\ for\ new\ note\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l not  -f  -n '__fish_doing_using_command note' -d Add\ note\ to\ item\ that\ \*doesn\'t\*\ match\ search/tag\ filters
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command note' -d Replace/Remove\ last\ entry\'s\ note
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command note' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command note' -d Add/remove\ note\ from\ last\ entry\ matching\ search\ filter
complete -c doing -l tag  -f -r -n '__fish_doing_using_command note' -d Add/remove\ note\ from\ last\ entry\ matching\ tag
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command note' -d Force\ exact\ search\ string\ matching
complete -c doing -l started  -f -r -n '__fish_doing_using_command now next' -d Backdate\ start\ time\ \[4pm\|20m\|2h\|\"yesterday\ noon\"\]
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command now next' -d Edit\ entry\ with\ vim
complete -c doing -l finish_last -s f -f  -n '__fish_doing_using_command now next' -d Timed\ entry
complete -c doing -l note -s n -f -r -n '__fish_doing_using_command now next' -d Include\ a\ note
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command now next' -d Section
complete -c doing -l duration  -f  -n '__fish_doing_using_command on' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command on' -d Output\ to\ export\ format
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command on' -d Section
complete -c doing -l times -s t -f  -n '__fish_doing_using_command on' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command on' -d Sort\ tags\ by
complete -c doing -l totals  -f  -n '__fish_doing_using_command on' -d Show\ time\ totals\ at\ the\ end\ of\ output
complete -c doing -l app -s a -f -r -n '__fish_doing_using_command open' -d Open\ with\ app\ name
complete -c doing -l bundle_id -s b -f -r -n '__fish_doing_using_command open' -d Open\ with\ app\ bundle\ id
complete -c doing -l editor -s e -f -r -n '__fish_doing_using_command open' -d Open\ with\ editor\ command
complete -c doing -l column -s c -f  -n '__fish_doing_using_command plugins' -d List\ in\ single\ column\ for\ completion
complete -c doing -l type -s t -f -r -n '__fish_doing_using_command plugins' -d List\ plugins\ of\ type
complete -c doing -l duration  -f  -n '__fish_doing_using_command recent' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command recent' -d Select\ from\ a\ menu\ of\ matching\ entries\ to\ perform\ additional\ operations
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command recent' -d Section
complete -c doing -l times -s t -f  -n '__fish_doing_using_command recent' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command recent' -d Sort\ tags\ by
complete -c doing -l totals  -f  -n '__fish_doing_using_command recent' -d Show\ intervals\ with\ totals\ at\ the\ end\ of\ output
complete -c doing -l bool  -f -r -n '__fish_doing_using_command reset begin' -d Boolean
complete -c doing -l case  -f -r -n '__fish_doing_using_command reset begin' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command reset begin' -d Select\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l not  -f  -n '__fish_doing_using_command reset begin' -d Reset\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l resume -s r -f  -n '__fish_doing_using_command reset begin' -d Resume\ entry
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command reset begin' -d Limit\ search\ to\ section
complete -c doing -l search  -f -r -n '__fish_doing_using_command reset begin' -d Reset\ last\ entry\ matching\ search\ filter
complete -c doing -l tag  -f -r -n '__fish_doing_using_command reset begin' -d Reset\ last\ entry\ matching\ tag
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command reset begin' -d Force\ exact\ search\ string\ matching
complete -c doing -l before  -f -r -n '__fish_doing_using_command rotate' -d Rotate\ entries\ older\ than\ date
complete -c doing -l bool  -f -r -n '__fish_doing_using_command rotate' -d Tag\ boolean
complete -c doing -l case  -f -r -n '__fish_doing_using_command rotate' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l keep -s k -f -r -n '__fish_doing_using_command rotate' -d How\ many\ items\ to\ keep\ in\ each\ section
complete -c doing -l not  -f  -n '__fish_doing_using_command rotate' -d Rotate\ items\ that\ \*don\'t\*\ match\ search\ string\ or\ tag\ filter
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command rotate' -d Section\ to\ rotate
complete -c doing -l search  -f -r -n '__fish_doing_using_command rotate' -d Search\ filter
complete -c doing -l tag  -f -r -n '__fish_doing_using_command rotate' -d Tag\ filter
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command rotate' -d Force\ exact\ search\ string\ matching
complete -c doing -l column -s c -f  -n '__fish_doing_using_command sections' -d List\ in\ single\ column
complete -c doing -l archive -s a -f  -n '__fish_doing_using_command select' -d Archive\ selected\ items
complete -c doing -l after  -f -r -n '__fish_doing_using_command select' -d Select\ from\ entries\ newer\ than\ date
complete -c doing -l resume  -f  -n '__fish_doing_using_command select' -d Copy\ selection\ as\ a\ new\ entry\ with\ current\ time\ and\ no\ @done\ tag
complete -c doing -l before  -f -r -n '__fish_doing_using_command select' -d Select\ from\ entries\ older\ than\ date
complete -c doing -l cancel -s c -f  -n '__fish_doing_using_command select' -d Cancel\ selected\ items
complete -c doing -l case  -f -r -n '__fish_doing_using_command select' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l delete -s d -f  -n '__fish_doing_using_command select' -d Delete\ selected\ items
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command select' -d Edit\ selected\ item\(s\)
complete -c doing -l finish -s f -f  -n '__fish_doing_using_command select' -d Add\ @done\ with\ current\ time\ to\ selected\ item\(s\)
complete -c doing -l flag  -f  -n '__fish_doing_using_command select' -d Add\ flag\ to\ selected\ item\(s\)
complete -c doing -l force  -f  -n '__fish_doing_using_command select' -d Perform\ action\ without\ confirmation
complete -c doing -l from  -f -r -n '__fish_doing_using_command select' -d Date\ range\ to\ show
complete -c doing -l move -s m -f -r -n '__fish_doing_using_command select' -d Move\ selected\ items\ to\ section
complete -c doing -l menu  -f  -n '__fish_doing_using_command select' -d Use\ --no-menu\ to\ skip\ the\ interactive\ menu
complete -c doing -l not  -f  -n '__fish_doing_using_command select' -d Select\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command select' -d Output\ entries\ to\ format
complete -c doing -l search  -f -r -n '__fish_doing_using_command select' -d Initial\ search\ query\ for\ filtering
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command select' -d Reverse\ -c
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command select' -d Select\ from\ a\ specific\ section
complete -c doing -l save_to  -f -r -n '__fish_doing_using_command select' -d Save\ selected\ entries\ to\ file\ using\ --output\ format
complete -c doing -l tag -s t -f -r -n '__fish_doing_using_command select' -d Tag\ selected\ entries
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command select' -d Force\ exact\ search\ string\ matching
complete -c doing -l age -s a -f -r -n '__fish_doing_using_command show' -d Age
complete -c doing -l after  -f -r -n '__fish_doing_using_command show' -d Show\ entries\ newer\ than\ date
complete -c doing -l bool -s b -f -r -n '__fish_doing_using_command show' -d Tag\ boolean
complete -c doing -l before  -f -r -n '__fish_doing_using_command show' -d Show\ entries\ older\ than\ date
complete -c doing -l count -s c -f -r -n '__fish_doing_using_command show' -d Max\ count\ to\ show
complete -c doing -l case  -f -r -n '__fish_doing_using_command show' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l duration  -f  -n '__fish_doing_using_command show' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l from  -f -r -n '__fish_doing_using_command show' -d Date\ range\ to\ show
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command show' -d Select\ from\ a\ menu\ of\ matching\ entries\ to\ perform\ additional\ operations
complete -c doing -l menu -s m -f  -n '__fish_doing_using_command show' -d Select\ section\ or\ tag\ to\ display\ from\ a\ menu
complete -c doing -l not  -f  -n '__fish_doing_using_command show' -d Show\ items\ that\ \*don\'t\*\ match\ search/tag/date\ filters
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command show' -d Output\ to\ export\ format
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command show' -d Only\ show\ items\ with\ recorded\ time\ intervals
complete -c doing -l sort -s s -f -r -n '__fish_doing_using_command show' -d Sort\ order
complete -c doing -l search  -f -r -n '__fish_doing_using_command show' -d Search\ filter
complete -c doing -l times -s t -f  -n '__fish_doing_using_command show' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag  -f -r -n '__fish_doing_using_command show' -d Tag\ filter
complete -c doing -l tag_order  -f -r -n '__fish_doing_using_command show' -d Tag\ sort\ direction
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command show' -d Sort\ tags\ by
complete -c doing -l totals  -f  -n '__fish_doing_using_command show' -d Show\ intervals\ with\ totals\ at\ the\ end\ of\ output
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command show' -d Force\ exact\ search\ string\ matching
complete -c doing -l duration  -f  -n '__fish_doing_using_command since' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command since' -d Output\ to\ export\ format
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command since' -d Section
complete -c doing -l times -s t -f  -n '__fish_doing_using_command since' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command since' -d Sort\ tags\ by
complete -c doing -l totals  -f  -n '__fish_doing_using_command since' -d Show\ time\ totals\ at\ the\ end\ of\ output
complete -c doing -l autotag -s a -f  -n '__fish_doing_using_command tag' -d Autotag\ entries\ based\ on\ autotag\ configuration\ in\ \~/
complete -c doing -l bool  -f -r -n '__fish_doing_using_command tag' -d Boolean
complete -c doing -l count -s c -f -r -n '__fish_doing_using_command tag' -d How\ many\ recent\ entries\ to\ tag
complete -c doing -l case  -f -r -n '__fish_doing_using_command tag' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l date -s d -f  -n '__fish_doing_using_command tag' -d Include\ current\ date/time\ with\ tag
complete -c doing -l force  -f  -n '__fish_doing_using_command tag' -d Don\'t\ ask\ permission\ to\ tag\ all\ entries\ when\ count\ is\ 0
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command tag' -d Select\ item\(s\)\ to\ tag\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l not  -f  -n '__fish_doing_using_command tag' -d Tag\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command tag' -d Remove\ given\ tag\(s\)
complete -c doing -l regex  -f  -n '__fish_doing_using_command tag' -d Interpret\ tag\ string\ as\ regular\ expression
complete -c doing -l rename  -f -r -n '__fish_doing_using_command tag' -d Replace\ existing\ tag\ with\ tag\ argument
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command tag' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command tag' -d Tag\ entries\ matching\ search\ filter
complete -c doing -l tag  -f -r -n '__fish_doing_using_command tag' -d Tag\ the\ last\ X\ entries\ containing\ TAG
complete -c doing -l unfinished -s u -f  -n '__fish_doing_using_command tag' -d Tag\ last\ entry
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command tag' -d Force\ exact\ search\ string\ matching
complete -c doing -l bool  -f -r -n '__fish_doing_using_command tags' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l counts -s c -f  -n '__fish_doing_using_command tags' -d Show\ count\ of\ occurrences
complete -c doing -l case  -f -r -n '__fish_doing_using_command tags' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command tags' -d Select\ items\ to\ scan\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l not  -f  -n '__fish_doing_using_command tags' -d Get\ tags\ from\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l order -s o -f -r -n '__fish_doing_using_command tags' -d Sort\ order
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command tags' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command tags' -d Get\ tags\ for\ items\ matching\ search
complete -c doing -l sort  -f -r -n '__fish_doing_using_command tags' -d Sort\ by\ name\ or\ count
complete -c doing -l tag  -f -r -n '__fish_doing_using_command tags' -d Get\ tags\ for\ entries\ matching\ tags
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command tags' -d Force\ exact\ search\ string\ matching
complete -c doing -l column -s c -f  -n '__fish_doing_using_command template' -d List\ in\ single\ column\ for\ completion
complete -c doing -l list -s l -f  -n '__fish_doing_using_command template' -d List\ all\ available\ templates
complete -c doing -l path -s p -f -r -n '__fish_doing_using_command template' -d Save\ template\ to\ alternate\ location
complete -c doing -l save -s s -f  -n '__fish_doing_using_command template' -d Save\ template\ to\ file\ instead\ of\ STDOUT
complete -c doing -l after  -f -r -n '__fish_doing_using_command today' -d View\ entries\ after\ specified\ time
complete -c doing -l before  -f -r -n '__fish_doing_using_command today' -d View\ entries\ before\ specified\ time
complete -c doing -l duration  -f  -n '__fish_doing_using_command today' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l from  -f -r -n '__fish_doing_using_command today' -d Time\ range\ to\ show\ \`doing\ today\ --from\ \"12pm\ to\ 4pm\"\`
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command today' -d Output\ to\ export\ format
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command today' -d Specify\ a\ section
complete -c doing -l times -s t -f  -n '__fish_doing_using_command today' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command today' -d Sort\ tags\ by
complete -c doing -l totals  -f  -n '__fish_doing_using_command today' -d Show\ time\ totals\ at\ the\ end\ of\ output
complete -c doing -l file -s f -f -r -n '__fish_doing_using_command undo' -d Specify\ alternate\ doing\ file
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command undo' -d Select\ from\ recent\ backups
complete -c doing -l prune -s p -f -r -n '__fish_doing_using_command undo' -d Remove\ old\ backups
complete -c doing -l redo -s r -f  -n '__fish_doing_using_command undo' -d Redo\ last\ undo
complete -c doing -l after  -f -r -n '__fish_doing_using_command view' -d View\ entries\ newer\ than\ date
complete -c doing -l bool -s b -f -r -n '__fish_doing_using_command view' -d Tag\ boolean
complete -c doing -l before  -f -r -n '__fish_doing_using_command view' -d View\ entries\ older\ than\ date
complete -c doing -l count -s c -f -r -n '__fish_doing_using_command view' -d Count\ to\ display
complete -c doing -l case  -f -r -n '__fish_doing_using_command view' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l color  -f  -n '__fish_doing_using_command view' -d Include\ colors\ in\ output
complete -c doing -l duration  -f  -n '__fish_doing_using_command view' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l from  -f -r -n '__fish_doing_using_command view' -d Date\ range\ to\ show
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command view' -d Select\ from\ a\ menu\ of\ matching\ entries\ to\ perform\ additional\ operations
complete -c doing -l not  -f  -n '__fish_doing_using_command view' -d Show\ items\ that\ \*don\'t\*\ match\ search\ string
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command view' -d Output\ to\ export\ format
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command view' -d Only\ show\ items\ with\ recorded\ time\ intervals
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command view' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command view' -d Search\ filter
complete -c doing -l times -s t -f  -n '__fish_doing_using_command view' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag  -f -r -n '__fish_doing_using_command view' -d Tag\ filter
complete -c doing -l tag_order  -f -r -n '__fish_doing_using_command view' -d Tag\ sort\ direction
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command view' -d Sort\ tags\ by
complete -c doing -l totals  -f  -n '__fish_doing_using_command view' -d Show\ intervals\ with\ totals\ at\ the\ end\ of\ output
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command view' -d Force\ exact\ search\ string\ matching
complete -c doing -l column -s c -f  -n '__fish_doing_using_command views' -d List\ in\ single\ column
complete -c doing -l after  -f -r -n '__fish_doing_using_command wiki' -d Include\ entries\ newer\ than\ date
complete -c doing -l bool -s b -f -r -n '__fish_doing_using_command wiki' -d Tag\ boolean
complete -c doing -l before  -f -r -n '__fish_doing_using_command wiki' -d Include\ entries\ older\ than\ date
complete -c doing -l from -s f -f -r -n '__fish_doing_using_command wiki' -d Date\ range\ to\ include
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command wiki' -d Only\ show\ items\ with\ recorded\ time\ intervals
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command wiki' -d Section\ to\ rotate
complete -c doing -l search  -f -r -n '__fish_doing_using_command wiki' -d Search\ filter
complete -c doing -l tag  -f -r -n '__fish_doing_using_command wiki' -d Tag\ filter
complete -c doing -l after  -f -r -n '__fish_doing_using_command yesterday' -d View\ entries\ after\ specified\ time
complete -c doing -l before  -f -r -n '__fish_doing_using_command yesterday' -d View\ entries\ before\ specified\ time
complete -c doing -l duration  -f  -n '__fish_doing_using_command yesterday' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l from  -f -r -n '__fish_doing_using_command yesterday' -d Time\ range\ to\ show
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command yesterday' -d Output\ to\ export\ format
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command yesterday' -d Specify\ a\ section
complete -c doing -l times -s t -f  -n '__fish_doing_using_command yesterday' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag_order  -f -r -n '__fish_doing_using_command yesterday' -d Tag\ sort\ direction
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command yesterday' -d Sort\ tags\ by
complete -c doing -l totals  -f  -n '__fish_doing_using_command yesterday' -d Show\ time\ totals\ at\ the\ end\ of\ output
complete -f -c doing -s o -l output -x -n '__fish_doing_using_command grep search on select show since today view yesterday' -a '(__fish_doing_export_plugins)'
