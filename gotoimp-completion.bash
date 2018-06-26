

_GoToImpCompletions()
{
	local cur

	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}

	case "$cur" in
		[a-zA-Z]*)
			words="$(goto -l | tail +3 | grep -E -v '^\s*$' | awk '{print $1}' | tr "\n" " ")"
			# words=""
			# for word in $(goto -l | tail +3 | grep -E -v '^\s*$' | awk '{print $1}' | tr -d "\n"); do
			# for word in $(goto -l | tail +3 | grep -E -v '^\s*$' | awk '{print $1}' | tr "\n" " "); do
			# 	words="$words $word"
			# done
			words="${words%%[[:space:]]}" # Remove trailing spaces
			words="${words##[[:space:]]}" # Remove leading spaces
			printf "\n\$words: ${words}\n"
			COMPREPLY=( $(compgen -W "$words" -- $cur ) )
			;;
		*)
			echo "Unknown option '$cur'" 1>&2
			;;
	esac

	return 0
}


# complete -F _GoToImpCompletions -o filenames goto

words="$(goto -l | tail +3 | grep -E -v '^\s*$' | awk '{print $1}' | tr "\n" " ")"
words="${words%%[[:space:]]}" # Remove trailing spaces
words="${words##[[:space:]]}" # Remove leading spaces
# echo complete -W "$words" goto
complete -W "$words" goto
