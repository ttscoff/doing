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

function __fish_doing_cache_timer_expired
  set -l timer __fish_doing_cache_timer_$argv[1]
  if not set -q $timer
    set -g $timer (date '+%s')
  end

  if test (math (date '+%s') - $$timer) -gt $argv[2]
    set -g $timer (date '+%s')
    return 1
  end

  return 0
end

function __fish_doing_subcommands
  if not set -q __fish_doing_subcommands_cache
    or __fish_doing_cache_timer_expired subcommands 86400
    set -g -a __fish_doing_subcommands_cache (doing help -c)
  end
  printf '%s
' $__fish_doing_subcommands_cache
end

function __fish_doing_complete_sections
  if not set -q __fish_doing_sections_cache
    or __fish_doing_cache_timer_expired sections 3600
    set -g -a __fish_doing_sections_cache (doing sections -c)
  end
  printf '%s
' $__fish_doing_sections_cache
  __fish_doing_complete_show_tag
end

function __fish_doing_complete_views
  if not set -q __fish_doing_views_cache
    or __fish_doing_cache_timer_expired views 3600
    set -g -a __fish_doing_views_cache (doing views -c)
  end
  printf '%s
' $__fish_doing_views_cache
end

function __fish_doing_export_plugin
  if not set -q __fish_doing_export_plugin_cache
    or __fish_doing_cache_timer_expired export_plugins 3600
    set -g -a __fish_doing_export_plugin_cache (doing plugins --type export -c)
  end
  printf '%s
' $__fish_doing_export_plugin_cache
end

function __fish_doing_import_plugin
  if not set -q __fish_doing_import_plugin_cache
    or __fish_doing_cache_timer_expired import_plugins 3600
    set -g -a __fish_doing_import_plugin_cache (doing plugins --type import -c)
  end
  printf '%s
' $__fish_doing_import_plugin_cache
end

function __fish_doing_complete_template
  if not set -q __fish_doing_template_cache
    or __fish_doing_cache_timer_expired template 3600
    set -g -a __fish_doing_template_cache (doing template -c)
  end
  printf '%s
' $__fish_doing_template_cache
end

function __fish_doing_complete_tag
  if not set -q __fish_doing_tag_cache
    or __fish_doing_cache_timer_expired tags 60
    set -g -a __fish_doing_tag_cache (doing tags)
  end
  printf '%s
' $__fish_doing_tag_cache
end

function __fish_doing_complete_show_tag
  if not set -q __fish_doing_tag_cache
    or __fish_doing_cache_timer_expired tags 60
    set -g -a __fish_doing_tag_cache (doing tags)
  end
  printf '@%s
' $__fish_doing_tag_cache
end

function __fish_doing_complete_args
  for cmd in (doing commands_accepting -c $argv[1])
    complete -x -c doing -l $argv[1] -n "__fish_doing_using_command $cmd" -a "(__fish_doing_complete_$argv[1])"
  end
end

complete -c doing -f
complete -xc doing -n '__fish_doing_needs_command' -a '(__fish_doing_subcommands)'

complete -f -c doing -n '__fish_doing_using_command show' -a '(__fish_doing_complete_sections)'
complete -f -c doing -n '__fish_doing_using_command view' -a '(__fish_doing_complete_views)'
complete -f -c doing -n '__fish_doing_using_command template' -a '(__fish_doing_complete_templates)'
complete -f -c doing -s t -l type -x -n '__fish_doing_using_command import' -a '(__fish_doing_import_plugins)'
complete -f -c doing -n '__fish_doing_using_command help' -a '(__fish_doing_subcommands)'

# complete -xc doing -n '__fish_seen_subcommand_from help; and not __fish_seen_subcommand_from (doing help -c)' -a "(doing help -c)"

function __fish_doing_complete_args
  for cmd in (doing commands_accepting -c $argv[1])
    complete -x -c doing -l $argv[1] -n "__fish_doing_using_command $cmd" -a "(__fish_doing_complete_$argv[1])"
  end
end

__fish_doing_complete_args tag

complete -xc doing -n '__fish_doing_needs_command' -a 'again resume' -d Repeat\ last\ entry\ as\ new\ entry
complete -xc doing -n '__fish_doing_needs_command' -a 'archive move' -d Move\ entries\ between\ sections
complete -xc doing -n '__fish_doing_needs_command' -a 'autotag' -d Autotag\ last\ entry\ or\ filtered\ entries
complete -xc doing -n '__fish_doing_needs_command' -a 'cancel' -d End\ last\ X\ entries\ with\ no\ time\ tracked
complete -xc doing -n '__fish_doing_needs_command' -a 'changes changelog' -d List\ recent\ changes\ in\ Doing
complete -xc doing -n '__fish_doing_needs_command' -a 'colors' -d List\ available\ color\ variables\ for\ configuration\ templates\ and\ views
complete -xc doing -n '__fish_doing_needs_command' -a 'commands' -d Enable\ and\ disable\ Doing\ commands
complete -xc doing -n '__fish_doing_needs_command' -a 'completion' -d Generate\ shell\ completion\ scripts\ for\ doing
complete -xc doing -n '__fish_doing_needs_command' -a 'config' -d Edit\ the\ configuration\ file\ or\ output\ a\ value\ from\ it
complete -xc doing -n '__fish_doing_needs_command' -a 'done did' -d Add\ a\ completed\ item\ with\ @done\(date\)
complete -xc doing -n '__fish_doing_needs_command' -a 'finish' -d Mark\ last\ X\ entries\ as\ @done
complete -xc doing -n '__fish_doing_needs_command' -a 'grep search' -d Search\ for\ entries
complete -xc doing -n '__fish_doing_needs_command' -a 'help' -d Shows\ a\ list\ of\ commands\ or\ help\ for\ one\ command
complete -xc doing -n '__fish_doing_needs_command' -a 'import' -d Import\ entries\ from\ an\ external\ source
complete -xc doing -n '__fish_doing_needs_command' -a 'last' -d Show\ the\ last\ entry
complete -xc doing -n '__fish_doing_needs_command' -a 'mark flag' -d Mark\ last\ entry\ as\ flagged
complete -xc doing -n '__fish_doing_needs_command' -a 'meanwhile' -d Finish\ any\ running\ @meanwhile\ tasks\ and\ optionally\ create\ a\ new\ one
complete -xc doing -n '__fish_doing_needs_command' -a 'note' -d Add\ a\ note\ to\ the\ last\ entry
complete -xc doing -n '__fish_doing_needs_command' -a 'now next' -d Add\ an\ entry
complete -xc doing -n '__fish_doing_needs_command' -a 'on' -d List\ entries\ for\ a\ date
complete -xc doing -n '__fish_doing_needs_command' -a 'open' -d Open\ the\ \"doing\"\ file\ in\ an\ editor
complete -xc doing -n '__fish_doing_needs_command' -a 'plugins' -d List\ installed\ plugins
complete -xc doing -n '__fish_doing_needs_command' -a 'recent' -d List\ recent\ entries
complete -xc doing -n '__fish_doing_needs_command' -a 'redo' -d Redo\ an\ undo\ command
complete -xc doing -n '__fish_doing_needs_command' -a 'reset begin' -d Reset\ the\ start\ time\ of\ an\ entry
complete -xc doing -n '__fish_doing_needs_command' -a 'rotate' -d Move\ entries\ to\ archive\ file
complete -xc doing -n '__fish_doing_needs_command' -a 'sections' -d List
complete -xc doing -n '__fish_doing_needs_command' -a 'select' -d Display\ an\ interactive\ menu\ to\ perform\ operations
complete -xc doing -n '__fish_doing_needs_command' -a 'show' -d List\ all\ entries
complete -xc doing -n '__fish_doing_needs_command' -a 'since' -d List\ entries\ since\ a\ date
complete -xc doing -n '__fish_doing_needs_command' -a 'tag' -d Add\ tag\(s\)\ to\ last\ entry
complete -xc doing -n '__fish_doing_needs_command' -a 'tag_dir' -d Set\ the\ default\ tags\ for\ the\ current\ directory
complete -xc doing -n '__fish_doing_needs_command' -a 'tags' -d List\ all\ tags\ in\ the\ current\ Doing\ file
complete -xc doing -n '__fish_doing_needs_command' -a 'template' -d Output\ HTML
complete -xc doing -n '__fish_doing_needs_command' -a 'test' -d Test\ Stuff
complete -xc doing -n '__fish_doing_needs_command' -a 'today' -d List\ entries\ from\ today
complete -xc doing -n '__fish_doing_needs_command' -a 'undo' -d Undo\ the\ last\ X\ changes\ to\ the\ Doing\ file
complete -xc doing -n '__fish_doing_needs_command' -a 'view' -d Display\ a\ user-created\ view
complete -xc doing -n '__fish_doing_needs_command' -a 'views' -d List\ available\ custom\ views
complete -xc doing -n '__fish_doing_needs_command' -a 'wiki' -d Output\ a\ tag\ wiki
complete -xc doing -n '__fish_doing_needs_command' -a 'yesterday' -d List\ entries\ from\ yesterday
complete -c doing -l noauto -s X -f  -n '__fish_doing_using_command again resume' -d Exclude\ auto\ tags\ and\ default\ tags
complete -c doing -l ask  -f  -n '__fish_doing_using_command again resume' -d Prompt\ for\ note\ via\ multi-line\ input
complete -c doing -l started  -f -r -n '__fish_doing_using_command again resume' -d Backdate\ start\ date\ for\ new\ entry\ to\ date\ string\ \[4pm\|20m\|2h\|yesterday\ noon\]
complete -c doing -l bool  -f -r -n '__fish_doing_using_command again resume' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l case  -f -r -n '__fish_doing_using_command again resume' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command again resume' -d Edit\ entry\ with\ vim
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command again resume' -d Select\ item\ to\ resume\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l in  -f -r -n '__fish_doing_using_command again resume' -d Add\ new\ entry\ to\ section
complete -c doing -l note -s n -f -r -n '__fish_doing_using_command again resume' -d Include\ a\ note
complete -c doing -l not  -f  -n '__fish_doing_using_command again resume' -d Repeat\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command again resume' -d Get\ last\ entry\ from\ a\ specific\ section
complete -c doing -l search  -f -r -n '__fish_doing_using_command again resume' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l tag  -f -r -n '__fish_doing_using_command again resume' -d Filter\ entries\ by\ tag
complete -c doing -l val  -f -r -n '__fish_doing_using_command again resume' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command again resume' -d Force\ exact\ search\ string\ matching
complete -c doing -l after  -f -r -n '__fish_doing_using_command archive move' -d Archive\ entries\ newer\ than\ date
complete -c doing -l before  -f -r -n '__fish_doing_using_command archive move' -d Archive\ entries\ older\ than\ date
complete -c doing -l bool  -f -r -n '__fish_doing_using_command archive move' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l case  -f -r -n '__fish_doing_using_command archive move' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l from  -f -r -n '__fish_doing_using_command archive move' -d Date\ range
complete -c doing -l keep -s k -f -r -n '__fish_doing_using_command archive move' -d How\ many\ items\ to\ keep
complete -c doing -l label  -f  -n '__fish_doing_using_command archive move' -d Label\ moved\ items\ with\ @from\(SECTION_NAME\)
complete -c doing -l not  -f  -n '__fish_doing_using_command archive move' -d Archive\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l search  -f -r -n '__fish_doing_using_command archive move' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l to -s t -f -r -n '__fish_doing_using_command archive move' -d Move\ entries\ to
complete -c doing -l tag  -f -r -n '__fish_doing_using_command archive move' -d Filter\ entries\ by\ tag
complete -c doing -l val  -f -r -n '__fish_doing_using_command archive move' -d Perform\ a\ tag\ value\ query
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
complete -c doing -l bool  -f -r -n '__fish_doing_using_command cancel' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l case  -f -r -n '__fish_doing_using_command cancel' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command cancel' -d Select\ item\(s\)\ to\ cancel\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l not  -f  -n '__fish_doing_using_command cancel' -d Cancel\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command cancel' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command cancel' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l tag  -f -r -n '__fish_doing_using_command cancel' -d Filter\ entries\ by\ tag
complete -c doing -l unfinished -s u -f  -n '__fish_doing_using_command cancel' -d Cancel\ last\ entry
complete -c doing -l val  -f -r -n '__fish_doing_using_command cancel' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command cancel' -d Force\ exact\ search\ string\ matching
complete -c doing -l changes -s C -f  -n '__fish_doing_using_command changes changelog' -d Only\ output\ changes
complete -c doing -l all -s a -f  -n '__fish_doing_using_command changes changelog' -d Display\ all\ versions
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command changes changelog' -d Open\ changelog\ in\ interactive\ viewer
complete -c doing -l lookup -s l -f -r -n '__fish_doing_using_command changes changelog' -d Look\ up\ a\ specific\ version
complete -c doing -l markdown  -f  -n '__fish_doing_using_command changes changelog' -d Output\ raw\ Markdown
complete -c doing -l only  -f -r -n '__fish_doing_using_command changes changelog' -d Only\ show\ changes\ of\ type\(s\)
complete -c doing -l prefix -s p -f  -n '__fish_doing_using_command changes changelog' -d Include
complete -c doing -l render  -f  -n '__fish_doing_using_command changes changelog' -d Force\ rendered\ output
complete -c doing -l search -s s -f -r -n '__fish_doing_using_command changes changelog' -d Show\ changelogs\ matching\ search\ terms
complete -c doing -l sort  -f -r -n '__fish_doing_using_command changes changelog' -d Sort\ order
complete -c doing -l type -s t -f -r -n '__fish_doing_using_command completion' -d Deprecated
complete -c doing -l dump -s d -f  -n '__fish_doing_using_command config' -d DEPRECATED
complete -c doing -l update -s u -f  -n '__fish_doing_using_command config' -d DEPRECATED
complete -c doing -l noauto -s X -f  -n '__fish_doing_using_command done did' -d Exclude\ auto\ tags\ and\ default\ tags
complete -c doing -l archive -s a -f  -n '__fish_doing_using_command done did' -d Immediately\ archive\ the\ entry
complete -c doing -l ask  -f  -n '__fish_doing_using_command done did' -d Prompt\ for\ note\ via\ multi-line\ input
complete -c doing -l finished  -f -r -n '__fish_doing_using_command done did' -d Set\ finish\ date\ to\ specific\ date/time
complete -c doing -l started  -f -r -n '__fish_doing_using_command done did' -d Backdate\ start\ date\ for\ new\ entry\ to\ date\ string\ \[4pm\|20m\|2h\|yesterday\ noon\]
complete -c doing -l date  -f  -n '__fish_doing_using_command done did' -d Include\ date
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command done did' -d Edit\ entry\ with\ vim
complete -c doing -l from  -f -r -n '__fish_doing_using_command done did' -d Start\ and\ end\ times\ as\ a\ date/time\ range\ \`doing\ done\ --from\ \"1am\ to\ 8am\"\`
complete -c doing -l note -s n -f -r -n '__fish_doing_using_command done did' -d Include\ a\ note
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command done did' -d Remove\ @done\ tag
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command done did' -d Section
complete -c doing -l for  -f -r -n '__fish_doing_using_command done did' -d Set\ completion\ date\ to\ start\ date\ plus\ interval
complete -c doing -l unfinished -s u -f  -n '__fish_doing_using_command done did' -d Finish\ last\ entry\ not\ already\ marked\ @done
complete -c doing -l archive -s a -f  -n '__fish_doing_using_command finish' -d Archive\ entries
complete -c doing -l finished  -f -r -n '__fish_doing_using_command finish' -d Set\ finish\ date\ to\ specific\ date/time
complete -c doing -l auto  -f  -n '__fish_doing_using_command finish' -d Auto-generate\ finish\ dates\ from\ next\ entry\'s\ start\ time
complete -c doing -l started  -f -r -n '__fish_doing_using_command finish' -d Backdate\ completed\ date\ to\ date\ string\ \[4pm\|20m\|2h\|yesterday\ noon\]
complete -c doing -l bool  -f -r -n '__fish_doing_using_command finish' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l case  -f -r -n '__fish_doing_using_command finish' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l date  -f  -n '__fish_doing_using_command finish' -d Include\ date
complete -c doing -l from  -f -r -n '__fish_doing_using_command finish' -d Start\ and\ end\ times\ as\ a\ date/time\ range\ \`doing\ done\ --from\ \"1am\ to\ 8am\"\`
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command finish' -d Select\ item\(s\)\ to\ finish\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l not  -f  -n '__fish_doing_using_command finish' -d Finish\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command finish' -d Remove\ @done\ tag
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command finish' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command finish' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l for  -f -r -n '__fish_doing_using_command finish' -d Set\ completion\ date\ to\ start\ date\ plus\ interval
complete -c doing -l tag  -f -r -n '__fish_doing_using_command finish' -d Filter\ entries\ by\ tag
complete -c doing -l unfinished -s u -f  -n '__fish_doing_using_command finish' -d Finish\ last\ entry
complete -c doing -l update  -f  -n '__fish_doing_using_command finish' -d Overwrite\ existing\ @done\ tag\ with\ new\ date
complete -c doing -l val  -f -r -n '__fish_doing_using_command finish' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command finish' -d Force\ exact\ search\ string\ matching
complete -c doing -l after  -f -r -n '__fish_doing_using_command grep search' -d Search\ entries\ newer\ than\ date
complete -c doing -l before  -f -r -n '__fish_doing_using_command grep search' -d Search\ entries\ older\ than\ date
complete -c doing -l bool  -f -r -n '__fish_doing_using_command grep search' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l case  -f -r -n '__fish_doing_using_command grep search' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l config_template  -f -r -n '__fish_doing_using_command grep search' -d Output\ using\ a\ template\ from\ configuration
complete -c doing -l delete -s d -f  -n '__fish_doing_using_command grep search' -d Delete\ matching\ entries
complete -c doing -l duration  -f  -n '__fish_doing_using_command grep search' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command grep search' -d Edit\ matching\ entries\ with\ vim
complete -c doing -l from  -f -r -n '__fish_doing_using_command grep search' -d Date\ range
complete -c doing -l hilite -s h -f  -n '__fish_doing_using_command grep search' -d Highlight\ search\ matches\ in\ output
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command grep search' -d Display\ an\ interactive\ menu\ of\ results\ to\ perform\ further\ operations
complete -c doing -l not  -f  -n '__fish_doing_using_command grep search' -d Search\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command grep search' -d Output\ to\ export\ format
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command grep search' -d Only\ show\ items\ with\ recorded\ time\ intervals
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command grep search' -d Section
complete -c doing -l save  -f -r -n '__fish_doing_using_command grep search' -d Save\ all\ current\ command\ line\ options\ as\ a\ new\ view
complete -c doing -l times -s t -f  -n '__fish_doing_using_command grep search' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag  -f -r -n '__fish_doing_using_command grep search' -d Filter\ entries\ by\ tag
complete -c doing -l tag_order  -f -r -n '__fish_doing_using_command grep search' -d Tag\ sort\ direction
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command grep search' -d Sort\ tags\ by
complete -c doing -l template  -f -r -n '__fish_doing_using_command grep search' -d Override\ output\ format\ with\ a\ template\ string\ containing\ \%placeholders
complete -c doing -l title  -f -r -n '__fish_doing_using_command grep search' -d Title\ string\ to\ be\ used\ for\ output\ formats\ that\ require\ it
complete -c doing -l totals  -f  -n '__fish_doing_using_command grep search' -d Show\ time\ totals\ at\ the\ end\ of\ output
complete -c doing -l val  -f -r -n '__fish_doing_using_command grep search' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command grep search' -d Force\ exact\ string\ matching
complete -c doing -F -n '__fish_doing_using_command import'
complete -c doing -l after  -f -r -n '__fish_doing_using_command import' -d Import\ entries\ newer\ than\ date
complete -c doing -l autotag  -f  -n '__fish_doing_using_command import' -d Autotag\ entries
complete -c doing -l before  -f -r -n '__fish_doing_using_command import' -d Import\ entries\ older\ than\ date
complete -c doing -l case  -f -r -n '__fish_doing_using_command import' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l from  -f -r -n '__fish_doing_using_command import' -d Date\ range
complete -c doing -l not  -f  -n '__fish_doing_using_command import' -d Import\ items\ that\ \*don\'t\*\ match\ search/tag/date\ filters
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command import' -d Only\ import\ items\ with\ recorded\ time\ intervals
complete -c doing -l overlap  -f  -n '__fish_doing_using_command import' -d Allow\ entries\ that\ overlap\ existing\ times
complete -c doing -l prefix  -f -r -n '__fish_doing_using_command import' -d Prefix\ entries\ with
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command import' -d Target\ section
complete -c doing -l search  -f -r -n '__fish_doing_using_command import' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l tag -s t -f -r -n '__fish_doing_using_command import' -d Tag\ all\ imported\ entries
complete -c doing -l type  -f -r -n '__fish_doing_using_command import' -d Import\ type
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command import' -d Force\ exact\ search\ string\ matching
complete -c doing -l bool  -f -r -n '__fish_doing_using_command last' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l case  -f -r -n '__fish_doing_using_command last' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l config_template  -f -r -n '__fish_doing_using_command last' -d Output\ using\ a\ template\ from\ configuration
complete -c doing -l delete -s d -f  -n '__fish_doing_using_command last' -d Delete\ the\ last\ entry
complete -c doing -l duration  -f  -n '__fish_doing_using_command last' -d Show\ elapsed\ time\ if\ entry\ is\ not\ tagged\ @done
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command last' -d Edit\ entry\ with\ vim
complete -c doing -l hilite -s h -f  -n '__fish_doing_using_command last' -d Highlight\ search\ matches\ in\ output
complete -c doing -l not  -f  -n '__fish_doing_using_command last' -d Show\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command last' -d Output\ to\ export\ format
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command last' -d Specify\ a\ section
complete -c doing -l save  -f -r -n '__fish_doing_using_command last' -d Save\ all\ current\ command\ line\ options\ as\ a\ new\ view
complete -c doing -l search  -f -r -n '__fish_doing_using_command last' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l tag  -f -r -n '__fish_doing_using_command last' -d Filter\ entries\ by\ tag
complete -c doing -l template  -f -r -n '__fish_doing_using_command last' -d Override\ output\ format\ with\ a\ template\ string\ containing\ \%placeholders
complete -c doing -l title  -f -r -n '__fish_doing_using_command last' -d Title\ string\ to\ be\ used\ for\ output\ formats\ that\ require\ it
complete -c doing -l val  -f -r -n '__fish_doing_using_command last' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command last' -d Force\ exact\ search\ string\ matching
complete -c doing -l bool  -f -r -n '__fish_doing_using_command mark flag' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l count -s c -f -r -n '__fish_doing_using_command mark flag' -d How\ many\ recent\ entries\ to\ tag
complete -c doing -l case  -f -r -n '__fish_doing_using_command mark flag' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l date -s d -f  -n '__fish_doing_using_command mark flag' -d Include\ current\ date/time\ with\ tag
complete -c doing -l force  -f  -n '__fish_doing_using_command mark flag' -d Don\'t\ ask\ permission\ to\ flag\ all\ entries\ when\ count\ is\ 0
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command mark flag' -d Select\ item\(s\)\ to\ flag\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l not  -f  -n '__fish_doing_using_command mark flag' -d Flag\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command mark flag' -d Remove\ flag
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command mark flag' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command mark flag' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l tag  -f -r -n '__fish_doing_using_command mark flag' -d Filter\ entries\ by\ tag
complete -c doing -l unfinished -s u -f  -n '__fish_doing_using_command mark flag' -d Flag\ last\ entry
complete -c doing -l val  -f -r -n '__fish_doing_using_command mark flag' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command mark flag' -d Force\ exact\ search\ string\ matching
complete -c doing -l noauto -s X -f  -n '__fish_doing_using_command meanwhile' -d Exclude\ auto\ tags\ and\ default\ tags
complete -c doing -l archive -s a -f  -n '__fish_doing_using_command meanwhile' -d Archive\ previous\ @meanwhile\ entry
complete -c doing -l ask  -f  -n '__fish_doing_using_command meanwhile' -d Prompt\ for\ note\ via\ multi-line\ input
complete -c doing -l started  -f -r -n '__fish_doing_using_command meanwhile' -d Backdate\ start\ date\ for\ new\ entry\ to\ date\ string\ \[4pm\|20m\|2h\|yesterday\ noon\]
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command meanwhile' -d Edit\ entry\ with\ vim
complete -c doing -l note -s n -f -r -n '__fish_doing_using_command meanwhile' -d Include\ a\ note
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command meanwhile' -d Section
complete -c doing -l ask  -f  -n '__fish_doing_using_command note' -d Prompt\ for\ note\ via\ multi-line\ input
complete -c doing -l bool  -f -r -n '__fish_doing_using_command note' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l case  -f -r -n '__fish_doing_using_command note' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command note' -d Edit\ entry\ with\ vim
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command note' -d Select\ item\ for\ new\ note\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l not  -f  -n '__fish_doing_using_command note' -d Note\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command note' -d Replace/Remove\ last\ entry\'s\ note
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command note' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command note' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l tag  -f -r -n '__fish_doing_using_command note' -d Filter\ entries\ by\ tag
complete -c doing -l val  -f -r -n '__fish_doing_using_command note' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command note' -d Force\ exact\ search\ string\ matching
complete -c doing -l noauto -s X -f  -n '__fish_doing_using_command now next' -d Exclude\ auto\ tags\ and\ default\ tags
complete -c doing -l ask  -f  -n '__fish_doing_using_command now next' -d Prompt\ for\ note\ via\ multi-line\ input
complete -c doing -l started  -f -r -n '__fish_doing_using_command now next' -d Backdate\ start\ date\ for\ new\ entry\ to\ date\ string\ \[4pm\|20m\|2h\|yesterday\ noon\]
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command now next' -d Edit\ entry\ with\ vim
complete -c doing -l finish_last -s f -f  -n '__fish_doing_using_command now next' -d Timed\ entry
complete -c doing -l from  -f -r -n '__fish_doing_using_command now next' -d Set\ a\ start\ and\ optionally\ end\ time\ as\ a\ date\ range
complete -c doing -l note -s n -f -r -n '__fish_doing_using_command now next' -d Include\ a\ note
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command now next' -d Section
complete -c doing -l after  -f -r -n '__fish_doing_using_command on' -d View\ entries\ after\ specified\ time
complete -c doing -l before  -f -r -n '__fish_doing_using_command on' -d View\ entries\ before\ specified\ time
complete -c doing -l bool  -f -r -n '__fish_doing_using_command on' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l case  -f -r -n '__fish_doing_using_command on' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l config_template  -f -r -n '__fish_doing_using_command on' -d Output\ using\ a\ template\ from\ configuration
complete -c doing -l duration  -f  -n '__fish_doing_using_command on' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l from  -f -r -n '__fish_doing_using_command on' -d Time\ range\ to\ show\ \`doing\ on\ --from\ \"12pm\ to\ 4pm\"\`
complete -c doing -l not  -f  -n '__fish_doing_using_command on' -d Show\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command on' -d Output\ to\ export\ format
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command on' -d Only\ show\ items\ with\ recorded\ time\ intervals
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command on' -d Section
complete -c doing -l save  -f -r -n '__fish_doing_using_command on' -d Save\ all\ current\ command\ line\ options\ as\ a\ new\ view
complete -c doing -l search  -f -r -n '__fish_doing_using_command on' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l times -s t -f  -n '__fish_doing_using_command on' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag  -f -r -n '__fish_doing_using_command on' -d Filter\ entries\ by\ tag
complete -c doing -l tag_order  -f -r -n '__fish_doing_using_command on' -d Tag\ sort\ direction
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command on' -d Sort\ tags\ by
complete -c doing -l template  -f -r -n '__fish_doing_using_command on' -d Override\ output\ format\ with\ a\ template\ string\ containing\ \%placeholders
complete -c doing -l title  -f -r -n '__fish_doing_using_command on' -d Title\ string\ to\ be\ used\ for\ output\ formats\ that\ require\ it
complete -c doing -l totals  -f  -n '__fish_doing_using_command on' -d Show\ time\ totals\ at\ the\ end\ of\ output
complete -c doing -l val  -f -r -n '__fish_doing_using_command on' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command on' -d Force\ exact\ search\ string\ matching
complete -c doing -l app -s a -f -r -n '__fish_doing_using_command open' -d Open\ with\ app\ name
complete -c doing -l bundle_id -s b -f -r -n '__fish_doing_using_command open' -d Open\ with\ app\ bundle\ id
complete -c doing -l editor -s e -f -r -n '__fish_doing_using_command open' -d Open\ with\ editor\ command
complete -c doing -l column -s c -f  -n '__fish_doing_using_command plugins' -d List\ in\ single\ column\ for\ completion
complete -c doing -l type -s t -f -r -n '__fish_doing_using_command plugins' -d List\ plugins\ of\ type
complete -c doing -l config_template  -f -r -n '__fish_doing_using_command recent' -d Output\ using\ a\ template\ from\ configuration
complete -c doing -l duration  -f  -n '__fish_doing_using_command recent' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command recent' -d Select\ from\ a\ menu\ of\ matching\ entries\ to\ perform\ additional\ operations
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command recent' -d Output\ to\ export\ format
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command recent' -d Only\ show\ items\ with\ recorded\ time\ intervals
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command recent' -d Section
complete -c doing -l save  -f -r -n '__fish_doing_using_command recent' -d Save\ all\ current\ command\ line\ options\ as\ a\ new\ view
complete -c doing -l times -s t -f  -n '__fish_doing_using_command recent' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag_order  -f -r -n '__fish_doing_using_command recent' -d Tag\ sort\ direction
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command recent' -d Sort\ tags\ by
complete -c doing -l template  -f -r -n '__fish_doing_using_command recent' -d Override\ output\ format\ with\ a\ template\ string\ containing\ \%placeholders
complete -c doing -l title  -f -r -n '__fish_doing_using_command recent' -d Title\ string\ to\ be\ used\ for\ output\ formats\ that\ require\ it
complete -c doing -l totals  -f  -n '__fish_doing_using_command recent' -d Show\ time\ totals\ at\ the\ end\ of\ output
complete -c doing -l file -s f -f -r -n '__fish_doing_using_command redo' -d Specify\ alternate\ doing\ file
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command redo' -d Select\ from\ an\ interactive\ menu
complete -c doing -l bool  -f -r -n '__fish_doing_using_command reset begin' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l case  -f -r -n '__fish_doing_using_command reset begin' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l from  -f -r -n '__fish_doing_using_command reset begin' -d Start\ and\ end\ times\ as\ a\ date/time\ range\ \`doing\ done\ --from\ \"1am\ to\ 8am\"\`
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command reset begin' -d Select\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l not  -f  -n '__fish_doing_using_command reset begin' -d Reset\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l resume -s r -f  -n '__fish_doing_using_command reset begin' -d Resume\ entry
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command reset begin' -d Limit\ search\ to\ section
complete -c doing -l search  -f -r -n '__fish_doing_using_command reset begin' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l for  -f -r -n '__fish_doing_using_command reset begin' -d Set\ completion\ date\ to\ start\ date\ plus\ interval
complete -c doing -l tag  -f -r -n '__fish_doing_using_command reset begin' -d Filter\ entries\ by\ tag
complete -c doing -l val  -f -r -n '__fish_doing_using_command reset begin' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command reset begin' -d Force\ exact\ search\ string\ matching
complete -c doing -l before  -f -r -n '__fish_doing_using_command rotate' -d Rotate\ entries\ older\ than\ date
complete -c doing -l bool  -f -r -n '__fish_doing_using_command rotate' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l case  -f -r -n '__fish_doing_using_command rotate' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l keep -s k -f -r -n '__fish_doing_using_command rotate' -d How\ many\ items\ to\ keep\ in\ each\ section
complete -c doing -l not  -f  -n '__fish_doing_using_command rotate' -d Rotate\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command rotate' -d Section\ to\ rotate
complete -c doing -l search  -f -r -n '__fish_doing_using_command rotate' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l tag  -f -r -n '__fish_doing_using_command rotate' -d Filter\ entries\ by\ tag
complete -c doing -l val  -f -r -n '__fish_doing_using_command rotate' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command rotate' -d Force\ exact\ search\ string\ matching
complete -c doing -l archive -s a -f  -n '__fish_doing_using_command select' -d Archive\ selected\ items
complete -c doing -l after  -f -r -n '__fish_doing_using_command select' -d Select\ entries\ newer\ than\ date
complete -c doing -l resume  -f  -n '__fish_doing_using_command select' -d Copy\ selection\ as\ a\ new\ entry\ with\ current\ time\ and\ no\ @done\ tag
complete -c doing -l before  -f -r -n '__fish_doing_using_command select' -d Select\ entries\ older\ than\ date
complete -c doing -l cancel -s c -f  -n '__fish_doing_using_command select' -d Cancel\ selected\ items
complete -c doing -l case  -f -r -n '__fish_doing_using_command select' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l delete -s d -f  -n '__fish_doing_using_command select' -d Delete\ selected\ items
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command select' -d Edit\ selected\ item\(s\)
complete -c doing -l finish -s f -f  -n '__fish_doing_using_command select' -d Add\ @done\ with\ current\ time\ to\ selected\ item\(s\)
complete -c doing -l flag  -f  -n '__fish_doing_using_command select' -d Add\ flag\ to\ selected\ item\(s\)
complete -c doing -l force  -f  -n '__fish_doing_using_command select' -d Perform\ action\ without\ confirmation
complete -c doing -l from  -f -r -n '__fish_doing_using_command select' -d Date\ range
complete -c doing -l move -s m -f -r -n '__fish_doing_using_command select' -d Move\ selected\ items\ to\ section
complete -c doing -l menu  -f  -n '__fish_doing_using_command select' -d Use\ --no-menu\ to\ skip\ the\ interactive\ menu
complete -c doing -l not  -f  -n '__fish_doing_using_command select' -d Select\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command select' -d Output\ entries\ to\ format
complete -c doing -l query -s q -f -r -n '__fish_doing_using_command select' -d Initial\ search\ query\ for\ filtering
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command select' -d Reverse\ -c
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command select' -d Select\ from\ a\ specific\ section
complete -c doing -l save_to  -f -r -n '__fish_doing_using_command select' -d Save\ selected\ entries\ to\ file\ using\ --output\ format
complete -c doing -l search  -f -r -n '__fish_doing_using_command select' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l tag -s t -f -r -n '__fish_doing_using_command select' -d Tag\ selected\ entries
complete -c doing -l val  -f -r -n '__fish_doing_using_command select' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command select' -d Force\ exact\ search\ string\ matching
complete -c doing -l age -s a -f -r -n '__fish_doing_using_command show' -d Age
complete -c doing -l after  -f -r -n '__fish_doing_using_command show' -d Show\ entries\ newer\ than\ date
complete -c doing -l before  -f -r -n '__fish_doing_using_command show' -d Show\ entries\ older\ than\ date
complete -c doing -l bool  -f -r -n '__fish_doing_using_command show' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l count -s c -f -r -n '__fish_doing_using_command show' -d Max\ count\ to\ show
complete -c doing -l case  -f -r -n '__fish_doing_using_command show' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l config_template  -f -r -n '__fish_doing_using_command show' -d Output\ using\ a\ template\ from\ configuration
complete -c doing -l duration  -f  -n '__fish_doing_using_command show' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command show' -d Edit\ matching\ entries\ with\ vim
complete -c doing -l from  -f -r -n '__fish_doing_using_command show' -d Date\ range
complete -c doing -l hilite -s h -f  -n '__fish_doing_using_command show' -d Highlight\ search\ matches\ in\ output
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command show' -d Select\ from\ a\ menu\ of\ matching\ entries\ to\ perform\ additional\ operations
complete -c doing -l menu -s m -f  -n '__fish_doing_using_command show' -d Select\ section\ or\ tag\ to\ display\ from\ a\ menu
complete -c doing -l not  -f  -n '__fish_doing_using_command show' -d Show\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command show' -d Output\ to\ export\ format
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command show' -d Only\ show\ items\ with\ recorded\ time\ intervals
complete -c doing -l sort -s s -f -r -n '__fish_doing_using_command show' -d Sort\ order
complete -c doing -l save  -f -r -n '__fish_doing_using_command show' -d Save\ all\ current\ command\ line\ options\ as\ a\ new\ view
complete -c doing -l search  -f -r -n '__fish_doing_using_command show' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l times -s t -f  -n '__fish_doing_using_command show' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag  -f -r -n '__fish_doing_using_command show' -d Filter\ entries\ by\ tag
complete -c doing -l tag_order  -f -r -n '__fish_doing_using_command show' -d Tag\ sort\ direction
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command show' -d Sort\ tags\ by
complete -c doing -l template  -f -r -n '__fish_doing_using_command show' -d Override\ output\ format\ with\ a\ template\ string\ containing\ \%placeholders
complete -c doing -l title  -f -r -n '__fish_doing_using_command show' -d Title\ string\ to\ be\ used\ for\ output\ formats\ that\ require\ it
complete -c doing -l totals  -f  -n '__fish_doing_using_command show' -d Show\ time\ totals\ at\ the\ end\ of\ output
complete -c doing -l val  -f -r -n '__fish_doing_using_command show' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command show' -d Force\ exact\ search\ string\ matching
complete -c doing -l bool  -f -r -n '__fish_doing_using_command since' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l case  -f -r -n '__fish_doing_using_command since' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l config_template  -f -r -n '__fish_doing_using_command since' -d Output\ using\ a\ template\ from\ configuration
complete -c doing -l duration  -f  -n '__fish_doing_using_command since' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l not  -f  -n '__fish_doing_using_command since' -d Since\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command since' -d Output\ to\ export\ format
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command since' -d Only\ show\ items\ with\ recorded\ time\ intervals
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command since' -d Section
complete -c doing -l save  -f -r -n '__fish_doing_using_command since' -d Save\ all\ current\ command\ line\ options\ as\ a\ new\ view
complete -c doing -l search  -f -r -n '__fish_doing_using_command since' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l times -s t -f  -n '__fish_doing_using_command since' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag  -f -r -n '__fish_doing_using_command since' -d Filter\ entries\ by\ tag
complete -c doing -l tag_order  -f -r -n '__fish_doing_using_command since' -d Tag\ sort\ direction
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command since' -d Sort\ tags\ by
complete -c doing -l template  -f -r -n '__fish_doing_using_command since' -d Override\ output\ format\ with\ a\ template\ string\ containing\ \%placeholders
complete -c doing -l title  -f -r -n '__fish_doing_using_command since' -d Title\ string\ to\ be\ used\ for\ output\ formats\ that\ require\ it
complete -c doing -l totals  -f  -n '__fish_doing_using_command since' -d Show\ time\ totals\ at\ the\ end\ of\ output
complete -c doing -l val  -f -r -n '__fish_doing_using_command since' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command since' -d Force\ exact\ search\ string\ matching
complete -c doing -l autotag -s a -f  -n '__fish_doing_using_command tag' -d Autotag\ entries\ based\ on\ autotag\ configuration\ in\ \~/
complete -c doing -l bool  -f -r -n '__fish_doing_using_command tag' -d Boolean\ used\ to\ combine\ multiple\ tags
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
complete -c doing -l search  -f -r -n '__fish_doing_using_command tag' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l tag  -f -r -n '__fish_doing_using_command tag' -d Filter\ entries\ by\ tag
complete -c doing -l unfinished -s u -f  -n '__fish_doing_using_command tag' -d Tag\ last\ entry
complete -c doing -l value -s v -f -r -n '__fish_doing_using_command tag' -d Include\ a\ value
complete -c doing -l val  -f -r -n '__fish_doing_using_command tag' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command tag' -d Force\ exact\ search\ string\ matching
complete -c doing -l clear  -f  -n '__fish_doing_using_command tag_dir' -d Remove\ all\ default_tags\ from\ the\ local
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command tag_dir' -d Use\ default\ editor\ to\ edit\ tag\ list
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command tag_dir' -d Delete\ tag\(s\)\ from\ the\ current\ list
complete -c doing -l bool  -f -r -n '__fish_doing_using_command tags' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l counts -s c -f  -n '__fish_doing_using_command tags' -d Show\ count\ of\ occurrences
complete -c doing -l case  -f -r -n '__fish_doing_using_command tags' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command tags' -d Select\ items\ to\ scan\ from\ a\ menu\ of\ matching\ entries
complete -c doing -l line -s l -f  -n '__fish_doing_using_command tags' -d Output\ in\ a\ single\ line\ with\ @\ symbols
complete -c doing -l not  -f  -n '__fish_doing_using_command tags' -d Show\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l order -s o -f -r -n '__fish_doing_using_command tags' -d Sort\ order
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command tags' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command tags' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l sort  -f -r -n '__fish_doing_using_command tags' -d Sort\ by\ name\ or\ count
complete -c doing -l tag  -f -r -n '__fish_doing_using_command tags' -d Filter\ entries\ by\ tag
complete -c doing -l val  -f -r -n '__fish_doing_using_command tags' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command tags' -d Force\ exact\ search\ string\ matching
complete -c doing -l column -s c -f  -n '__fish_doing_using_command template' -d List\ in\ single\ column\ for\ completion
complete -c doing -l list -s l -f  -n '__fish_doing_using_command template' -d List\ all\ available\ templates
complete -c doing -l path -s p -f -r -n '__fish_doing_using_command template' -d Save\ template\ to\ alternate\ location
complete -c doing -l save -s s -f  -n '__fish_doing_using_command template' -d Save\ template\ to\ file\ instead\ of\ STDOUT
complete -c doing -l after  -f -r -n '__fish_doing_using_command today' -d View\ entries\ after\ specified\ time
complete -c doing -l before  -f -r -n '__fish_doing_using_command today' -d View\ entries\ before\ specified\ time
complete -c doing -l config_template  -f -r -n '__fish_doing_using_command today' -d Output\ using\ a\ template\ from\ configuration
complete -c doing -l duration  -f  -n '__fish_doing_using_command today' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l from  -f -r -n '__fish_doing_using_command today' -d Time\ range\ to\ show\ \`doing\ today\ --from\ \"12pm\ to\ 4pm\"\`
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command today' -d Output\ to\ export\ format
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command today' -d Only\ show\ items\ with\ recorded\ time\ intervals
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command today' -d Specify\ a\ section
complete -c doing -l save  -f -r -n '__fish_doing_using_command today' -d Save\ all\ current\ command\ line\ options\ as\ a\ new\ view
complete -c doing -l times -s t -f  -n '__fish_doing_using_command today' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag_order  -f -r -n '__fish_doing_using_command today' -d Tag\ sort\ direction
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command today' -d Sort\ tags\ by
complete -c doing -l template  -f -r -n '__fish_doing_using_command today' -d Override\ output\ format\ with\ a\ template\ string\ containing\ \%placeholders
complete -c doing -l title  -f -r -n '__fish_doing_using_command today' -d Title\ string\ to\ be\ used\ for\ output\ formats\ that\ require\ it
complete -c doing -l totals  -f  -n '__fish_doing_using_command today' -d Show\ time\ totals\ at\ the\ end\ of\ output
complete -c doing -l file -s f -f -r -n '__fish_doing_using_command undo' -d Specify\ alternate\ doing\ file
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command undo' -d Select\ from\ recent\ backups
complete -c doing -l prune -s p -f -r -n '__fish_doing_using_command undo' -d Remove\ old\ backups
complete -c doing -l redo -s r -f  -n '__fish_doing_using_command undo' -d Redo\ last\ undo
complete -c doing -l after  -f -r -n '__fish_doing_using_command view' -d Show\ entries\ newer\ than\ date
complete -c doing -l age  -f -r -n '__fish_doing_using_command view' -d Age
complete -c doing -l before  -f -r -n '__fish_doing_using_command view' -d Show\ entries\ older\ than\ date
complete -c doing -l bool  -f -r -n '__fish_doing_using_command view' -d Boolean\ used\ to\ combine\ multiple\ tags
complete -c doing -l count -s c -f -r -n '__fish_doing_using_command view' -d Count\ to\ display
complete -c doing -l case  -f -r -n '__fish_doing_using_command view' -d Case\ sensitivity\ for\ search\ string\ matching\ \[\(c\)ase-sensitive
complete -c doing -l color  -f  -n '__fish_doing_using_command view' -d Include\ colors\ in\ output
complete -c doing -l config_template  -f -r -n '__fish_doing_using_command view' -d Output\ using\ a\ template\ from\ configuration
complete -c doing -l duration  -f  -n '__fish_doing_using_command view' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l from  -f -r -n '__fish_doing_using_command view' -d Date\ range
complete -c doing -l hilite -s h -f  -n '__fish_doing_using_command view' -d Highlight\ search\ matches\ in\ output
complete -c doing -l interactive -s i -f  -n '__fish_doing_using_command view' -d Select\ from\ a\ menu\ of\ matching\ entries\ to\ perform\ additional\ operations
complete -c doing -l not  -f  -n '__fish_doing_using_command view' -d Show\ items\ that\ \*don\'t\*\ match\ search/tag\ filters
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command view' -d Output\ to\ export\ format
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command view' -d Only\ show\ items\ with\ recorded\ time\ intervals
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command view' -d Section
complete -c doing -l search  -f -r -n '__fish_doing_using_command view' -d Filter\ entries\ using\ a\ search\ query
complete -c doing -l times -s t -f  -n '__fish_doing_using_command view' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag  -f -r -n '__fish_doing_using_command view' -d Filter\ entries\ by\ tag
complete -c doing -l tag_order  -f -r -n '__fish_doing_using_command view' -d Tag\ sort\ direction
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command view' -d Sort\ tags\ by
complete -c doing -l template  -f -r -n '__fish_doing_using_command view' -d Override\ output\ format\ with\ a\ template\ string\ containing\ \%placeholders
complete -c doing -l totals  -f  -n '__fish_doing_using_command view' -d Show\ intervals\ with\ totals\ at\ the\ end\ of\ output
complete -c doing -l val  -f -r -n '__fish_doing_using_command view' -d Perform\ a\ tag\ value\ query
complete -c doing -l exact -s x -f  -n '__fish_doing_using_command view' -d Force\ exact\ search\ string\ matching
complete -c doing -l column -s c -f  -n '__fish_doing_using_command views' -d List\ in\ single\ column
complete -c doing -l editor -s e -f  -n '__fish_doing_using_command views' -d Open\ YAML\ for\ view\ in\ editor
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command views' -d Output/edit\ view\ in\ alternative\ format
complete -c doing -l remove -s r -f  -n '__fish_doing_using_command views' -d Delete\ view\ config
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
complete -c doing -l config_template  -f -r -n '__fish_doing_using_command yesterday' -d Output\ using\ a\ template\ from\ configuration
complete -c doing -l duration  -f  -n '__fish_doing_using_command yesterday' -d Show\ elapsed\ time\ on\ entries\ without\ @done\ tag
complete -c doing -l from  -f -r -n '__fish_doing_using_command yesterday' -d Time\ range\ to\ show\ \`doing\ yesterday\ --from\ \"12pm\ to\ 4pm\"\`
complete -c doing -l output -s o -f -r -n '__fish_doing_using_command yesterday' -d Output\ to\ export\ format
complete -c doing -l only_timed  -f  -n '__fish_doing_using_command yesterday' -d Only\ show\ items\ with\ recorded\ time\ intervals
complete -c doing -l section -s s -f -r -n '__fish_doing_using_command yesterday' -d Specify\ a\ section
complete -c doing -l save  -f -r -n '__fish_doing_using_command yesterday' -d Save\ all\ current\ command\ line\ options\ as\ a\ new\ view
complete -c doing -l times -s t -f  -n '__fish_doing_using_command yesterday' -d Show\ time\ intervals\ on\ @done\ tasks
complete -c doing -l tag_order  -f -r -n '__fish_doing_using_command yesterday' -d Tag\ sort\ direction
complete -c doing -l tag_sort  -f -r -n '__fish_doing_using_command yesterday' -d Sort\ tags\ by
complete -c doing -l template  -f -r -n '__fish_doing_using_command yesterday' -d Override\ output\ format\ with\ a\ template\ string\ containing\ \%placeholders
complete -c doing -l title  -f -r -n '__fish_doing_using_command yesterday' -d Title\ string\ to\ be\ used\ for\ output\ formats\ that\ require\ it
complete -c doing -l totals  -f  -n '__fish_doing_using_command yesterday' -d Show\ time\ totals\ at\ the\ end\ of\ output
complete -f -c doing -s o -l output -x -n '__fish_doing_using_command grep search last on recent select show since today view views yesterday' -a '(__fish_doing_export_plugin)'
complete -f -c doing -s b -l bool -x -n '__fish_doing_using_command again resume archive move autotag cancel finish grep search last mark flag note on reset begin rotate show since tag tags view wiki' -a 'and or not pattern'
complete -f -c doing -l case -x -n '__fish_doing_using_command again resume archive move cancel finish grep search import last mark flag note on reset begin rotate select show since tag tags view' -a 'case-sensitive ignore smart'
complete -f -c doing -l sort -x -n '__fish_doing_using_command changes changelog show tags' -a 'asc desc'
complete -f -c doing -l tag_sort -x -n '__fish_doing_using_command grep search on recent show since today view yesterday' -a 'name time'
complete -f -c doing -l tag_order -x -n '__fish_doing_using_command grep search on recent show since today view yesterday' -a 'asc desc'
complete -f -c doing -s a -l age -x -n '__fish_doing_using_command show view' -a 'oldest newest'
complete -f -c doing -s s -l section -x -n '__fish_doing_using_command again resume autotag cancel done did finish grep search import last mark flag meanwhile note now next on recent reset begin rotate select since tag tags today view wiki yesterday' -a '(__fish_doing_complete_sections)'
