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

# preview: fzf --preview="bash $PWD/../preview.sh {}" --no-mouse
# cat gradients.json |jq ".[4]"|jq '.colors'
_PROMPT_FGCOLOR="444444"
_PROMPT_BGCOLOR="ffffff"

. "$1" &>/dev/null || exit 42
CHAR="▁"
ESC=$'\e'
PREFG="${ESC}[38;2;"
PREBG="${ESC}[48;2;"
POST="m"
[[ -z $COLUMNS ]] && COLUMNS=$(stty size | awk '{ print $2 }')
INDEX=0
printf "\e]11;#%s\a\e]10;#%s\a\e]12;#%s\a" "${_PROMPT_BGCOLOR}" "${_PROMPT_FGCOLOR}" "${_PROMPT_FGCOLOR}"
printf "\nLorem ipsum dolor sit amet,\n"

while [[ $INDEX -lt $COLUMNS ]]; do
	printf "${PREFG}${_PROMPT_LUT[$((${#_PROMPT_LUT[*]} * INDEX / $((COLUMNS + 1))))]}${POST}${CHAR}"
	INDEX=$((INDEX + 1))
done
echo ""
TEXT=consectetur
TEXT=" $TEXT "
INDEX=0
printf "\033[${COLUMNS}D"
while [[ $INDEX -lt $COLUMNS ]]; do
	LUT=$((${#_PROMPT_LUT[*]} * INDEX / $((COLUMNS + 1))))
	if [ -z "${_PROMPT_TEXT_LUT[0]}" ]; then
		_PROMPT_TEXT_LUT[0]=$(\printf "%d;%d;%d" "${_PROMPT_BGCOLOR:0:2}" "${_PROMPT_BGCOLOR:2:2}" "${_PROMPT_BGCOLOR:4:2}" 2>/dev/null)
	fi
	TEXT_LUT=$(((${#_PROMPT_TEXT_LUT[*]} * INDEX) / $((COLUMNS + 1))))
	printf "${PREBG}${_PROMPT_LUT[${LUT}]}${POST}${PREFG}${_PROMPT_TEXT_LUT[${TEXT_LUT}]}${POST}${TEXT:${INDEX}:1}"
	INDEX=$((INDEX + 1))
done
printf "\033[0m"
printf " adipiscing elit,"
printf "\n"

