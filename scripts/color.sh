#!/bin/bash
if [[ $ZSH_NAME ]]; then
	setopt KSH_ARRAYS
	setopt prompt_subst
fi

_MONORAIL_CONTRAST() {
	if which bc &>/dev/null; then
		:
	else
		"error: please install bc"
		exit 42
	fi

	COLOR1=$1
	COLOR2=$2

	r1="$((0x${COLOR1:0:2}))"
	g1="$((0x${COLOR1:2:2}))"
	b1="$((0x${COLOR1:4:2}))"

	r2="$((0x${COLOR2:0:2}))"
	g2="$((0x${COLOR2:2:2}))"
	b2="$((0x${COLOR2:4:2}))"

	# translate sRGB to CIE XYZ (only Y-component)
	Y1=$(echo "define vp(v){v=v/255.0;if(v<=0.04045)return v/12.92; return e(2.4*l((v+0.055)/1.055)) };0.2126729*vp($r1) + 0.71515122*vp($g1) + 0.0721750*vp($b1)" | bc -l)

	Y2=$(echo "define vp(v){v=v/255.0;if(v<=0.04045)return v/12.92; return e(2.4*l((v+0.055)/1.055)) };0.2126729*vp($r2) + 0.71515122*vp($g2) + 0.0721750*vp($b2)" | bc -l)

	# the contrast is the factor K of (Y_largest + 0.05) / (Y_smallest + 0.05)
	# according to WCAG as found on https://www.leserlich.info/werkzeuge/kontrastrechner/index-en.php
	CONTRAST=$(echo "
    define int(x){auto s;s=scale=0;x/=1;scale=s;return x}
    define round(x){return int(x+0.5)}
    define max(x,y){if(x>y)return x;return y}
    define min(x,y){if(x<y)return x;return y}
    if($Y1>$Y2)($Y1 + 0.05)/($Y2 + 0.05) else ($Y2 + 0.05)/($Y1 + 0.05)" | bc -l)
	INT_CONTRAST=$(\echo "define int(x){auto s;s=scale=0;x/=1;scale=s;return x};int(${CONTRAST}*100)" | \bc -l)
	# contrast 1.5 is set sufficiently low to be visible, but high enough to avoid shooting yourself in the foot.
	if [[ ${INT_CONTRAST} -lt 150 ]]; then
		\echo "ERROR: background and foreground are too similar, try setting either background or foreground to '7f7f7f' and the other to '000000' or 'ffffff'" 1>&2 | tee 1>/dev/null
		return 1
	else
		return 0
	fi
}
_COLOR() {
	case "$1" in
	"")
		if which fzf &>/dev/null; then
			:
		else
			"error: please install fzf"
			exit 42
		fi

		local THEME
		unset "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]"
		_PROMPT_LUT=()
		_PROMPT_TEXT_LUT=()
		_COLORS=()
		. "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
		[[ ${_DEFAULT_FGCOLOR} ]] || _DEFAULT_FGCOLOR=444444
		[[ ${_DEFAULT_BGCOLOR} ]] || _DEFAULT_BGCOLOR=ffffff
		[[ ${_COLORS[16]} ]] || _COLORS[16]=$_DEFAULT_FGCOLOR
		[[ ${_COLORS[17]} ]] || _COLORS[17]=$_DEFAULT_BGCOLOR
		THEME=$(\cd ${_MONORAIL_DIR}/colors && fzf --preview "${_MONORAIL_DIR}/scripts/preview.sh "${_COLORS[16]}" "${_COLORS[17]}" {}")
		if [[ ${THEME} ]]; then
			_COLORS=()
			. "${_MONORAIL_DIR}/colors/${THEME}"
			_UPDATE_CONFIG
		fi
		exit 0
		;;
	--list | -l)
		cd "$_MONORAIL_DIR/colors"
		if [ -t 1 ]; then
			for SCHEME in *.sh; do
				echo "$SCHEME" | sed 's/\.sh//g'
			done | less
		else
			for SCHEME in *.sh; do
				echo "$SCHEME" | sed 's/\.sh//g'
			done
		fi
		exit 1
		;;
	--help | -h)
		echo "
Set background and foreground colors of the terminal.
This tool refuses to set back- and foreground colors that are too similar.
Predefined colorschemes can be listed and selected.
CMD_CURSOR is the cursor visible in commands outside the prompt.

Usage:
    monorail_color <FGCOLOR> [<BGCOLOR>] [<CMD_CURSOR>]
    monorail_color <SCHEME>
    monorail_color <[-l|--list>
 
Examples:
    monorail_color 444444
    monorail_color 89ecff 444444
    monorail_color 89ecff 444444 fff0f0
    monorail_color Adwaita
"
		exit 1
		;;
	esac
	_PROMPT_TEXT_LUT=()
	_PROMPT_LUT=()
	unset _COLORS
	unset "_COLORS[*]"
	. "$_MONORAIL_CONFIG"/colors-${_MONORAIL_SHORT_HOSTNAME}.sh

	if [ "$1" = "000000" ]; then
		HANDLE_COLOR_ARG "$@"
	elif [ "${#1}" = 6 ] && [ $(printf "%x" "0x$1" 2>/dev/null) != 0 ]; then
		HANDLE_COLOR_ARG "$@"
	else
		# not color
		case "$1" in
		*/*) . "$1" ;;
		*)
			cd "${_MONORAIL_DIR}"/colors
			. ./"$1".sh
			;;
		esac
	fi
	_UPDATE_CONFIG
}
HANDLE_COLOR_ARG() {
	# TODO: validate $2 ?
	_COLORS[16]="$1"
	if [[ $2 ]]; then
		_COLORS[17]="$2"
	fi
	if [[ $3 ]]; then
		_COLORS[21]="$3"
	fi

	_MONORAIL_CONTRAST "${_COLORS[17]}" "$1" || return 1
}
_UPDATE_CONFIG() {
	_DEFAULT_BGCOLOR=${_COLORS[17]}
	_DEFAULT_FGCOLOR=${_COLORS[16]}

	if [[ ${#_PROMPT_TEXT_LUT[@]} = 0 ]]; then
		_PROMPT_TEXT_LUT=([0]="255;255;255")
	fi
	rm -f "${_MONORAIL_CONFIG}"/colors-${_MONORAIL_SHORT_HOSTNAME}.sh
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
	} >"${_MONORAIL_CONFIG}"/colors-${_MONORAIL_SHORT_HOSTNAME}.sh
	killall -s WINCH bash zsh &>/dev/null
}
_COLOR "$@"
