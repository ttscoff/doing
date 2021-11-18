_doing_again() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--bool --editor --interactive --in --note --section --search --tag' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-e -i -n -s --bool --editor --interactive --in --note --section --search --tag' -- $token ) )
  
  fi
}

_doing_archive() {
  OLD_IFS="$IFS"
local token=${COMP_WORDS[$COMP_CWORD]}
IFS=$'	'
local words=$(doing sections)
IFS="$OLD_IFS"

  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--before --bool --keep --label --search --to --tag' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-k -t --before --bool --keep --label --search --to --tag' -- $token ) )
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
    COMPREPLY=( $( compgen -W '--archive --bool --interactive --section --tag --unfinished' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -i -s -u --archive --bool --interactive --section --tag --unfinished' -- $token ) )
  
  fi
}

_doing_config() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--dump --editor --output --update' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-d -e -o -u --dump --editor --output --update' -- $token ) )
  
  fi
}

_doing_done() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--archive --at --back --date --editor --note --remove --section --took --unfinished' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -b -e -n -r -s -t -u --archive --at --back --date --editor --note --remove --section --took --unfinished' -- $token ) )
  
  fi
}

_doing_finish() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--archive --at --auto --back --bool --date --interactive --remove --section --search --took --tag --unfinished' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -b -i -r -s -t -u --archive --at --auto --back --bool --date --interactive --remove --section --search --took --tag --unfinished' -- $token ) )
  
  fi
}

_doing_grep() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--after --before --interactive --output --only_timed --section --times --tag_sort --totals' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-i -o -s -t --after --before --interactive --output --only_timed --section --times --tag_sort --totals' -- $token ) )
  
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
    COMPREPLY=( $( compgen -W '--after --autotag --before --from --only_timed --overlap --prefix --section --search --tag --type' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-f -s --after --autotag --before --from --only_timed --overlap --prefix --section --search --tag --type' -- $token ) )
  
  fi
}

_doing_last() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--bool --editor --section --search --tag' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-e -s --bool --editor --section --search --tag' -- $token ) )
  
  fi
}

_doing_later() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--back --editor --note' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-b -e -n --back --editor --note' -- $token ) )
  
  fi
}

_doing_mark() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--bool --count --date --force --interactive --remove --section --search --tag --unfinished' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-c -d -i -r -s -u --bool --count --date --force --interactive --remove --section --search --tag --unfinished' -- $token ) )
  
  fi
}

_doing_meanwhile() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--archive --back --editor --note --section' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -b -e -n -s --archive --back --editor --note --section' -- $token ) )
  
  fi
}

_doing_note() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--bool --editor --interactive --remove --section --search --tag' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-e -i -r -s --bool --editor --interactive --remove --section --search --tag' -- $token ) )
  
  fi
}

_doing_now() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--back --editor --finish_last --note --section' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-b -e -f -n -s --back --editor --finish_last --note --section' -- $token ) )
  
  fi
}

_doing_on() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--output --section --times --tag_sort --totals' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-o -s -t --output --section --times --tag_sort --totals' -- $token ) )
  
  fi
}

_doing_open() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--app --bundle_id' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -b --app --bundle_id' -- $token ) )
  
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
    COMPREPLY=( $( compgen -W '--interactive --section --times --tag_sort --totals' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-i -s -t --interactive --section --times --tag_sort --totals' -- $token ) )
  
  fi
}

_doing_reset() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--bool --interactive --resume --section --search --tag' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-i -r -s --bool --interactive --resume --section --search --tag' -- $token ) )
  
  fi
}

_doing_rotate() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--before --bool --keep --section --search --tag' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-k -s --before --bool --keep --section --search --tag' -- $token ) )
  
  fi
}

_doing_sections() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--column' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-c --column' -- $token ) )
  
  fi
}

_doing_select() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--archive --resume --cancel --delete --editor --finish --flag --force --move --menu --output --search --remove --section --save_to --tag' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -c -d -e -f -m -o -r -s -t --archive --resume --cancel --delete --editor --finish --flag --force --move --menu --output --search --remove --section --save_to --tag' -- $token ) )
  
  fi
}

_doing_show() {
  OLD_IFS="$IFS"
local token=${COMP_WORDS[$COMP_CWORD]}
IFS=$'	'
local words=$(doing sections)
IFS="$OLD_IFS"

  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--age --after --bool --before --count --from --interactive --output --only_timed --sort --search --times --tag --tag_order --tag_sort --totals' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -b -c -f -i -o -s -t --age --after --bool --before --count --from --interactive --output --only_timed --sort --search --times --tag --tag_order --tag_sort --totals' -- $token ) )
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
    COMPREPLY=( $( compgen -W '--output --section --times --tag_sort --totals' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-o -s -t --output --section --times --tag_sort --totals' -- $token ) )
  
  fi
}

_doing_tag() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--autotag --bool --count --date --force --interactive --remove --regex --rename --section --search --tag --unfinished' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-a -c -d -i -r -s -u --autotag --bool --count --date --force --interactive --remove --regex --rename --section --search --tag --unfinished' -- $token ) )
  
  fi
}

_doing_template() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--list' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-l --list' -- $token ) )
  
  fi
}

_doing_today() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--after --before --output --section --times --tag_sort --totals' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-o -s -t --after --before --output --section --times --tag_sort --totals' -- $token ) )
  
  fi
}

_doing_undo() {
  
  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--file' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-f --file' -- $token ) )
  
  fi
}

_doing_view() {
  OLD_IFS="$IFS"
local token=${COMP_WORDS[$COMP_CWORD]}
IFS=$'	'
local words=$(doing views)
IFS="$OLD_IFS"

  if [[ "$token" == --* ]]; then
    COMPREPLY=( $( compgen -W '--after --bool --before --count --color --interactive --output --only_timed --section --search --times --tag --tag_order --tag_sort --totals' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-b -c -i -o -s -t --after --bool --before --count --color --interactive --output --only_timed --section --search --times --tag --tag_order --tag_sort --totals' -- $token ) )
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
    COMPREPLY=( $( compgen -W '--column' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-c --column' -- $token ) )
  
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
    COMPREPLY=( $( compgen -W '--after --before --output --section --times --tag_order --tag_sort --totals' -- $token ) )
  elif [[ "$token" == -* ]]; then
    COMPREPLY=( $( compgen -W '-o -s -t --after --before --output --section --times --tag_order --tag_sort --totals' -- $token ) )
  
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
    elif [[ $last =~ (config) ]]; then _doing_config
    elif [[ $last =~ (done|did) ]]; then _doing_done
    elif [[ $last =~ (finish) ]]; then _doing_finish
    elif [[ $last =~ (grep|search) ]]; then _doing_grep
    elif [[ $last =~ (help) ]]; then _doing_help
    elif [[ $last =~ (import) ]]; then _doing_import
    elif [[ $last =~ (last) ]]; then _doing_last
    elif [[ $last =~ (later) ]]; then _doing_later
    elif [[ $last =~ (mark|flag) ]]; then _doing_mark
    elif [[ $last =~ (meanwhile) ]]; then _doing_meanwhile
    elif [[ $last =~ (note) ]]; then _doing_note
    elif [[ $last =~ (now|next) ]]; then _doing_now
    elif [[ $last =~ (on) ]]; then _doing_on
    elif [[ $last =~ (open) ]]; then _doing_open
    elif [[ $last =~ (plugins) ]]; then _doing_plugins
    elif [[ $last =~ (recent) ]]; then _doing_recent
    elif [[ $last =~ (reset|begin) ]]; then _doing_reset
    elif [[ $last =~ (rotate) ]]; then _doing_rotate
    elif [[ $last =~ (sections) ]]; then _doing_sections
    elif [[ $last =~ (select) ]]; then _doing_select
    elif [[ $last =~ (show) ]]; then _doing_show
    elif [[ $last =~ (since) ]]; then _doing_since
    elif [[ $last =~ (tag) ]]; then _doing_tag
    elif [[ $last =~ (template) ]]; then _doing_template
    elif [[ $last =~ (today) ]]; then _doing_today
    elif [[ $last =~ (undo) ]]; then _doing_undo
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
