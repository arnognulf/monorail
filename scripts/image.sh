#!/bin/bash
# Copyright (c) 2025 Thomas Eriksson
# SPDX-License-Identifier: BSD-3-Clause
_MAIN() {
	if [[ $ZSH_NAME ]]; then
		setopt KSH_ARRAYS
		setopt prompt_subst
	fi
	_MONORAIL_SHORT_HOSTNAME=$(hostname | cut -d. -f1 | awk '{print tolower($0)}')

	if which identify &>/dev/null && which convert &>/dev/null && which bc &>/dev/null && which fzf &>/dev/null; then
		:
	else
		"error: please install bc, fzf, imagemagick"
		exit 42
	fi

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

	case $(echo "${THEME}" | awk '{print tolower($0)}') in
	"")
		exit 1
		;;
	*)

		unset "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]"
		_PROMPT_LUT=()
		_PROMPT_TEXT_LUT=()

		TEMP=$(mktemp --suff=".${THEME##*.}")

		cp "${XDG_PICTURES_DIR-${HOME}/Pictures}/${THEME}" "${TEMP}" &>/dev/null
		# identify will report size
		WIDTH=$(identify "${TEMP}" | awk '{ print $3 }' | cut -dx -f1 | head -n1)
		HEIGHT=$(identify "${TEMP}" | awk '{ print $3 }' | cut -dx -f2 | head -n1)

		for RGB in $(convert -crop "$WIDTH"x1+0+$((HEIGHT / 2)) "${XDG_PICTURES_DIR-${HOME}/Pictures}/${THEME}" PPM:- | convert -scale 200x "PPM:-" RGB:- | xxd -ps -c3); do
			_PROMPT_LUT[$I]="$((0x${RGB:0:2}));$((0x${RGB:2:2}));$((0x${RGB:4:2}))"
			I=$((I + 1))
		done

		rm "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
		{
			I=0
			while [[ "$I" -lt "${#_PROMPT_LUT[*]}" ]]; do
				echo "_PROMPT_LUT[$I]=\"${_PROMPT_LUT[$I]}\""
				I=$((I + 1))
			done
			I=0
			while [[ "$I" -lt "${#_PROMPT_TEXT_LUT[*]}" ]]; do
				echo "_PROMPT_TEXT_LUT[$I]=\"${_PROMPT_TEXT_LUT[$I]}\""
				I=$((I + 1))
			done
			I=0
			while [[ "$I" -lt "${#_COLORS[*]}" ]]; do
				echo "_COLORS[$I]=\"${_COLORS[$I]}\""
				I=$((I + 1))
			done

			echo _DEFAULT_FGCOLOR=$_DEFAULT_FGCOLOR
			echo _DEFAULT_BGCOLOR=$_DEFAULT_BGCOLOR

		} >"${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
		killall -s WINCH bash zsh &>/dev/null
		;;
	"")
		# TODO HELP
		:
		;;
	esac

	{
		I=0
		while [[ "$I" -lt "${#_PROMPT_LUT[*]}" ]]; do
			echo "_PROMPT_LUT[$I]=\"${_PROMPT_LUT[$I]}\""
			I=$((I + 1))
		done
		I=0
		while [[ "$I" -lt "${#_PROMPT_TEXT_LUT[*]}" ]]; do
			echo "_PROMPT_TEXT_LUT[$I]=\"${_PROMPT_TEXT_LUT[$I]}\""
			I=$((I + 1))
		done
		I=0
		while [[ "$I" -lt "${#_COLORS[*]}" ]]; do
			echo "_COLORS[$I]=\"${_COLORS[$I]}\""
			I=$((I + 1))
		done

		echo _DEFAULT_FGCOLOR=$_DEFAULT_FGCOLOR
		echo _DEFAULT_BGCOLOR=$_DEFAULT_BGCOLOR

	} >"${DEST}" 2>/dev/null
	killall -s WINCH bash zsh &>/dev/null
}
_MAIN "$@"
