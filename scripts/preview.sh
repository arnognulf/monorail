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
if [[ $ZSH_NAME ]]; then
	setopt KSH_ARRAYS
	setopt prompt_subst
fi
_MONORAIL_SHORT_HOSTNAME=$(hostname | cut -d. -f1 | awk '{print tolower($0)}')

if [[ "$3" = "000_README.md" ]]; then
	cat "$3"
	exit 1
fi
_COLORS=()
_COLORS[16]="$1"
_COLORS[17]="$2"
if [[ $LINES -lt 19 ]]; then
	I=$((19 - LINES))
else
	I=0
fi
case $(echo "$3" | awk '{print tolower($0)}') in
*.sh)

	if [[ $XDG_CONFIG_HOME ]]; then
		_MONORAIL_CONFIG="$XDG_CONFIG_HOME/monorail"
	else
		_MONORAIL_CONFIG="$HOME/.config/monorail"
	fi
	_MONORAIL_SHORT_HOSTNAME=$(hostname | cut -d. -f1 | awk '{print tolower($0)}')
	. ${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh &>/dev/null || exit 42
	. "$3" &>/dev/null || exit 42
	case "${3}" in
	*/gradients/*)
		unset "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]"
		;;
	esac
	;;
*)

	THEME="${3}"

	TEMP=$(mktemp --suff=".${THEME##*.}")
	cp -f "${XDG_PICTURES_DIR-${HOME}/Pictures}/${THEME}" "$TEMP"
	WIDTH=$(identify "$TEMP" 2>/dev/null | awk '{ print $3 }' | cut -dx -f1 | head -n1)
	HEIGHT=$(identify "$TEMP" 2>/dev/null | awk '{ print $3 }' | cut -dx -f2 | head -n1)

	for RGB in $(convert -crop "$WIDTH"x1+0+$((HEIGHT / 2)) "${XDG_PICTURES_DIR-${HOME}/Pictures}/${THEME}" PPM:- | convert -scale 200x PPM:- RGB:- | xxd -ps -c3); do
		_PROMPT_LUT[I]="$((0x${RGB:0:2}));$((0x${RGB:2:2}));$((0x${RGB:4:2}))"
		I=$((I + 1))
	done
	rm -f "$TEMP"
	;;
esac

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
#PRE_LINES=3
[[ -z $COLUMNS ]] && COLUMNS=$(stty size | awk '{ print $2 }')
[[ -z $LINES ]] && LINES=$(stty size | awk '{ print $1 }')
FGCOLOR=${_COLORS[16]}
BGCOLOR=${_COLORS[17]}
FGCOLOR_RGB="$((0x${FGCOLOR:0:2}));$((0x${FGCOLOR:2:2}));$((0x${FGCOLOR:4:2}))"
BGCOLOR_RGB="$((0x${BGCOLOR:0:2}));$((0x${BGCOLOR:2:2}));$((0x${BGCOLOR:4:2}))"
#I=0
#while [[ $I -lt $PRE_LINES ]]; do
#	J=0
#	while [[ $J -lt $COLUMNS ]]; do
#		printf "${PREFG}${FGCOLOR_RGB}${POST}${PREBG}${BGCOLOR_RGB}$POST "
#		J=$((J + 1))
#	done
#	printf "\n"
#	I=$((I + 1))
#done

while [[ $I -lt 17 ]]; do
	if [[ $I == 16 ]]; then
		TEXT1=${TEXT[I]}
		TEXT1=${TEXT1:0:1}
		FGCOLOR=${_COLORS[17]}
		BGCOLOR=${_COLORS[21]}
		FGCOLOR_RGB="$((0x${FGCOLOR:0:2}));$((0x${FGCOLOR:2:2}));$((0x${FGCOLOR:4:2}))"
		BGCOLOR_RGB="$((0x${BGCOLOR:0:2}));$((0x${BGCOLOR:2:2}));$((0x${BGCOLOR:4:2}))"
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
		printf "${PREBG}${BGCOLOR_RGB}$POST "
		J=$((J + 1))
	done
	printf "\n"
	I=$((I + 1))
done
