#
# GoToImp
# BASH directory traversal tool
#
# @author RuneImp <runeimp@gmail.com>
# @see https://github.com/runeimp/gotoimp
#


#
# CONSTANTS
#
declare -r _GOTO_APP_NAME='GoToImp'
declare -r _GOTO_APP_VERSION='0.7.0'


#
# VARIABLES
#
declare -a _gotoimp_alias_lines
declare -a _gotoimp_alias_names
declare -a _gotoimp_alias_paths
declare -a _gotoimp_list_titles
declare -i _gotoimp_alias_length=0
declare -i _alias_name_width=0
declare -i _alias_path_width=0
declare -i _alias_title_width=0
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
	   -d | --del | --delete <alias>                Delete a goto alias, including title if present
	   -e | --edit                                  Display configuration paths for editing
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
	
	local goto_name=""
	local goto_path=""
	local goto_term=""
	local line=""


	IFS='
'
	echo "_gotoimp_load_list() | _gotoimp_alias_db: '${_gotoimp_alias_db}'"
	echo "_gotoimp_load_list() | _gotoimp_title_db: '${_gotoimp_title_db}'"
	_gotoimp_alias_lines=( $(cat "${_gotoimp_alias_db}") )
	_gotoimp_title_lines=( $(cat "${_gotoimp_title_db}") )
	
	IFS=' '
	_gotoimp_alias_length=${#_gotoimp_alias_lines[@]}
	_gotoimp_alias_names=( )
	_gotoimp_alias_paths=( )
	_alias_name_width=0
	_gotoimp_title_length=${#_gotoimp_title_lines[@]}
	_gotoimp_title_names=( )
	_gotoimp_title_terms=( )
	_alias_title_width=0
	i=0

	# Loop through all the aliases
	while [[ $i -lt $_gotoimp_alias_length ]]; do
		found_space=1 # Initialy 1 == false
		j=0
		line=${_gotoimp_alias_lines[$i]}

		# Process each line
		while [[ $j -lt ${#line} ]]; do
			# echo "line: ${line} ($j) | ${line:$j:1} ($j)"

			if [[ $found_space -eq 0 ]]; then
				# Find width of the path
				goto_path="${goto_path}${line:$j:1}"
				# Update the path display width if the new path is longer
				if [[ ${#goto_path} -gt ${_alias_path_width} ]]; then
					_alias_path_width=${#goto_path}
				fi
			else
				# Find width of the alias which terminates with a space
				if [[ ${line:$j:1} != ' ' ]]; then
					goto_name="${goto_name}${line:$j:1}"
					if [[ ${#goto_name} -gt ${_alias_name_width} ]]; then
						_alias_name_width=${#goto_name}
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

		# echo "${i}: ${_gotoimp_alias_lines[$i]} (${_alias_name_width})"
		let "i += 1"
	done

	i=0
	# Loop through all of the titles
	while [[ $i -lt $_gotoimp_title_length ]]; do
		found_space=1
		j=0
		line=${_gotoimp_title_lines[$i]}
		while [[ $j -lt ${#line} ]]; do
			# echo "line: ${line} ($j) | ${line:$j:1} ($j)"
			if [[ $found_space -eq 0 ]]; then
				goto_term="${goto_term}${line:$j:1}"
				if [[ ${#goto_term} -gt ${_alias_title_width} ]]; then
					_alias_title_width=${#goto_term}
				fi
			else
				# Find the space at the end of the alias and save the title name
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

		# echo "${i}: ${_gotoimp_title_lines[$i]} (${_alias_name_width})"
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

				_gotoimp_bash_completion

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
			-e | --edit)
				echo "$_GOTO_APP_NAME Data Path = '$_gotoimp_data_path'"
				echo "$_GOTO_APP_NAME Alias DB = '$_gotoimp_alias_db'"
				echo "$_GOTO_APP_NAME Title DB = '$_gotoimp_title_db'"
				;;
			-h | --help)
				_gotoimp_help
				;;
			-l | --list)
				# echo "\$_gotoimp_alias_length: ${_gotoimp_alias_length}"
				_gotoimp_load_list
				echo "\$_gotoimp_alias_length: ${_gotoimp_alias_length}"
				if [[ $_gotoimp_alias_length -eq 0 ]]; then
					echo "  No gotoimp aliases yet"
				else
					local -i term_width="$COLUMNS"
					if [[ $term_width -eq 0 ]]; then
						if [[ $(which stty 1>/dev/null; echo $?) -eq 0 ]]; then
							term_width=$(stty size | cut -d' ' -f2)
						elif [[ $(which tcap 1>/dev/null; echo $?) -eq 0 ]]; then
							term_width=$(tcap co)
						elif [[ $(which tput 1>/dev/null; echo $?) -eq 0 ]]; then
							term_width=$(tput cols)
						fi
					fi

					let "alias_title_max = $_alias_title_width + 2" # Include single quotes for display
					let "total_width = $_alias_name_width + $_alias_path_width + $alias_title_max + 2" # + 2 for column spaces
					# echo " _alias_name_width: $_alias_name_width"
					# echo " _alias_path_width: $_alias_path_width"
					# echo "_alias_title_width: $_alias_title_width"
					# echo "   alias_title_max: $alias_title_max"
					# echo "        term_width: $term_width"
					# echo "       total_width: $total_width"
					if [[ $term_width -lt $total_width ]]; then
						let "_alias_path_width = $term_width - $_alias_name_width - $alias_title_max - 2" # - 2 for column spaces
					fi
					# echo " _alias_name_width: $_alias_name_width"
					# echo " _alias_path_width: $_alias_path_width"
					# echo "_alias_title_width: $_alias_title_width"

					echo "  gotoimp aliases:"
					printf "%-${_alias_name_width}s %-${_alias_path_width}s %s\n" Alias Path Title
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
						alias_path=${_gotoimp_alias_paths[$i]}
						if [[ ${#alias_path} -gt $_alias_path_width ]]; then
							let "alias_path_max = $_alias_path_width - 3"
							alias_path="${alias_path:0:$alias_path_max}..."
						fi
						printf "%-${_alias_name_width}s %-${_alias_path_width}s %-${alias_title_max}s\n" "${_gotoimp_alias_names[$i]}" "${alias_path}" "$term_title"
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

				_gotoimp_bash_completion

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

				_gotoimp_bash_completion

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

						# Strip control and non UTF-8 characters
						goto_path="$(printf '%s' "$goto_path" | LC_ALL=POSIX tr -d '[:cntrl:]' | iconv -cs -f UTF-8 -t UTF-8)"
						# echo "\$goto_path: $goto_path (stripped)"

						if [[ "$GOTO_DYNAMIC" != "safe" ]]; then
							goto_path="$(eval "echo ${goto_path}")"
							# echo "\$goto_path: $goto_path (eval)"
							eval "cd ${goto_path}"
						else
							echo "           \${goto_path}: ${goto_path}"
							echo "         \${goto_path:1}: ${goto_path:1}"
							echo "    grep \${goto_path:1}: $(env | grep -F ${goto_path:1} --line-buffered | cut -d= -f2)"
							echo "printenv \${goto_path:1}: $(printenv ${goto_path:1})"

							case "${goto_path:0:1}" in
								'-')
									# Hyphen Prefixed Path?
									goto_path="./${goto_path}"
									if [[ ! -d "${goto_path}" ]]; then
										echo "ERROR: invalid path '${goto_path}'"
										exit 1
									fi
									;;
								'~')
									# Tilde Expansion
									goto_path="${goto_path/#\~/$HOME}"
									exit_code=$?
									echo "Tilde Expansion: ${goto_path} | exit_code: $exit_code"
									;;
								'$')
									# Variable Expansion
									env_var_re='^\$([a-zA-Z][a-zA-Z0-9_]*|{[a-zA-Z][a-zA-Z0-9#:_-]*})$'
									if [[ "${goto_path}" =~ ${env_var_re} ]]; then
										set -f -o pipefail

										path_temp=$(printenv ${goto_path:1})
										exit_code=$?
										# echo "  ENV Expansion: ${goto_path} | exit_code: $exit_code"
										if [[ $exit_code -gt 0 ]]; then
											goto_path=$(env | grep -F ${goto_path:1} --line-buffered | cut -d= -f2)
											exit_code=$?
											# echo "  ENV Expansion: ${goto_path} | exit_code: $exit_code"
											if [[ $exit_code -gt 0 ]]; then
												echo "ERROR: invalid variable name '${goto_path}'"
												exit 1
											fi
										else
											goto_path="$path_temp"
										fi
									else
										echo "ERROR: unsafe variable reference '${goto_path}'"
										exit 1
									fi
									;;
								*)
									# Standard Path?
									if [[ ! -d "${goto_path}" ]]; then
										echo "ERROR: invalid path '${goto_path}'"
										exit 1
									fi
									;;
							esac

							cd "${goto_path}"
						fi

						not_found=1
						break
					fi
					let "i += 1"
				done

				if [[ $not_found -eq 1 ]]; then
					# term_wipe
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

term_wipe()
{
	if [[ ${#VISUAL_STUDIO_CODE} -gt 0 ]]; then
		clear
	elif [[ $KITTY_WINDOW_ID -gt 0 ]] || [[ ${#TMUX} -gt 0 ]] || [[ "$TERM_PROGRAM" = 'vscode' ]]; then
		printf '\033c'
	elif [[ "$(uname)" == 'Darwin' ]] || [[ "$TERM_PROGRAM" = 'Apple_Terminal' ]] || [[ "$TERM_PROGRAM" = 'iTerm.app' ]]; then
		osascript -e 'tell application "System Events" to keystroke "k" using command down'
	elif [[ -x "$(which tcap)" ]]; then
		tcap cl
	elif [[ -x "$(which tput)" ]]; then
		tput clear
	elif [[ -x "$(which reset)" ]]; then
		reset
	else
		clear
	fi
}


#
# INIT
#

# Check for existing Shorcut Alias DB
if [[ -d "${XDG_CONFIG_HOME}/gotoimp" ]]; then
	_gotoimp_data_path="${XDG_CONFIG_HOME}/gotoimp"
elif [[ -d ~/.config/gotoimp ]]; then
	_gotoimp_data_path=~/.config/gotoimp
elif [[ -d "${XDG_DATA_HOME}/gotoimp" ]]; then
	_gotoimp_data_path="${XDG_DATA_HOME}/gotoimp"
elif [[ -d ~/.local/share/gotoimp ]]; then
	_gotoimp_data_path=~/.local/share/gotoimp
elif [[ -f ~/.local/gotoimp ]]; then
	_gotoimp_data_path=~/.local/gotoimp
elif [[ -d ~/.gotoimp ]]; then
	_gotoimp_data_path=~/.gotoimp
fi

# Define Path to Alias DB
if [[ ${#_gotoimp_data_path} -gt 0 ]]; then
	_gotoimp_alias_db="${_gotoimp_data_path}/alias_db.txt"
	if [[ -f "${_gotoimp_data_path}/alias_db.txt" ]]; then
		# All good in the hood
		:
	elif [[ -f ~/.goto ]]; then
		# NOTE: This is a bit magical. Should probably get user input.
		_gotoimp_alias_db=~/.goto
		echo "${_GOTO_APP_NAME} copying '"~/.goto"' to '${_gotoimp_data_path}/alias_db.txt'"
		cp ~/.goto "${_gotoimp_data_path}/alias_db.txt"
	else
		echo "${_GOTO_APP_NAME} creating missing '${_gotoimp_data_path}/alias_db.txt'"
		touch "${_gotoimp_data_path}/alias_db.txt"
	fi
elif [[ -f ~/.goto ]]; then
	_gotoimp_alias_db=~/.goto
fi

# Define Data Path if data path not found
if [[ ${#_gotoimp_data_path} -eq 0 ]]; then
	if [[ -d "${XDG_CONFIG_HOME}" ]]; then
		_gotoimp_data_path="${XDG_CONFIG_HOME}/gotoimp"
	elif [[ -d ~/.config/gotoimp ]]; then
		_gotoimp_data_path=~/.config/gotoimp
	elif [[ -d "${XDG_DATA_HOME}" ]]; then
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
		echo "MKDIR _gotoimp_data_path: ${_gotoimp_data_path}"
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
echo "_gotoimp_data_path = '$_gotoimp_data_path'"
echo "_gotoimp_alias_db = '$_gotoimp_alias_db'"
echo "_gotoimp_title_db = '$_gotoimp_title_db'"

_gotoimp_bash_completion

