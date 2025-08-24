#!/bin/bash
# Copyright (c) 2025 Thomas Eriksson
# SPDX-License-Identifier: BSD-3-Clause
_MAIN() {
	declare -a _PROMPT_LUT=()
	declare -a _PROMPT_TEXT_LUT=()
	if [[ -z "$DEST" ]]; then
		DEST="${_MONORAIL_CONFIG}/colors.sh"
	fi
	OVERRIDE_FGCOLOR=444444
	OVERRIDE_BGCOLOR=ffffff

	while [[ "$1" = "-"* ]]; do
		case "$1" in
		--light)
			local OVERRIDE_BGCOLOR=ffffff
			local OVERRIDE_FGCOLOR=444444
			printf "\033]10;#${OVERRIDE_FGCOLOR}\007"
			printf "\033]11;#${OVERRIDE_BGCOLOR}\007"
			printf "\033]12;#${OVERRIDE_FGCOLOR}\007"
			shift
			;;
		--dark)
			local OVERRIDE_BGCOLOR=444444
			local OVERRIDE_FGCOLOR=ffffff
			printf "\033]10;#${OVERRIDE_FGCOLOR}\007"
			printf "\033]11;#${OVERRIDE_BGCOLOR}\007"
			printf "\033]12;#${OVERRIDE_FGCOLOR}\007"
			shift
			;;
		esac
	done

	if [[ -z "$1" ]]; then
		THEME=$(cd "${XDG_PICTURES_DIR-${HOME}/Pictures}" && fzf --preview "${_MONORAIL_DIR}/scripts/preview.sh \"${OVERRIDE_FGCOLOR}\" \"${OVERRIDE_BGCOLOR}\" {}")
	else
		THEME="$1"
	fi
	case "${THEME,,}" in
    "")
        exit 1;;
	*)

		_PROMPT_FGCOLOR=$OVERRIDE_FGCOLOR
		_PROMPT_BGCOLOR=$OVERRIDE_BGCOLOR
		unset "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]"

		TEMP=$(mktemp --suff=".${THEME##*.}")

		cp "${XDG_PICTURES_DIR-${HOME}/Pictures}/${THEME}" "${TEMP}" &>/dev/null
		# identify will report size
		WIDTH=$(identify "${TEMP}" | awk '{ print $3 }' | cut -dx -f1 | head -n1)

		for RGB in $(convert -crop "$WIDTH"x1+0+$((WIDTH / 2)) "${XDG_PICTURES_DIR-${HOME}/Pictures}/${THEME}" PPM:- | convert -scale 200x "PPM:-" RGB:- | xxd -ps -c3); do
			_PROMPT_LUT[$I]="$((0x${RGB:0:2}));$((0x${RGB:2:2}));$((0x${RGB:4:2}))"
			I=$((I + 1))
		done

		rm "${_MONORAIL_CONFIG}/colors.sh"
		{
			[[ $OVERRIDE_FGCOLOR ]] && printf "\n_PROMPT_FGCOLOR=${OVERRIDE_FGCOLOR}\n"
			[[ $OVERRIDE_BGCOLOR ]] && printf "\n_PROMPT_BGCOLOR=${OVERRIDE_BGCOLOR}\n"
			[[ ${_PROMPT_LUT[0]} ]] && declare -p _PROMPT_LUT
			[[ ${_PROMPT_TEXT_LUT[0]} ]] && declare -p _PROMPT_TEXT_LUT

		} >"${_MONORAIL_CONFIG}/colors.sh"
		;;
	"")
		# TODO HELP
		:
		;;
	esac

	{
		[[ ${_PROMPT_LUT} ]] && declare -p _PROMPT_LUT | cut -d" " -f3-1024
		[[ ${_PROMPT_TEXT_LUT} ]] && declare -p _PROMPT_TEXT_LUT | cut -d" " -f3-1024 | grep -v '()'
		if [[ ! $RESET_COLORS ]]; then
			[[ ${_PROMPT_FGCOLOR} ]] && declare -p _PROMPT_FGCOLOR | cut -d" " -f3-1024
			[[ ${_PROMPT_BGCOLOR} ]] && declare -p _PROMPT_BGCOLOR | cut -d" " -f3-1024
		fi
	} >"${DEST}" 2>/dev/null
	killall -s WINCH bash zsh &>/dev/null
}
_MAIN "$@"
