# Bash completion for `doing` <http://brettterpstra.com/projects/doing>
# Completes commands, views, and section titles

_doing_show() {
	OLD_IFS="$IFS"
	local token=${COMP_WORDS[$COMP_CWORD]}
	IFS=$'\t'
	local words=$(doing sections)
	IFS="$OLD_IFS"


	if [[ "$token" == --* ]]; then
		COMPREPLY=( $( compgen -W '--boolean --count --age --sort --times --totals --csv' -- $token ) )
	elif [[ "$token" == -* ]]; then
		COMPREPLY=( $( compgen -W '-b -c -a -s -t --boolean --count --age --sort --times --totals --csv' -- $token ) )
	else

		local nocasematchWasOff=0
		shopt nocasematch >/dev/null || nocasematchWasOff=1
		(( nocasematchWasOff )) && shopt -s nocasematch

		local w matches=()
		OLD_IFS="$IFS"
		IFS=$'\t'‰

		for w in $words; do
			if [[ "$w" == "$token"* ]]; then
				matches+=("${w// /\ }")
			fi
		done

		IFS="$OLD_IFS"

		(( nocasematchWasOff )) && shopt -u nocasematch

		COMPREPLY=("${matches[@]}")
	fi

}

_doing_view() {
	OLD_IFS="$IFS"
	local token=${COMP_WORDS[$COMP_CWORD]}
	IFS=$'\t'
	local words=$(doing views)
	IFS="$OLD_IFS"

	if [[ "$token" == --* ]]; then
		COMPREPLY=( $( compgen -W '--section--count --csv --times --totals' -- $token ) )
	elif [[ "$token" == -* ]]; then
		COMPREPLY=( $( compgen -W '-s -c -t --section--count --csv --times --totals' -- $token ) )
	else
		local nocasematchWasOff=0
		shopt nocasematch >/dev/null || nocasematchWasOff=1
		(( nocasematchWasOff )) && shopt -s nocasematch

		OLD_IFS="$IFS"
		IFS=$'\t'
		local w matches=()
		for w in $words; do
			if [[ "$w" == "$token"* ]]; then matches+=("$w"); fi
		done
		IFS="$OLD_IFS"

		(( nocasematchWasOff )) && shopt -u nocasematch

		COMPREPLY=("${matches[@]}")
	fi

}

_doing()
{
	local last="${@: -1}"
	local token=${COMP_WORDS[$COMP_CWORD]}

	if [[ $last == "view" ]]; then
		_doing_view
	elif [[ $last =~ (show|archive|-s|--s|-t) ]]; then
		_doing_show
	else
		OLD_IFS="$IFS"
		IFS=$'\n'
		COMPREPLY=( $(compgen -W "$(doing help -c)" -- $token) )
		IFS="$OLD_IFS"
	fi
}

complete -F _doing doing
