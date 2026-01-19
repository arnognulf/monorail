#!/bin/bash
# Copyright (c) 2025 Thomas Eriksson
# SPDX-License-Identifier: BSD-3-Clause
_MAIN() {
	if [[ $ZSH_NAME ]]; then
		setopt KSH_ARRAYS
		setopt prompt_subst
	fi
	case "$1" in
	-h | --help)
		echo "
Set monorail gradient to the center line of an image.
Without arguments an fzf menu of images will be displayed.

Usage:
    monorail_image <IMAGE>
 
Examples:
    monorail_image /usr/share/backrounds/wallpaper.jpg
"
		exit 1
		;;
	esac

	if which identify &>/dev/null && which convert &>/dev/null && which fzf &>/dev/null; then
		:
	else
		"error: please install fzf, imagemagick"
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
		if [ -n "$THEME" ]; then
			THEME="${XDG_PICTURES_DIR-${HOME}/Pictures}/${THEME}"
		else
			exit 1
		fi
	else
		THEME="$1"
	fi
	ERR=$(identify "$THEME" 2>&1)
	if [ $? -ne 0 ]; then
		echo "monorail_image: decoding failed: ${ERR}" 1>&2 | tee 1>/dev/null
		exit 1
	fi

	if [ -e "$THEME" ]; then
		:
	else
		echo "monorail_image: $THEME not found"
		exit 1
	fi
	unset "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]"
	_PROMPT_LUT=()
	_PROMPT_TEXT_LUT=()

	TEMP=$(mktemp --suff=".${THEME##*.}")

	cp "${THEME}" "${TEMP}" &>/dev/null
	# identify will report size
	WIDTH=$(identify "${TEMP}" | awk '{ print $3 }' | cut -dx -f1 | head -n1)
	HEIGHT=$(identify "${TEMP}" | awk '{ print $3 }' | cut -dx -f2 | head -n1)

	for RGB in $(convert -crop "$WIDTH"x1+0+$((HEIGHT / 2)) "${THEME}" PPM:- | convert -scale 200x "PPM:-" RGB:- | xxd -ps -c3); do
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
