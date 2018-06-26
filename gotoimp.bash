#
# GoToImp
# BASH directory traversal enhancement
#
# @author RuneImp <runeimp@gmail.com>
#
#####
# ChangeLog
# ---------
# 2018-06-25  v0.5.1      Updated docs
# 2018-06-25  v0.5.0      Updated fresh install initialization and BASH completion
# 2018-06-18  v0.4.0      Added tmux support
# 2018-05-10  v0.3.0      Initial BASH Completion added
# 2018-05-??  v0.2.0      Added Update switch
# 2018-04-??  v0.1.0      Initial script creation
#


#
# CONSTANTS'ish
#
# declare -r and readonly is noisy...
#
declare _GOTO_APP_VERSION='0.5.1'


#
# VARIABLES
#
declare -a _gotoimp_alias_lines
declare -a _gotoimp_alias_names
declare -a _gotoimp_alias_paths
declare -a _gotoimp_list_titles
declare -i _gotoimp_alias_length=0
declare -i _gotoimp_name_width=0
declare -i _gotoimp_path_width=0
declare _gotoimp_alias_db=''
declare _gotoimp_data_path=''
declare _gotoimp_title_db=''



#
# FUNCTIONS
#


_gotoimp_bash_completion()
{
	local list="$(goto -l)"
	local words

	local -i line_count=$(echo "$list" | wc -l)
	
	# echo "\$list: $list"
	# echo "\$line_count: $line_count"

	if [[ $line_count -gt 1 ]]; then
		local words="$(echo "$list" | tail -n +3 | grep -E -v '^\s*$' | awk '{print $1}' | tr "\n" " ")"
		words="${words%%[[:space:]]}" # Remove trailing spaces
		words="${words##[[:space:]]}" # Remove leading spaces
		# echo complete -W "$words" goto
		complete -W "$words" goto
	else
		echo "$list"
	fi
}


_gotoimp_help()
{
	cat <<-EOH
	gotoimp v${_GOTO_APP_VERSION}

	Command for storing and utilizing aliases to directories

	OPTIONS:
	   -a | --add <alias> <path>                    Add a alias path
	  -at | --add-title <alias> <path> <title>      Add an alias path with title
	   -d | --del | --delete <alias>                Delete a goto alias
	   -h | --help                                  Display this help info
	   -l | --list                                  List goto aliases
	   -t | --title <alias> <title>                 Add an alias title
	   -u | --up | --update                         Update a goto alias
	  -ut | --update-title  <alias> <path> <title>  Update a goto alias path with title
	   -v | --version                               Show the goto version

EOH
}


_gotoimp_load_list()
{
	local -i found_space=1
	local -i i=0
	local -i j=0
	
	local line=""
	local goto_name=""
	local goto_path=""
	local goto_term=""

	IFS='
'
	_gotoimp_alias_lines=( $(cat "${_gotoimp_alias_db}") )
	_gotoimp_title_lines=( $(cat "${_gotoimp_title_db}") )
	
	IFS=' '
	_gotoimp_alias_length=${#_gotoimp_alias_lines[@]}
	_gotoimp_alias_names=( )
	_gotoimp_alias_paths=( )
	_gotoimp_name_width=0
	_gotoimp_title_length=${#_gotoimp_title_lines[@]}
	_gotoimp_title_names=( )
	_gotoimp_title_terms=( )
	i=0

	while [[ $i -lt $_gotoimp_alias_length ]]; do
		found_space=1
		j=0
		line=${_gotoimp_alias_lines[$i]}
		while [[ $j -lt ${#line} ]]; do
			# echo "line: ${line} ($j) | ${line:$j:1} ($j)"
			if [[ $found_space -eq 0 ]]; then
				goto_path="${goto_path}${line:$j:1}"
				if [[ ${#goto_path} -gt ${_gotoimp_path_width} ]]; then
					_gotoimp_path_width=${#goto_path}
				fi
			else
				if [[ ${line:$j:1} != ' ' ]]; then
					goto_name="${goto_name}${line:$j:1}"
					if [[ ${#goto_name} -gt ${_gotoimp_name_width} ]]; then
						_gotoimp_name_width=${#goto_name}
					fi
				else
					found_space=0
				fi
			fi
			let "j += 1"
		done
		# echo "goto_name: $goto_name | goto_path: $goto_path"
		_gotoimp_alias_names=( "${_gotoimp_alias_names[@]}" "$goto_name" )
		_gotoimp_alias_paths=( "${_gotoimp_alias_paths[@]}" "$goto_path" )
		goto_name=""
		goto_path=""

		# echo "${i}: ${_gotoimp_alias_lines[$i]} (${_gotoimp_name_width})"
		let "i += 1"
	done

	i=0
	while [[ $i -lt $_gotoimp_title_length ]]; do
		found_space=1
		j=0
		line=${_gotoimp_title_lines[$i]}
		while [[ $j -lt ${#line} ]]; do
			# echo "line: ${line} ($j) | ${line:$j:1} ($j)"
			if [[ $found_space -eq 0 ]]; then
				goto_term="${goto_term}${line:$j:1}"
			else
				if [[ ${line:$j:1} != ' ' ]]; then
					goto_name="${goto_name}${line:$j:1}"
				else
					found_space=0
				fi
			fi
			let "j += 1"
		done
		# echo "goto_name: $goto_name | goto_term: $goto_term"
		_gotoimp_title_names=( "${_gotoimp_title_names[@]}" "$goto_name" )
		_gotoimp_title_terms=( "${_gotoimp_title_terms[@]}" "$goto_term" )
		goto_name=""
		goto_term=""

		# echo "${i}: ${_gotoimp_title_lines[$i]} (${_gotoimp_name_width})"
		let "i += 1"
	done
}


goto()
{
	local -i i=0
	local -i j=0
	local -i not_found=0
	local goto_path=''
	local goto_name=''
	local goto_path=''
	local term_title=''

	until [[ $# -eq 0 ]]; do
		case "$1" in
			-a | --add)
				goto_name="$2"
				goto_path="$3"
				_gotoimp_load_list
				if [[ $_gotoimp_alias_length -eq 0 ]]; then
					echo "  Adding first gotoimp alias!"
					# touch "${_gotoimp_alias_db}"
				fi
				echo "  gotoimp '${goto_name}' alias added to ${_gotoimp_alias_db}"
				echo "${goto_name} ${goto_path}" >> "${_gotoimp_alias_db}"
				# touch ~/.gotoimp.tmp
				cat "${_gotoimp_alias_db}" | sort > ~/.gotoimp.tmp
				mv ~/.gotoimp.tmp "${_gotoimp_alias_db}"

				_gotoimp_bash_completion

				shift
				shift
				;;
			-at | --add-title)
				goto_name="$2"
				goto_path="$3"
				goto_term="$4"

				goto --add "$goto_name" "$goto_path"
				goto --title "$goto_name" "$goto_term"

				# if [[ ! -f "${_gotoimp_title_db}" ]]; then
				# 	echo "  Adding first gotoimp alias title!"
				# 	touch "${_gotoimp_title_db}"
				# fi
				# echo "  gotoimp '${goto_term}' alias title added to ${_gotoimp_title_db}"
				# echo "${goto_name} ${goto_term}" >> "${_gotoimp_title_db}"
				# cat "${_gotoimp_title_db}" | sort > ~/.gotoimp.tmp
				# mv ~/.gotoimp.tmp "${_gotoimp_title_db}"

				shift
				shift
				shift
				;;
			-d | --del | --delete | -r | --remove)
				goto_name="$2"
				
				if [[ -f "${_gotoimp_title_db}" ]]; then
					echo "  gotoimp '${goto_name}' alias removed"
					cat "${_gotoimp_alias_db}" | grep -Ev "^$goto_name.*" > ~/.gotoimp.tmp
					mv ~/.gotoimp.tmp "${_gotoimp_alias_db}"
				else
					echo "  No gotoimp alias shorcuts defined yet"
				fi
				if [[ -f "${_gotoimp_title_db}" ]]; then
					cat "${_gotoimp_title_db}" | grep -Ev "^$goto_name.*" > ~/.gotoimp.tmp
					mv ~/.gotoimp.tmp "${_gotoimp_title_db}"
				else
					echo "  No gotoimp alias titles defined yet"
				fi
				shift
				;;
			-h | --help)
				_gotoimp_help
				;;
			-l | --list)
				# echo "\$_gotoimp_alias_length: $_gotoimp_alias_length"
				_gotoimp_load_list
				if [[ $_gotoimp_alias_length -eq 0 ]]; then
					echo "  No gotoimp aliases yet"
				else
					echo "  gotoimp aliases:"
					printf "%-${_gotoimp_name_width}s %-${_gotoimp_path_width}s %s\n" Alias Path Title
					i=0
					while [[ $i -lt $_gotoimp_alias_length ]]; do
						term_title=""
						j=0
						while [[ $j -lt $_gotoimp_title_length ]]; do
							if [[ "${_gotoimp_title_names[$j]}" == "${_gotoimp_alias_names[$i]}" ]]; then
								term_title="'${_gotoimp_title_terms[$j]}'"
							fi
							let "j += 1"
						done
						printf "%-${_gotoimp_name_width}s %-${_gotoimp_path_width}s %s\n" "${_gotoimp_alias_names[$i]}" "${_gotoimp_alias_paths[$i]}" "$term_title"
						let "i += 1"
					done
					echo
				fi
				;;
			-t | --title)
				goto_name="$2"
				goto_term="$3"

				if [[ ! -f "${_gotoimp_title_db}" ]]; then
					echo "  Adding first gotoimp alias title!"
					touch "${_gotoimp_title_db}"
				fi
				echo "  gotoimp '${goto_term}' alias title added to ${_gotoimp_title_db}"
				echo "${goto_name} ${goto_term}" >> "${_gotoimp_title_db}"
				cat "${_gotoimp_title_db}" | sort > ~/.gotoimp.tmp
				mv ~/.gotoimp.tmp "${_gotoimp_title_db}"

				shift
				shift
				;;
			-v | --version)
				echo "gotoimp v${_GOTO_APP_VERSION}"
				;;
			-u | --update)
				goto_name="$2"
				goto_path="$3"
				tmp=$(goto -d "${goto_name}" 2>&1 /dev/null)
				tmp=$(goto -a "${goto_name}" "${goto_path}" 2>&1 /dev/null)
				echo "  gotoimp '${goto_name}' alias updated in ${_gotoimp_alias_db}"
				shift
				shift
				;;
			-ut | --update-title)
				goto_name="$2"
				goto_path="$3"
				goto_term="$4"
				tmp=$(goto -d "${goto_name}" 2>&1 /dev/null)
				tmp=$(goto -at "${goto_name}" "${goto_path}" "${goto_term}" 2>&1 /dev/null)
				echo "  gotoimp '${goto_name}' alias updated in ${_gotoimp_alias_db} and ${_gotoimp_title_db}"
				shift
				shift
				shift
				;;
			*)
				goto_name="$1"
				_gotoimp_load_list
				i=0
				while [[ $i -lt $_gotoimp_alias_length ]]; do
					if [[ "${_gotoimp_alias_names[$i]}" == "$goto_name" ]]; then
						# echo "Going to: '${goto_name}'"
						goto_path="${_gotoimp_alias_paths[$i]}"
						# echo "\$goto_path: $goto_path"
						goto_path="${goto_path/#\~/$HOME}"
						# echo "\$goto_path: $goto_path"
						cd "$goto_path"
						not_found=1
						break
					fi
					let "i += 1"
				done

				if [[ $not_found -eq 1 ]]; then
					if [[ "$(uname -s)" == 'Darwin' ]] && [[ ${#TMUX} -eq 0 ]]; then
						osascript -e 'tell application "System Events" to keystroke "k" using command down'
					elif [[ -f $(which 'tput') ]]; then
						tput reset
					elif [[ -f $(which 'reset') ]]; then
						reset
					else
						clear
					fi
					i=0
					# echo "\$goto_name: $goto_name"
					while [[ $i -lt $_gotoimp_title_length ]]; do
						if [[ "${_gotoimp_title_names[$i]}" == "$goto_name" ]]; then
							# echo "Going to: '${goto_name}'"
							goto_term="${_gotoimp_title_terms[$i]}"
							# echo "\$goto_term: $goto_term ($i)"
							printf "\033]0;${goto_term}\007"
							break
						fi
						let "i += 1"
					done
				fi
				
				if [[ $not_found -eq 0 ]]; then
					echo "gotoimp '$goto_name' alias not found"
				fi
				;;
		esac

		shift
	done
}


#
# INIT
#

# Check for existing Shorcut Alias DB
if [[ -f "${XDG_DATA_HOME}/gotoimp/alias_db.txt" ]]; then
	_gotoimp_data_path="${XDG_DATA_HOME}/gotoimp"
elif [[ -f ~/.local/share/gotoimp/alias_db.txt ]]; then
	_gotoimp_data_path=~/.local/share/gotoimp
elif [[ -f ~/.local/gotoimp/alias_db.txt ]]; then
	_gotoimp_data_path=~/.local/gotoimp
elif [[ -d ~/.gotoimp ]]; then
	_gotoimp_data_path=~/.gotoimp
elif [[ -f ~/.goto ]]; then
	_gotoimp_alias_db=~/.goto
fi

# Define Data Path if Shorcut Alias DB not found
if [[ ${#_gotoimp_data_path} -eq 0 ]]; then
	if [[ -d "${XDG_DATA_HOME}" ]]; then
		_gotoimp_data_path="${XDG_DATA_HOME}/gotoimp"
	elif [[ -d ~/.local ]]; then
		if [[ -d ~/.local/share ]]; then
			_gotoimp_data_path=~/.local/share/gotoimp
		else
			_gotoimp_data_path=~/.local/gotoimp
		fi
	else
		_gotoimp_data_path=~/.gotoimp
	fi
	if [[ ! -d "${_gotoimp_data_path}" ]]; then
		mkdir -p "${_gotoimp_data_path}"
	fi
fi

# Define path to Shorcut Alias DB
if [[ ${#_gotoimp_alias_db} -eq 0 ]]; then
	_gotoimp_alias_db="${_gotoimp_data_path}/alias_db.txt"
	if [[ ! -f "${_gotoimp_alias_db}" ]]; then
		touch "${_gotoimp_alias_db}"
	fi
fi

# Define path to Terminal Title DB
if [[ ${#_gotoimp_title_db} -eq 0 ]]; then
	_gotoimp_title_db="${_gotoimp_data_path}/title_db.txt"
	if [[ ! -f "${_gotoimp_title_db}" ]]; then
		touch "${_gotoimp_title_db}"
	fi
fi

_gotoimp_bash_completion

