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
if [[ "$3" = "000_README.md" ]]; then
	cat "$3"
	exit 1
fi
_PROMPT_FGCOLOR="$1"
_PROMPT_BGCOLOR="$2"

. "$3" &>/dev/null || exit 42

CHAR="▁"
ESC=$'\e'
PREFG="${ESC}[38;2;"
PREBG="${ESC}[48;2;"
POST="m"
PRE_LINES=3
[[ -z $COLUMNS ]] && COLUMNS=$(stty size | awk '{ print $2 }')
[[ -z $LINES ]] && LINES=$(stty size | awk '{ print $1 }')
FGCOLOR_RGB="$((0x${_PROMPT_FGCOLOR:0:2}));$((0x${_PROMPT_FGCOLOR:2:2}));$((0x${_PROMPT_FGCOLOR:4:2}))"
BGCOLOR_RGB="$((0x${_PROMPT_BGCOLOR:0:2}));$((0x${_PROMPT_BGCOLOR:2:2}));$((0x${_PROMPT_BGCOLOR:4:2}))"
I=0
while [[ $I -lt $PRE_LINES ]]; do
	J=0
	while [[ $J -lt $COLUMNS ]]; do
		printf "${PREFG}${FGCOLOR_RGB}${POST}${PREBG}${BGCOLOR_RGB}$POST "
		J=$((J + 1))
	done
	printf "\n"
	I=$((I + 1))
done

TEXT0="Lorem ipsum dolor sit amet,"
printf "$TEXT0"

J=${#TEXT0}
while [[ $J -lt $COLUMNS ]]; do
	printf "${PREBG}${BGCOLOR_RGB}$POST "
	J=$((J + 1))
done
printf "\n"

INDEX=0
while [[ $INDEX -lt $COLUMNS ]]; do
	printf "${PREBG}${BGCOLOR_RGB}${POST}${PREFG}${_PROMPT_LUT[$((${#_PROMPT_LUT[*]} * INDEX / $((COLUMNS + 1))))]}${POST}${CHAR}"
	INDEX=$((INDEX + 1))
done
echo ""
TEXT1=consectetur
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
		printf "${ESC}[7m${TEXT1:${INDEX}:1}"
	else
		printf "${PREBG}${_PROMPT_LUT[${LUT}]}${POST}${PREFG}${_PROMPT_TEXT_LUT[${TEXT_LUT}]}${POST}${TEXT1:${INDEX}:1}"
	fi
	INDEX=$((INDEX + 1))
done
printf "\033[0m${PREBG}${BGCOLOR_RGB}$POST "
TEXT2="adipiscing elit,"
printf "${PREFG}${FGCOLOR_RGB}${POST}${PREBG}${BGCOLOR_RGB}${POST}${TEXT2}"
I=$((${#TEXT1} + ${#TEXT2}))
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
