#!/bin/bash
_BGCOLOR() {
	# reload in case user has manually modified colors.sh
	[[ -f ${_MONORAIL_CONFIG}/colors.sh ]] && . "$_MONORAIL_CONFIG"/colors.sh

	if [[ "${#1}" != 6 ]]; then
		\echo "ERROR: color must be hexadecimal and 6 hexadecimal characters" 1>&2 | tee 1>/dev/null
		return 1
	fi

	_MONORAIL_CONTRAST "${_PROMPT_FGCOLOR}" "$1" || return 1

	_PROMPT_BGCOLOR="$1"
	[[ ${#_PROMPT_TEXT_LUT[@]} = 0 ]] && _PROMPT_TEXT_LUT=()
	[[ ${#_PROMPT_LUT[@]} = 0 ]] && _PROMPT_LUT=()
	{
		declare -p _PROMPT_LUT | cut -d" " -f3-1024
		declare -p _PROMPT_TEXT_LUT | cut -d" " -f3-1024
		declare -p _PROMPT_FGCOLOR | cut -d" " -f3-1024
		declare -p _PROMPT_BGCOLOR | cut -d" " -f3-1024
	} >"${_MONORAIL_CONFIG}"/colors.sh
    killall -s WINCH bash zsh &>/dev/null
}

_BGCOLOR "$@"
