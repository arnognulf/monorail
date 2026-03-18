#!/bin/sh
if [ "$ZSH_NAME" ]; then
	setopt KSH_ARRAYS
	setopt prompt_subst
fi

# shellcheck disable=SC1091 # path exists
. "${_MONORAIL_DIR}"/scripts/callbacks.inc.sh
. "${_MONORAIL_DIR}"/scripts/sandbox.inc.sh

TEMPDIR=$(mktemp -d)
cp -f "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.conf" "${TEMPDIR}"/current.conf
DEST="${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.conf"

_MONORAIL_CONTRAST() {
	if command -v bc 1>/dev/null 2>/dev/null; then
		:
	else
		echo "error: please install bc"
		exit 42
	fi

	COLOR1=$1
	COLOR2=$2

	r1=$((0x$(echo "$COLOR1" | cut -c1-2)))
	g1=$((0x$(echo "$COLOR1" | cut -c3-4)))
	b1=$((0x$(echo "$COLOR1" | cut -c5-6)))

	r2=$((0x$(echo "$COLOR2" | cut -c1-2)))
	g2=$((0x$(echo "$COLOR2" | cut -c3-4)))
	b2=$((0x$(echo "$COLOR2" | cut -c5-6)))

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
	if [ "${INT_CONTRAST}" -lt 150 ]; then
		\echo "ERROR: background and foreground are too similar, try setting either background or foreground to '7f7f7f' and the other to '000000' or 'ffffff'" 1>&2 | tee 1>/dev/null
		return 1
	else
		return 0
	fi
}
_COLOR() {
	case "$1" in
	"")
		if command -v fzf >/dev/null 2>/dev/null; then
			:
		else
			echo "error: please install fzf"
			exit 42
		fi
		for REQUIRED_SHELL in bash zsh ksh; do
			PREVIEW_SHELL=$(command -v "${REQUIRED_SHELL}")
			if [ "$PREVIEW_SHELL" ]; then
				break
			fi
		done
		if [ -z "$PREVIEW_SHELL" ]; then
			echo "error: preview requires bash, zsh, or ksh to be installed"
			exit 42
		fi
		# shellcheck disable=SC1090 # file will exist
		. "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.conf"
		[ "${_DEFAULT_FGCOLOR}" ] || _DEFAULT_FGCOLOR=444444
		[ "${_DEFAULT_BGCOLOR}" ] || _DEFAULT_BGCOLOR=ffffff
		[ "${_COLORS_16}" ] || _COLORS_16=$_DEFAULT_FGCOLOR
		[ "${_COLORS_17}" ] || _COLORS_17=$_DEFAULT_BGCOLOR
		THEME=$(\cd "${_MONORAIL_DIR}"/colors && fzf --preview "$PREVIEW_SHELL \"${_MONORAIL_DIR}/scripts/preview.sh\" {}")
		if [ "${THEME}" ]; then
			# shellcheck disable=SC1090 # non-constant source will exist
			. "${_MONORAIL_DIR}/colors/${THEME}"
			_UPDATE_CONFIG "$THEME" "$FGCOLOR" "$BGCOLOR" "$CURSORCOLOR"
		fi
		exit 0
		;;
	--list | -l)
		cd "$_MONORAIL_DIR/colors" || {
			echo "error: missing colors directory"
			exit 42
		}
		if [ -t 1 ]; then
			for SCHEME in *.conf; do
				echo "$SCHEME" | sed 's/\.conf//g'
			done | less
		else
			for SCHEME in *.conf; do
				echo "$SCHEME" | sed 's/\.conf//g'
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
	*)
		{
			FGCOLOR=$((0x$1))
		} 2>/dev/null
		if [ $FGCOLOR ]; then
			FGCOLOR=$1
			BGCOLOR=$2
			CURSORCOLOR=$3
		else
			THEME=$1
		fi
		;;
	esac
	# shellcheck disable=SC2329 # callback function
	_COLORS() {
		I=0
		for ARG in "$@"; do
			if [ "$I" = 16 ]; then
				_COLORS_16=$ARG
			fi
			if [ "$I" = 17 ]; then
				_COLORS_17=$ARG
			fi
			I=$((I + 1))
		done
	}
	# shellcheck disable=SC1091 # file will be created
	. "${TEMPDIR}/current.conf"

	NUM_ARGS=0
	for ARG in "$@"; do
		NUM_ARGS=$((NUM_ARGS + 1))
	done

	if [ "$1" = "000000" ]; then
		HANDLE_COLOR_ARG "$@" || return 1
	else
		{
			FGCOLOR=$((0x$1))
			if [ $((0x$1)) ]; then
				FGCOLOR=$1
			fi
			if [ $((0x$2)) ]; then
				BGCOLOR=$2
			fi
			if [ $((0x$3)) ]; then
				CURSORCOLOR=$3
			fi

		} 2>/dev/null

		if [ "$FGCOLOR" ] && [ "$BGCOLOR" ]; then
			HANDLE_COLOR_ARG "$FGCOLOR" "$BGCOLOR" || exit 1
		elif [ "$FGCOLOR" ]; then
			HANDLE_COLOR_ARG "$FGCOLOR" "$_COLORS_17" || exit 1
		fi
		# not color
		[ -z "$FGCOLOR" ] && [ -z "$BGCOLOR" ] && [ -z "$CURSORCOLOR" ] && case "$1" in
		*/*)
			# shellcheck disable=SC1090 # file will exist
			. "$1"
			;;
		*)
			cd "${_MONORAIL_DIR}"/colors || {
				echo "error: missing colors directory"
				exit 42
			}
			# shellcheck disable=SC1090 # file exists
			. ./"$THEME".conf
			;;
		esac
	fi
	_UPDATE_CONFIG "$THEME" "$FGCOLOR" "$BGCOLOR" "$CURSORCOLOR"
}
HANDLE_COLOR_ARG() {
	_COLORS_16="$1"
	if [ "$2" ]; then
		{
			TMP=$((0x$2))
		} 2>/dev/null
		if [ -z "$TMP" ]; then
			echo "error; $2 is not a valid color"
			exit 42
		fi
		_COLOR_17=$2
	fi
	if [ "$3" ]; then
		{
			TMP=$((0x$3))
		} 2>/dev/null
		if [ -z "$TMP" ]; then
			echo "error; $3 is not a valid color"
			exit 42
		fi
		_COLORS_21="$3"
	fi

	_MONORAIL_CONTRAST "${_COLORS_17}" "$1" || return 1
}
_UPDATE_CONFIG() {
	THEME=$1
	case $THEME in
	"") THEME="" ;;
	*.conf) : ;;
	*) THEME=${THEME}.conf ;;
	esac
	FGCOLOR=$2
	BGCOLOR=$3
	CURSORCOLOR=$4
	if [ "$BGCOLOR" ]; then
		_COLORS_17=$BGCOLOR
		_DEFAULT_BGCOLOR=${BGCOLOR}
	else
		_DEFAULT_BGCOLOR=${_COLORS_17}
	fi
	if [ "$FGCOLOR" ]; then
		_DEFAULT_FGCOLOR=${FGCOLOR}
		_COLORS_16=$FGCOLOR
	else
		_DEFAULT_FGCOLOR=${_COLORS_16}
	fi
	if [ "$CURSORCOLOR" ]; then
		_COLORS_21=$CURSORCOLOR
	fi

	rm "${DEST}"

	cd "${_MONORAIL_DIR}"/colors || {
		echo "error: missing colors directory"
		exit 42
	}
	# set default colors
	ADD_CURRENT_PROMPT_TEXT_LUT
	ADD_CURRENT_PROMPT_LUT
	RESET_CALLBACKS
	if [ "$THEME" ]; then
		# shellcheck disable=SC1090 # file will exist
		. ./"$THEME"
		_COLORS() {
			printf "_COLORS"
			for COLOR in "$@"; do
				echo " \\"
				printf "%s" "$COLOR"
			done
			echo ""
			echo ""
		}

		# shellcheck disable=SC1090 # file will exist
		. ./"${THEME}" >>"${DEST}"
	else
		_COLORS() {
			I=0
			printf "_COLORS"
			for COLOR in "$@"; do
				echo " \\"
				if [ $I = 16 ]; then
					printf "%s" "$_COLORS_16"
				elif [ $I = 17 ]; then
					printf "%s" "$_COLORS_17"
				elif [ $I = 21 ]; then
					printf "%s" "$_COLORS_21"
				else
					printf "%s" "$COLOR"
				fi
				I=$((I + 1))
			done
			echo ""
			echo ""
		}
		# shellcheck disable=SC1091 # file will exist
		. "${TEMPDIR}/current.conf" >>"${DEST}"
	fi

	killall -s WINCH bash zsh 1>/dev/null 2>/dev/null

}

_COLOR "$@"
