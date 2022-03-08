# alias goto=gotoimp

# complete -W "$(gotoimp --completion bash)" gotoimp
# complete -W "$(gotoimp --completion bash)" goto

goto() {
	case $1 in
		-a | -add | --add) gotoimp "$@" ;;
		-at | -add-title | --add-title) gotoimp "$@" ;;
		-d | -del | --del | -delete | --delete) gotoimp "$@" ;;
		-e | -edit | --edit) gotoimp "$@" ;;
		-h | -help | --help) gotoimp "$@" ;;
		-l | -list | --list) gotoimp "$@" ;;
		-t | -title | --title) gotoimp "$@" ;;
		-u | -up | --up | -update | --update) gotoimp "$@" ;;
		-ut | -update-title | --update-title) gotoimp "$@" ;;
		-v | -ver | --ver | -version | --version) gotoimp "$@" ;;
		*)
			local parts=$(gotoimp "$@")
			local path
			local title
			read path title <<< ${parts}
			# echo "parts: ${parts}"
			# echo " path: ${path}"
			# echo "title: ${title}"
			# echo

			[[ ${#path} -gt 0 ]] && cd "${path}"
			[[ ${#title} -gt 0 ]] && _term_title "${title}"
			;;
	esac
}


_gotoimp_bash_completion()
{
	COMPREPLY=($(compgen -W "$(gotoimp --completion bash)" "${COMP_WORDS[1]}"))
}

# complete -F _gotoimp_bash_completion gotoimp
complete -F _gotoimp_bash_completion goto

_term_title() {
	local title="$@"
	if [[ "x${title}x" != 'xx' ]]; then
		# echo -ne "\033]0;${title}\007"
		if [[ "$(tput hs; echo $?)" -eq 0 ]]; then
			printf "$(tput tsl)${title}$(tput fsl)"
		else
			printf "\033]0;%s\007" "${title}"
		fi
	fi
}


	# OPTIONS:
	#    -a | --add <alias> <path>                    Add a alias path
	#   -at | --add-title <alias> <path> <title>      Add an alias path with title
	#    -d | --del | --delete <alias>                Delete a goto alias, including title if present
	#    -e | --edit                                  Display configuration paths for editing
	#    -h | --help                                  Display this help info
	#    -l | --list                                  List goto aliases
	#    -t | --title <alias> <title>                 Add an alias title
	#    -u | --up | --update                         Update a goto alias
	#   -ut | --update-title  <alias> <path> <title>  Update a goto alias path with title
	#    -v | --version                               Show the goto version