#!/bin/bash
# Copyright (c) 2025 Thomas Eriksson
# SPDX-License-Identifier: BSD-3-Clause
_MAIN() {
	_MONORAIL_SHORT_HOSTNAME=${HOSTNAME%%.*}
	_MONORAIL_SHORT_HOSTNAME=${_MONORAIL_SHORT_HOSTNAME,,}

		unset "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]"
        _PROMPT_LUT=()
        _PROMPT_TEXT_LUT=()
        _COLORS=()
		. "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
        [[ ${_DEFAULT_FGCOLOR} ]] || _DEFAULT_FGCOLOR=444444
        [[ ${_DEFAULT_BGCOLOR} ]] || _DEFAULT_BGCOLOR=ffffff
        [[ ${_COLORS[16]} ]] || _COLORS[16]=$_DEFAULT_FGCOLOR
        [[ ${_COLORS[17]} ]] || _COLORS[17]=$_DEFAULT_BGCOLOR

	if [[ -z "$DEST" ]]; then
		DEST="${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
	fi

	if [[ -z "$1" ]]; then
		THEME=$(cd "${XDG_PICTURES_DIR-${HOME}/Pictures}" && fzf --preview "${_MONORAIL_DIR}/scripts/preview.sh \"${_COLORS[16]}\" \"${_COLORS[17]}\" {}")
	else
		THEME="$1"
	fi
	case "${THEME,,}" in
	"")
		exit 1
		;;
	*)

		unset "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]"
        _PROMPT_LUT=()
        _PROMPT_TEXT_LUT=()
        _COLORS=()

		TEMP=$(mktemp --suff=".${THEME##*.}")

		cp "${XDG_PICTURES_DIR-${HOME}/Pictures}/${THEME}" "${TEMP}" &>/dev/null
		# identify will report size
		WIDTH=$(identify "${TEMP}" | awk '{ print $3 }' | cut -dx -f1 | head -n1)

		for RGB in $(convert -crop "$WIDTH"x1+0+$((WIDTH / 2)) "${XDG_PICTURES_DIR-${HOME}/Pictures}/${THEME}" PPM:- | convert -scale 200x "PPM:-" RGB:- | xxd -ps -c3); do
			_PROMPT_LUT[$I]="$((0x${RGB:0:2}));$((0x${RGB:2:2}));$((0x${RGB:4:2}))"
			I=$((I + 1))
		done

		rm "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
		{
			declare -p _PROMPT_LUT
			declare -p _PROMPT_TEXT_LUT
			declare -p _COLORS
			declare -p _DEFAULT_FGCOLOR
			declare -p _DEFAULT_BGCOLOR

		} >"${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
		;;
	"")
		# TODO HELP
		:
		;;
	esac

	{
	declare -p _PROMPT_LUT | cut -d" " -f3-1024
	declare -p _PROMPT_TEXT_LUT | cut -d" " -f3-1024 | grep -v '()'
	declare -p _COLORS | cut -d" " -f3-1024
	declare -p _DEFAULT_FGCOLOR | cut -d" " -f3-1024
	declare -p _DEFAULT_BGCOLOR | cut -d" " -f3-1024
	} >"${DEST}" 2>/dev/null
	killall -s WINCH bash zsh &>/dev/null
}
_MAIN "$@"
