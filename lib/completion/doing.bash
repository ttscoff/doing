_doing_again() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--noauto --ask --since --bool --case --editor --interactive --in --note --not --section --search --tag --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-X -e -i -n -s -x --noauto --ask --since --bool --case --editor --interactive --in --note --not --section --search --tag --val --exact' -- $token ) )
  
  fi
}

_doing_archive() {
  OLD_IFS="$IFS"
local token=${COMP_WORDS[$COMP_CWORD]}
IFS=$'	'
local words=$(doing sections)
IFS="$OLD_IFS"

  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--after --before --bool --case --from --keep --label --not --search --to --tag --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-k -t -x --after --before --bool --case --from --keep --label --not --search --to --tag --val --exact' -- $token ) )
  else
  local nocasematchWasOff=0
  shopt nocasematch >/dev/null || nocasematchWasOff=1
  (( nocasematchWasOff )) && shopt -s nocasematch
  local w matches=()
  OLD_IFS="$IFS"
  IFS=$'	'‰
  for w in $words; do
    if [[ "$w" == "$token"* ]]; then
      matches+=("${w// / }")
    fi
  done
  IFS="$OLD_IFS"
  (( nocasematchWasOff )) && shopt -u nocasematch
  COMPREPLY=("${matches[@]}")

  fi
}

_doing_autotag() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--bool --count --force --interactive --section --search --tag --unfinished' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-c -i -s -u --bool --count --force --interactive --section --search --tag --unfinished' -- $token ) )
  
  fi
}

_doing_cancel() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--archive --bool --case --interactive --not --section --search --tag --unfinished --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -i -s -u -x --archive --bool --case --interactive --not --section --search --tag --unfinished --val --exact' -- $token ) )
  
  fi
}

_doing_changes() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--changes --all --interactive --lookup --markdown --only --prefix --render --search --sort' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-C -a -i -l -p -s --changes --all --interactive --lookup --markdown --only --prefix --render --search --sort' -- $token ) )
  
  fi
}

_doing_completion() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--type' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-t --type' -- $token ) )
  
  fi
}

_doing_config() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--dump --update' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-d -u --dump --update' -- $token ) )
  
  fi
}

_doing_done() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--noauto --archive --ask --finished --since --date --editor --from --note --remove --section --for --unfinished' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-X -a -e -n -r -s -u --noauto --archive --ask --finished --since --date --editor --from --note --remove --section --for --unfinished' -- $token ) )
  
  fi
}

_doing_finish() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--archive --finished --auto --started --bool --case --date --from --interactive --not --remove --section --search --for --tag --unfinished --update --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -i -r -s -u -x --archive --finished --auto --started --bool --case --date --from --interactive --not --remove --section --search --for --tag --unfinished --update --val --exact' -- $token ) )
  
  fi
}

_doing_grep() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--after --before --bool --case --config_template --delete --duration --editor --from --hilite --interactive --not --output --only_timed --section --save --times --tag --tag_order --tag_sort --template --title --totals --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-d -e -h -i -o -s -t -x --after --before --bool --case --config_template --delete --duration --editor --from --hilite --interactive --not --output --only_timed --section --save --times --tag --tag_order --tag_sort --template --title --totals --val --exact' -- $token ) )
  
  fi
}

_doing_help() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W ' ' -- $token ) )
  
  fi
}

_doing_import() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--after --autotag --before --case --from --not --only_timed --overlap --prefix --section --search --tag --type --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-s -t -x --after --autotag --before --case --from --not --only_timed --overlap --prefix --section --search --tag --type --exact' -- $token ) )
  
  fi
}

_doing_last() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--bool --case --config_template --delete --duration --editor --hilite --not --output --section --save --search --tag --template --title --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-d -e -h -o -s -x --bool --case --config_template --delete --duration --editor --hilite --not --output --section --save --search --tag --template --title --val --exact' -- $token ) )
  
  fi
}

_doing_mark() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--bool --count --case --date --force --interactive --not --remove --section --search --tag --unfinished --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-c -d -i -r -s -u -x --bool --count --case --date --force --interactive --not --remove --section --search --tag --unfinished --val --exact' -- $token ) )
  
  fi
}

_doing_meanwhile() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--noauto --archive --ask --since --editor --note --section' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-X -a -e -n -s --noauto --archive --ask --since --editor --note --section' -- $token ) )
  
  fi
}

_doing_note() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--ask --bool --case --editor --interactive --not --remove --section --search --tag --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-e -i -r -s -x --ask --bool --case --editor --interactive --not --remove --section --search --tag --val --exact' -- $token ) )
  
  fi
}

_doing_now() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--noauto --ask --since --editor --finish_last --from --note --section' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-X -e -f -n -s --noauto --ask --since --editor --finish_last --from --note --section' -- $token ) )
  
  fi
}

_doing_on() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--after --before --bool --case --config_template --duration --from --not --output --only_timed --section --save --search --times --tag --tag_order --tag_sort --template --title --totals --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-o -s -t -x --after --before --bool --case --config_template --duration --from --not --output --only_timed --section --save --search --times --tag --tag_order --tag_sort --template --title --totals --val --exact' -- $token ) )
  
  fi
}

_doing_open() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--app --bundle_id --editor' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -b -e --app --bundle_id --editor' -- $token ) )
  
  fi
}

_doing_plugins() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--column --type' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-c -t --column --type' -- $token ) )
  
  fi
}

_doing_recent() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--config_template --duration --interactive --output --only_timed --section --save --times --tag_order --tag_sort --template --title --totals' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-i -o -s -t --config_template --duration --interactive --output --only_timed --section --save --times --tag_order --tag_sort --template --title --totals' -- $token ) )
  
  fi
}

_doing_redo() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--file --interactive' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-f -i --file --interactive' -- $token ) )
  
  fi
}

_doing_reset() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--bool --case --from --interactive --not --resume --section --search --for --tag --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-i -r -s -x --bool --case --from --interactive --not --resume --section --search --for --tag --val --exact' -- $token ) )
  
  fi
}

_doing_rotate() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--before --bool --case --keep --not --section --search --tag --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-k -s -x --before --bool --case --keep --not --section --search --tag --val --exact' -- $token ) )
  
  fi
}

_doing_select() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--archive --after --resume --before --cancel --case --delete --editor --finish --flag --force --from --move --menu --not --output --query --remove --section --save_to --search --tag --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -c -d -e -f -m -o -q -r -s -t -x --archive --after --resume --before --cancel --case --delete --editor --finish --flag --force --from --move --menu --not --output --query --remove --section --save_to --search --tag --val --exact' -- $token ) )
  
  fi
}

_doing_show() {
  OLD_IFS="$IFS"
local token=${COMP_WORDS[$COMP_CWORD]}
IFS=$'	'
local words=$(doing sections)
IFS="$OLD_IFS"

  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--age --after --before --bool --count --case --config_template --duration --editor --from --hilite --interactive --menu --not --output --only_timed --section --save --search --sort --times --tag --tag_order --tag_sort --template --title --totals --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -c -e -h -i -m -o -s -t -x --age --after --before --bool --count --case --config_template --duration --editor --from --hilite --interactive --menu --not --output --only_timed --section --save --search --sort --times --tag --tag_order --tag_sort --template --title --totals --val --exact' -- $token ) )
  else
  local nocasematchWasOff=0
  shopt nocasematch >/dev/null || nocasematchWasOff=1
  (( nocasematchWasOff )) && shopt -s nocasematch
  local w matches=()
  OLD_IFS="$IFS"
  IFS=$'	'‰
  for w in $words; do
    if [[ "$w" == "$token"* ]]; then
      matches+=("${w// / }")
    fi
  done
  IFS="$OLD_IFS"
  (( nocasematchWasOff )) && shopt -u nocasematch
  COMPREPLY=("${matches[@]}")

  fi
}

_doing_since() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--bool --case --config_template --duration --not --output --only_timed --section --save --search --times --tag --tag_order --tag_sort --template --title --totals --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-o -s -t -x --bool --case --config_template --duration --not --output --only_timed --section --save --search --times --tag --tag_order --tag_sort --template --title --totals --val --exact' -- $token ) )
  
  fi
}

_doing_tag() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--autotag --bool --count --case --date --force --interactive --not --remove --regex --rename --section --search --tag --unfinished --value --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -c -d -i -r -s -u -v -x --autotag --bool --count --case --date --force --interactive --not --remove --regex --rename --section --search --tag --unfinished --value --val --exact' -- $token ) )
  
  fi
}

_doing_tag_dir() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--clear --editor --remove' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-e -r --clear --editor --remove' -- $token ) )
  
  fi
}

_doing_tags() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--bool --counts --case --interactive --line --not --order --section --search --sort --tag --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-c -i -l -o -s -x --bool --counts --case --interactive --line --not --order --section --search --sort --tag --val --exact' -- $token ) )
  
  fi
}

_doing_template() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--column --list --path --save' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-c -l -p -s --column --list --path --save' -- $token ) )
  
  fi
}

_doing_today() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--after --before --config_template --duration --from --output --only_timed --section --save --times --tag_order --tag_sort --template --title --totals' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-o -s -t --after --before --config_template --duration --from --output --only_timed --section --save --times --tag_order --tag_sort --template --title --totals' -- $token ) )
  
  fi
}

_doing_undo() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--file --interactive --prune --redo' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-f -i -p -r --file --interactive --prune --redo' -- $token ) )
  
  fi
}

_doing_update() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--beta' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W ' --beta' -- $token ) )
  
  fi
}

_doing_view() {
  OLD_IFS="$IFS"
local token=${COMP_WORDS[$COMP_CWORD]}
IFS=$'	'
local words=$(doing views)
IFS="$OLD_IFS"

  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--after --age --before --bool --count --case --color --config_template --duration --from --hilite --interactive --not --output --only_timed --section --search --times --tag --tag_order --tag_sort --template --totals --val --exact' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-c -h -i -o -s -t -x --after --age --before --bool --count --case --color --config_template --duration --from --hilite --interactive --not --output --only_timed --section --search --times --tag --tag_order --tag_sort --template --totals --val --exact' -- $token ) )
  else
  local nocasematchWasOff=0
  shopt nocasematch >/dev/null || nocasematchWasOff=1
  (( nocasematchWasOff )) && shopt -s nocasematch
  local w matches=()
  OLD_IFS="$IFS"
  IFS=$'	'‰
  for w in $words; do
    if [[ "$w" == "$token"* ]]; then
      matches+=("${w// / }")
    fi
  done
  IFS="$OLD_IFS"
  (( nocasematchWasOff )) && shopt -u nocasematch
  COMPREPLY=("${matches[@]}")

  fi
}

_doing_views() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--column --editor --output --remove' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-c -e -o -r --column --editor --output --remove' -- $token ) )
  
  fi
}

_doing_wiki() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--after --bool --before --from --only_timed --section --search --tag' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-b -f -s --after --bool --before --from --only_timed --section --search --tag' -- $token ) )
  
  fi
}

_doing_yesterday() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--after --before --config_template --duration --from --output --only_timed --section --save --times --tag_order --tag_sort --template --title --totals' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-o -s -t --after --before --config_template --duration --from --output --only_timed --section --save --times --tag_order --tag_sort --template --title --totals' -- $token ) )
  
  fi
}

_doing()
{
  local last="${@: -1}"
  local token=${COMP_WORDS[$COMP_CWORD]}

  if [[ $last =~ (again|resume) ]]; then _doing_again
    elif [[ $last =~ (archive|move) ]]; then _doing_archive
    elif [[ $last =~ (autotag) ]]; then _doing_autotag
    elif [[ $last =~ (cancel) ]]; then _doing_cancel
    elif [[ $last =~ (changes|changelog) ]]; then _doing_changes
    elif [[ $last =~ (completion) ]]; then _doing_completion
    elif [[ $last =~ (config) ]]; then _doing_config
    elif [[ $last =~ (done|did) ]]; then _doing_done
    elif [[ $last =~ (finish) ]]; then _doing_finish
    elif [[ $last =~ (grep|search) ]]; then _doing_grep
    elif [[ $last =~ (help) ]]; then _doing_help
    elif [[ $last =~ (import) ]]; then _doing_import
    elif [[ $last =~ (last) ]]; then _doing_last
    elif [[ $last =~ (mark|flag) ]]; then _doing_mark
    elif [[ $last =~ (meanwhile) ]]; then _doing_meanwhile
    elif [[ $last =~ (note) ]]; then _doing_note
    elif [[ $last =~ (now|next) ]]; then _doing_now
    elif [[ $last =~ (on) ]]; then _doing_on
    elif [[ $last =~ (open) ]]; then _doing_open
    elif [[ $last =~ (plugins) ]]; then _doing_plugins
    elif [[ $last =~ (recent) ]]; then _doing_recent
    elif [[ $last =~ (redo) ]]; then _doing_redo
    elif [[ $last =~ (reset|begin) ]]; then _doing_reset
    elif [[ $last =~ (rotate) ]]; then _doing_rotate
    elif [[ $last =~ (select) ]]; then _doing_select
    elif [[ $last =~ (show) ]]; then _doing_show
    elif [[ $last =~ (since) ]]; then _doing_since
    elif [[ $last =~ (tag) ]]; then _doing_tag
    elif [[ $last =~ (tag_dir) ]]; then _doing_tag_dir
    elif [[ $last =~ (tags) ]]; then _doing_tags
    elif [[ $last =~ (template) ]]; then _doing_template
    elif [[ $last =~ (today) ]]; then _doing_today
    elif [[ $last =~ (undo) ]]; then _doing_undo
    elif [[ $last =~ (update) ]]; then _doing_update
    elif [[ $last =~ (view) ]]; then _doing_view
    elif [[ $last =~ (views) ]]; then _doing_views
    elif [[ $last =~ (wiki) ]]; then _doing_wiki
    elif [[ $last =~ (yesterday) ]]; then _doing_yesterday
  else
    OLD_IFS="$IFS"
    IFS=$'
'
    COMPREPLY=( $(compgen -W "$(doing help -c)" -- $token) )
    IFS="$OLD_IFS"
  fi
}

complete -F _doing doing
