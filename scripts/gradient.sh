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

# OKLab: https://bottosson.github.io/posts/oklab/
# bc(1) functions: http://phodd.net/gnu-bc/code/logic.bc

# INPUT:
# $R - R component 0-255
# $G - G component 0-255
# $B - G component 0-255
#
# OUTPUT
# $L - L component 0.0-1.0
# $a - a component 0.0-1.0
# $b - b component 0.0-1.0
_LINEAR_SRGB_TO_OKLAB() {
	local DEF_CBRT="define cbrt(x){return e(l(x)/3)}"

	local l=$(\echo "$DEF_CBRT;cbrt(0.4122214708 * $r/255.0 + 0.5363325363 * $g/255.0 + 0.0514459929 * $b/255.0)" | bc -l)
	local m=$(\echo "$DEF_CBRT;cbrt(0.2119034982 * $r/255.0 + 0.6806995451 * $g/255.0 + 0.1073969566 * $b/255.0)" | bc -l)
	local s=$(\echo "$DEF_CBRT;cbrt(0.0883024619 * $r/255.0 + 0.2817188376 * $g/255.0 + 0.6299787005 * $b/255.0)" | bc -l)

	L=$(\echo "0.2104542553*$l + 0.7936177850*$m - 0.0040720468*$s" | bc -l)
	a=$(\echo "1.9779984951*$l - 2.4285922050*$m + 0.4505937099*$s" | bc -l)
	b=$(\echo "0.0259040371*$l + 0.7827717662*$m - 0.8086757660*$s" | bc -l)
}

# INPUT:
# $L - L component 0.0-1.0
# $a - a component 0.0-1.0
# $b - b component 0.0-1.0
# $DELTA_L - delta of L 0.0-1.0
# $DELTA_a - delta of a 0.0-1.0
# $DELTA_b - delta of b 0.0-1.0
# $MULTIPLIER
#
# OUTPUT
# $R - R component 0-255
# $G - G component 0-255
# $B - B component 0-255
_OKLAB_TO_LINEAR_SRGB() {
	local l=$(\echo "(($L + $DELTA_L * $NUM) + 0.3963377774 * ($a + $DELTA_a * $NUM) + 0.2158037573 * ($b + $DELTA_b * $NUM))^3" | bc -l)
	local m=$(\echo "(($L + $DELTA_L * $NUM) - 0.1055613458 * ($a + $DELTA_a * $NUM) - 0.0638541728 * ($b + $DELTA_b * $NUM))^3" | bc -l)
	local s=$(\echo "(($L + $DELTA_L * $NUM) - 0.0894841775 * ($a + $DELTA_a * $NUM) - 1.2914855480 * ($b + $DELTA_b * $NUM))^3" | bc -l)

	DEF_ROUND="
    define max(x,y){if(x>y)return x;return y}
    define min(x,y){if(x<y)return x;return y}
    define int(x){auto s;s=scale=0;x/=1;scale=s;return x}
define round(x){return int(x+0.5)}"
	R=$(\echo "$DEF_ROUND
int(max(0.0, min(255.0, round(255.0 * ( 4.0767416621 * $l - 3.3077115913 * $m + 0.2309699292 * $s)))))" | bc -l)
	G=$(\echo "
$DEF_ROUND
int(max(0.0, min(255.0, round(255.0 * (-1.2684380046 * $l + 2.6097574011 * $m - 0.3413193965 * $s)))))" | bc -l)
	B=$(\echo "
$DEF_ROUND
int(max(0.0, min(255.0, round(255.0 * (-0.0041960863 * $l - 0.7034186147 * $m + 1.7076147010 * $s)))))" | bc -l)
}

# gradient [start_color index]
_GRADIENT() {
	_MONORAIL_SHORT_HOSTNAME=${HOSTNAME%%.*}
	_MONORAIL_SHORT_HOSTNAME=${_MONORAIL_SHORT_HOSTNAME,,}

	local PREFIX=""
	_DEFAULT_BGCOLOR=ffffff
	_DEFAULT_FGCOLOR=444444
	local RESET_COLORS=""

	while [[ "$1" = "-"* ]]; do
		case "$1" in
		--text)
			local HELP_PREFIX=text
			local PREFIX=TEXT_
			shift
			;;
		--help | -h)
			cat ${_MONORAIL_DIR}/gradients/000_README.md
			exit 1
			;;
		esac
	done

	case "$1" in
	"")
		local THEME
		_PROMPT_LUT=()
		_COLORS=()
		. "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
		[[ ${_DEFAULT_FGCOLOR} ]] || _DEFAULT_FGCOLOR=444444
		[[ ${_DEFAULT_BGCOLOR} ]] || _DEFAULT_BGCOLOR=ffffff
		[[ ${_COLORS[16]} ]] || _COLORS[16]=$_DEFAULT_FGCOLOR
		[[ ${_COLORS[17]} ]] || _COLORS[17]=$_DEFAULT_BGCOLOR
		unset "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]"
		THEME=$(\cd ${_MONORAIL_DIR}/gradients && fzf --preview "${_MONORAIL_DIR}/scripts/preview.sh "${_COLORS[16]}" "${_COLORS[17]}" {}")
		if [[ ${THEME} ]]; then
			_PROMPT_LUT=()
			_PROMPT_TEXT_LUT=()
			. "${_MONORAIL_DIR}/gradients/${THEME}"
			rm "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
			{
				declare -p _COLORS | cut -d" " -f3-1024
				declare -p _PROMPT_LUT | cut -d" " -f3-1024
				declare -p _PROMPT_TEXT_LUT | cut -d" " -f3-1024
				declare -p _DEFAULT_FGCOLOR | cut -d" " -f3-1024
				declare -p _DEFAULT_BGCOLOR | cut -d" " -f3-1024
			} >"${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
		fi
		exit 0
		;;
	esac
	if [[ "${#@}" = 1 ]]; then
		if [[ -f "${_MONORAIL_DIR}/gradients/${1}.sh" ]]; then
			unset "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]"
			. "${_MONORAIL_DIR}/gradients/${1}".sh
			if [[ ${#_PROMPT_TEXT_LUT[@]} = 0 ]]; then
				_PROMPT_TEXT_LUT=([0]="255;255;255")
			fi
			"${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
			{
				declare -p _PROMPT_LUT | cut -d" " -f3-1024
				declare -p _PROMPT_TEXT_LUT | cut -d" " -f3-1024
				declare -p _DEFAULT_FGCOLOR | cut -d" " -f3-1024
				declare -p _DEFAULT_BGCOLOR | cut -d" " -f3-1024
			} >"${_MONORAIL_CONFIG}"/colors-${_MONORAIL_SHORT_HOSTNAME}.sh

		else
			{
				echo "gradient: No such theme \"$1\""
				echo "Select any of:
"
				local FILE
				for FILE in ${_MONORAIL_DIR}/gradients/*; do
					FILE="${FILE##*/}"
					FILE="${FILE%.sh}"
					echo "${FILE}"
				done

				echo "
or \"None\" to use text color"
			} | less
			return 1
		fi
		unset "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]"
		. ${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh
		return 0
	fi
	# reload in case user has manually modified colors.sh
	_PROMPT_TEXT_LUT=([0]="255;255;255")
	. ${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh

	unset "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]"

	local L
	local a
	local b
	local SRC_L=""
	local SRC_a=""
	local SRC_b=""
	local DST_L=""
	local DST_a=""
	local DST_b=""
	local INDEX=0
	while [ -n "${1}" ]; do
		local STEPS=${1}
		[ "$STEPS" -lt 1 ] && STEPS=1
		if [ "$STEPS" -gt 100 ]; then
			echo "STEPS must be in range 1-100"
			exit 42
		fi
		local COLOR=$2
		# TODO: conversion is broken for pitch black. Work around for now:
		if [[ $COLOR = 000000 ]]; then
			COLOR=010101
		fi
		shift 2
		local r="$((0x${COLOR:0:2}))"
		local g="$((0x${COLOR:2:2}))"
		local b="$((0x${COLOR:4:2}))"
		_LINEAR_SRGB_TO_OKLAB

		DST_L=$L
		DST_a=$a
		DST_b=$b
		[ -z "${SRC_L}" ] && SRC_L=${DST_L}
		[ -z "${SRC_a}" ] && SRC_a=${DST_a}
		[ -z "${SRC_b}" ] && SRC_b=${DST_b}
		L=$SRC_L
		a=$SRC_a
		b=$SRC_b

		# Create look-up-tables of 200 elements by default
		# Normally, terminals have 80-150 columns of width.
		# In order to avoid banding we need to sample down the gradient
		# We also want a value that is not too big to compute/keep in memory.
		# Thus, 200 was an easy choice since it's only a multiplier on what custom values the user specifies.
		TOTAL_STEPS=$((STEPS * 2 - INDEX))
		DELTA_L=$(echo "($DST_L - $SRC_L)/$TOTAL_STEPS" | bc -l)
		DELTA_a=$(echo "($DST_a - $SRC_a)/$TOTAL_STEPS" | bc -l)
		DELTA_b=$(echo "($DST_b - $SRC_b)/$TOTAL_STEPS" | bc -l)

		local I=0
		while [ $I -lt $TOTAL_STEPS ]; do

			NUM=$I
			_OKLAB_TO_LINEAR_SRGB
			eval "_PROMPT_${PREFIX}LUT[$INDEX]=\"$R;$G;$B\""
			let INDEX++
			#echo "R=${R}, G=${G}, B=${B}"
			let I++
		done

		SRC_L=${DST_L}
		SRC_a=${DST_a}
		SRC_b=${DST_b}
	done
	if [[ -z "$DEST" ]]; then
		DEST="${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
	fi
	if [[ ${#_PROMPT_TEXT_LUT[@]} = 0 ]]; then
		_PROMPT_TEXT_LUT=([0]="255;255;255")
	fi
	{
		declare -p _PROMPT_LUT | cut -d" " -f3-1024
		declare -p _PROMPT_TEXT_LUT | cut -d" " -f3-1024 | grep -v '()'
		declare -p _DEFAULT_FGCOLOR | cut -d" " -f3-1024
		declare -p _DEFAULT_BGCOLOR | cut -d" " -f3-1024
		declare -p _COLORS | cut -d" " -f3-1024
	} >"${DEST}" 2>/dev/null
	killall -s WINCH bash zsh &>/dev/null
}
_GRADIENT "$@"
