PROJECT_NAME := "GoToImp"
APP_NAME := "GoToImp"
CLI_NAME := "gotoimp"

alias _build-win := _build-windows
alias _build-mac := _build-macos
alias ver := version

set dotenv-load := false
set positional-arguments := true


@_default: _term-wipe
	just --list


# Build app
build $target='': _term-wipe
	#!/bin/sh
	if [ ${#target} -eq 0 ]; then
		target={{os()}}
	fi
	just _build-${target}

# Build GNU/Linux binary
_build-linux:
	@# go clean -cache
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o "bin/linux/{{CLI_NAME}}" *.go

# Build macOS binary
_build-macos:
	@# go clean -cache
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -a -o "bin/macos/{{CLI_NAME}}" *.go

# Build Windows Binary
_build-windows:
	@# go clean -cache
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o "bin/windows/{{CLI_NAME}}.exe" *.go


# Install app
install:
	go install gotoimp.go

# Run the app
run +args='': _term-wipe
	go run gotoimp.go {{args}}


# Wipes the terminal buffer for a clean start
_term-wipe:
	#!/bin/sh
	if [[ ${#VISUAL_STUDIO_CODE} -gt 0 ]]; then
		clear
	elif [[ ${KITTY_WINDOW_ID} -gt 0 ]] || [[ ${#TMUX} -gt 0 ]] || [[ "${TERM_PROGRAM}" = 'vscode' ]]; then
		printf '\033c'
	elif [[ "$(uname)" == 'Darwin' ]] || [[ "${TERM_PROGRAM}" = 'Apple_Terminal' ]] || [[ "${TERM_PROGRAM}" = 'iTerm.app' ]]; then
		osascript -e 'tell application "System Events" to keystroke "k" using command down'
	elif [[ -x "$(which tput)" ]]; then
		tput reset
	elif [[ -x "$(which reset)" ]]; then
		reset
	else
		clear
	fi

# Output the current version
@version:
	grep -F 'appVersion = ' app/app.go | cut -d'"' -f2


