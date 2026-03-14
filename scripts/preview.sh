#!/bin/bash
#
# Copyright (c) Thomas Eriksson <thomas.eriksson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
. "${_MONORAIL_DIR}"/scripts/sandbox.inc.sh

if [[ $ZSH_NAME ]]; then
	setopt KSH_ARRAYS
	setopt prompt_subst
fi

if [[ "$1" = "000_README.md" ]]; then
	cat "$1"
	exit 1
fi

_PROMPT_LUT() {
	I=0
	_PROMPT_LUT=()
	while [[ $1 ]]; do
		_PROMPT_LUT[I]=$1
		shift
		I=$((I + 1))
	done
	unset I
}
_PROMPT_TEXT_LUT() {
	_PROMPT_TEXT_LUT=()
	I=0
	while [[ $1 ]]; do
		_PROMPT_TEXT_LUT[I]=$1
		shift
		I=$((I + 1))
	done
	unset I
}
_COLORS() {
	_COLORS=()
	I=0
	while [[ "$1" ]]; do
		_COLORS[I]=$1
		shift
		I=$((I + 1))
	done
	unset I
}

PREVIEW=$1

if [[ $XDG_CONFIG_HOME ]]; then
	_MONORAIL_CONFIG="$XDG_CONFIG_HOME/monorail"
else
	_MONORAIL_CONFIG="$HOME/.config/monorail"
fi
# shellcheck disable=SC1090 # file exists
. "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
case $(echo "$PREVIEW" | awk '{print tolower($0)}') in
*.sh)
	case "${PWD}" in
	${_MONORAIL_DIR}/gradients)
:
		;;
	${_MONORAIL_DIR}/colors)
:
		;;
	*)
		echo "Not a theme: ${PREVIEW}"
		exit 42
		;;
	esac
	# shellcheck disable=SC1090 # file exists
	. "./$PREVIEW"
	;;
*)

	THEME="${PREVIEW}"
	_SANDBOX identify "${THEME}" >/dev/null 2>/dev/null || {
		echo "Not a theme: ${THEME}"
		exit 1
	}

	TEMP=$(mktemp --suff=".${THEME##*.}")
	cp -f "${XDG_PICTURES_DIR-${HOME}/Pictures}/${THEME}" "$TEMP"
	WIDTH=$(_SANDBOX identify "$TEMP" 2>/dev/null | awk '{ print $3 }' | cut -dx -f1 | head -n1)
	HEIGHT=$(_SANDBOX identify "$TEMP" 2>/dev/null | awk '{ print $3 }' | cut -dx -f2 | head -n1)

	for RGB in $(_SANDBOX convert -crop "$WIDTH"x1+0+$((HEIGHT / 2)) -scale 200x "${XDG_PICTURES_DIR-${HOME}/Pictures}/${THEME}" RGB:- | xxd -ps -c3); do
		_PROMPT_LUT[I]="$((0x${RGB:0:2}));$((0x${RGB:2:2}));$((0x${RGB:4:2}))"
		I=$((I + 1))
	done
	rm -f "$TEMP"
	;;
esac

if [[ $LINES -lt 19 ]]; then
	I=$((19 - LINES))
else
	I=0
fi
TEXT=(
	"Lorem ipsum dolor sit amet,"
	"consectetur adipiscing elit."
	"Cras scelerisque, ipsum nec luctus ultricies, "
	"eros enim malesuada ipsum, "
	"eu viverra justo orci ac ex. "
	"Mauris vestibulum elit et augue cursus placerat. "
	"Etiam orci massa, accumsan vitae nisi in,"
	"tristique pharetra leo. "
	"Mauris rhoncus fermentum volutpat. "
	"Nulla sodales leo nec efficitur vehicula. "
	"Nam a lacus non leo suscipit porta id quis est. "
	"Vestibulum ante ipsum primis in faucibus orci "
	"luctus et ultrices posuere cubilia curae; "
	"Fusce blandit augue eget augue scelerisque, "
	"in efficitur justo eleifend. "
	"Ut in urna vel nunc molestie mollis in sit amet justo."
	"Praesent elementum lorem vitae pharetra cursus. "
	"Aliquam"
	"fringilla, erat non cursus gravida, "
)
CHAR="▁"
ESC=$'\e'
PREFG="${ESC}[38;2;"
PREBG="${ESC}[48;2;"
POST="m"
[[ -z $COLUMNS ]] && COLUMNS=$(stty size | awk '{ print $2 }')
[[ -z $LINES ]] && LINES=$(stty size | awk '{ print $1 }')
_COLORS() {
	local I=0
	while [[ $1 ]]; do
		_COLORS[I]=$1
		shift
	done
}
FGCOLOR=${_COLORS[16]}
BGCOLOR=${_COLORS[17]}
if [ -z "$FGCOLOR" ]; then
	echo "MISSING FGCOLOR"
	sleep 3
fi
FGCOLOR_RGB=$((0x$(echo "$FGCOLOR" | cut -c1-2)))";"$((0x$(echo "$FGCOLOR" | cut -c3-4)))";"$((0x$(echo "$FGCOLOR" | cut -c5-6)))
BGCOLOR_RGB=$((0x$(echo "$BGCOLOR" | cut -c1-2)))";"$((0x$(echo "$BGCOLOR" | cut -c3-4)))";"$((0x$(echo "$BGCOLOR" | cut -c5-6)))

while [[ $I -lt 17 ]]; do
	if [[ $I == 16 ]]; then
		TEXT1=${TEXT[I]}
		TEXT1=${TEXT1:0:1}
		FGCOLOR=${_COLORS[17]}
		BGCOLOR=${_COLORS[21]}
		FGCOLOR_RGB=$((0x$(echo "$FGCOLOR" | cut -c1-2)))";"$((0x$(echo "$FGCOLOR" | cut -c3-4)))";"$((0x$(echo "$FGCOLOR" | cut -c5-6)))
		BGCOLOR_RGB=$((0x$(echo "$BGCOLOR" | cut -c1-2)))";"$((0x$(echo "$BGCOLOR" | cut -c3-4)))";"$((0x$(echo "$BGCOLOR" | cut -c5-6)))
		printf "${PREBG}${BGCOLOR_RGB}$POST${PREFG}${FGCOLOR_RGB}$POST$TEXT1"
		TEXT1=${TEXT[I]}
		TEXT1=${TEXT1:1}
	else
		TEXT1="${TEXT[I]}"
	fi
	FGCOLOR=${_COLORS[I]}
	BGCOLOR=${_COLORS[17]}
	FGCOLOR_RGB="$((0x${FGCOLOR:0:2}));$((0x${FGCOLOR:2:2}));$((0x${FGCOLOR:4:2}))"
	BGCOLOR_RGB="$((0x${BGCOLOR:0:2}));$((0x${BGCOLOR:2:2}));$((0x${BGCOLOR:4:2}))"
	printf "${PREBG}${BGCOLOR_RGB}$POST${PREFG}${FGCOLOR_RGB}$POST${TEXT1}"

	J=0
	while [[ $J -lt $((COLUMNS + 1)) ]]; do
		printf "${PREBG}${BGCOLOR_RGB}$POST "
		J=$((J + 1))
	done

	printf "\n"
	I=$((I + 1))
done

INDEX=0
if [[ ${_PROMPT_LUT[0]} ]]; then
	while [[ $INDEX -lt $COLUMNS ]]; do
		printf "${PREBG}${BGCOLOR_RGB}${POST}${PREFG}${_PROMPT_LUT[$((${#_PROMPT_LUT[*]} * INDEX / $((COLUMNS + 1))))]}${POST}${CHAR}"
		INDEX=$((INDEX + 1))
	done
else
	while [[ $INDEX -lt $COLUMNS ]]; do
		printf "${PREBG}${BGCOLOR_RGB}${POST}${PREFG}${FGCOLOR_RGB}${POST}${CHAR}"
		INDEX=$((INDEX + 1))
	done
fi
echo ""
TEXT1=${TEXT[17]}
TEXT1=" ${TEXT1} "
INDEX=0
printf "\033[${COLUMNS}D"
while [[ $INDEX -lt $COLUMNS ]]; do
	LUT=$((${#_PROMPT_LUT[*]} * INDEX / $((COLUMNS + 1))))
	if [ -z "${_PROMPT_TEXT_LUT[0]}" ]; then
		_PROMPT_TEXT_LUT[0]="255;255;255"
	fi
	TEXT_LUT=$(((${#_PROMPT_TEXT_LUT[*]} * INDEX) / $((COLUMNS + 1))))
	if [[ ${#_PROMPT_LUT[@]} = 0 ]]; then
		# sic!
		printf "${PREBG}${FGCOLOR_RGB}${POST}${PREFG}${BGCOLOR_RGB}${POST}${TEXT1:${INDEX}:1}"
	else
		printf "${PREBG}${_PROMPT_LUT[${LUT}]}${POST}${PREFG}${_PROMPT_TEXT_LUT[${TEXT_LUT}]}${POST}${TEXT1:${INDEX}:1}"
	fi
	INDEX=$((INDEX + 1))
done
printf "\033[0m${PREBG}${BGCOLOR_RGB}$POST "
printf "${PREFG}${FGCOLOR_RGB}${POST}${PREBG}${BGCOLOR_RGB}${POST}${TEXT[18]}"
I=$((${#TEXT[17]} + ${#TEXT[18]}))
while [[ $I -lt $COLUMNS ]]; do
	printf " "
	I=$((I + 1))
done
I=0
while [[ $I -lt $((LINES - PRE_LINES - 3)) ]]; do
	J=0
	while [[ $J -lt $COLUMNS ]]; do
		printf "%s%s%s " "${PREBG}" "${BGCOLOR_RGB}" "$POST"
		J=$((J + 1))
	done
	printf "\n"
	I=$((I + 1))
done
