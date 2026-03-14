#!/bin/sh
# Copyright (c) 2025 Thomas Eriksson
# SPDX-License-Identifier: BSD-3-Clause
TEMPDIR=$(mktemp -d)
cp "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh" "${TEMPDIR}"/current.sh
touch "${TEMPDIR}"/current.sh
# shellcheck disable=SC1091 # path exists
. "${_MONORAIL_DIR}"/scripts/callbacks.inc.sh
. "${_MONORAIL_DIR}"/scripts/sandbox.inc.sh

_MAIN() {
	if [ "$ZSH_NAME" ]; then
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

	if command -v identify >/dev/null 2>/dev/null && command -v convert >/dev/null 2>/dev/null; then
		:
	else
		echo "error: please install imagemagick"
		exit 42
	fi

	if [ -z "$DEST" ]; then
		DEST="${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
	fi

	if [ -z "$1" ]; then
		if [ "$BASH_VERSION" ] || [ "$ZSH_NAME" ] || [ "$KSH_VERSION" ]; then
			:
		else
			echo "error: preview requires bash, zsh, or ksh"
			exit 42
		fi

		if command -v fzf >/dev/null 2>/dev/null; then
			:
		else
			echo "error: please install fzf"
			exit 42
		fi
		PREVIEW_SHELL=$(command -v ksh)
		if [ ! -x "$PREVIEW_SHELL" ]; then
			PREVIEW_SHELL="$0"
		fi

		if [ -z "$_MONORAIL_IMAGE_DIR" ]; then
			_MONORAIL_IMAGE_DIR=$XDG_PICTURES_DIR
		fi
		THEME=$(cd "${_MONORAIL_IMAGE_DIR}" && fzf --preview "$PREVIEW_SHELL ${_MONORAIL_DIR}/scripts/preview.sh {}")

		if [ -n "$THEME" ]; then
			THEME="${_MONORAIL_IMAGE_DIR}/$THEME"
		else
			exit 1
		fi
	else
		THEME="$1"
	fi
	if ! cat "$THEME" | _SANDBOX identify - >/dev/null 2>/dev/null; then
		echo "monorail_image: decoding failed"
		exit 1
	fi

	if [ -e "$THEME" ]; then
		:
	else
		echo "monorail_image: $THEME not found"
		exit 1
	fi

rm "${DEST}"
	# identify will report size
	WIDTH=$(cat "${THEME}" | _SANDBOX identify - | awk '{ print $3 }' | cut -dx -f1 | head -n1)
	HEIGHT=$(cat "${THEME}" | _SANDBOX identify - | awk '{ print $3 }' | cut -dx -f2 | head -n1)

	ADD_WHITE_PROMPT_TEXT_LUT
{
	printf "_PROMPT_LUT"

	for RGB in $(_SANDBOX convert -crop "$WIDTH"x1+0+$((HEIGHT / 2)) -scale 200x "${THEME}" RGB:- | xxd -ps -c3); do
		echo " \\"
		printf "\"%s;%s;%s\"" $((0x$(echo "$RGB" | cut -c1-2))) $((0x$(echo "$RGB" | cut -c3-4))) $((0x$(echo "$RGB" | cut -c5-6)))
		I=$((I + 1))
	done
echo ""
echo ""
} >>"${DEST}"

	ADD_CURRENT_COLORS
	killall -s WINCH bash zsh >/dev/null 2>/dev/null
}
_MAIN "$@"
