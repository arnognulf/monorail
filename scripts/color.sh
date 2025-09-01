#!/bin/bash
_MONORAIL_CONTRAST() {
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
	_MONORAIL_SHORT_HOSTNAME=${HOSTNAME%%.*}
	_MONORAIL_SHORT_HOSTNAME=${_MONORAIL_SHORT_HOSTNAME,,}

	case "$1" in
	"")
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
			_DEFAULT_FGCOLOR="${_COLOR[16]}"
			_DEFAULT_BGCOLOR="${_COLOR[17]}"
			rm "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
			{
				_COLORS=()
				. "${_MONORAIL_DIR}/colors/${THEME}"
				declare -p _COLORS | cut -d" " -f3-1024
				declare -p _PROMPT_LUT | cut -d" " -f3-1024
				declare -p _PROMPT_TEXT_LUT | cut -d" " -f3-1024
				declare -p _DEFAULT_FGCOLOR | cut -d" " -f3-1024
				declare -p _DEFAULT_BGCOLOR | cut -d" " -f3-1024
			} >"${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
		fi
		exit 0

		;;
	--help | -h)
		echo "Usage:
monorail_color <FGCOLOR> [<BGCOLOR>]

Example:
monorail_color 444444
monorail_color 89ecff 444444
"
		exit 1
		;;
	esac
	_PROMPT_TEXT_LUT=()
	_PROMPT_LUT=()
	. "$_MONORAIL_CONFIG"/colors-${_MONORAIL_SHORT_HOSTNAME}.sh

	if [[ "${#1}" != 6 ]]; then
		\echo "ERROR: color must be hexadecimal and 6 hexadecimal characters" 1>&2 | tee 1>/dev/null
		return 1
	fi

	_COLORS[16]="$1"
	if [[ $2 ]]; then
		_COLORS[17]="$2"
	fi

	_MONORAIL_CONTRAST "${_COLORS[17]}" "$1" || return 1

	_DEFAULT_BGCOLOR=${_COLORS[17]}
	_DEFAULT_FGCOLOR=${_COLORS[16]}
			if [[ ${#_PROMPT_TEXT_LUT[@]} = 0 ]]; then
				_PROMPT_TEXT_LUT=([0]="255;255;255")
			fi
	rm -f "${_MONORAIL_CONFIG}"/colors-${_MONORAIL_SHORT_HOSTNAME}.sh
	{
		declare -p _COLORS | cut -d" " -f3-1024
		declare -p _PROMPT_LUT | cut -d" " -f3-1024
		declare -p _PROMPT_TEXT_LUT | cut -d" " -f3-1024
		declare -p _DEFAULT_FGCOLOR | cut -d" " -f3-1024
		declare -p _DEFAULT_BGCOLOR | cut -d" " -f3-1024
	} >"${_MONORAIL_CONFIG}"/colors-${_MONORAIL_SHORT_HOSTNAME}.sh
	killall -s WINCH bash zsh &>/dev/null
}
_COLOR "$@"
