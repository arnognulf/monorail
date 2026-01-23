#!/bin/sh
# Copyright (c) 2025 Thomas Eriksson
# SPDX-License-Identifier: BSD-3-Clause

# monorail.compat.sh is the fallback of monorail if using a non-supported terminal or a non-supported shell.

# Terminals tested:
# konsole
# gnome-terminal (vte)
# DEC VT240, VT100, VT52, VT05
# xterm
# Wyse 30
# Wyse 60
# Wyse 370
# Tek 40xx
# ADM-3a
# IBM 3151
# IBM 3270
# Ann Arbour
# HP 2621A
# Hazeltine 1500
# Sun Console
# heath19 (?)
# vc404
# hft
# scoansi
#
# Shells tested:
# bash
# zsh
# ksh93
# posh
# dash
# mksh
# busybox sh
# osh
# brush
CR=$(printf '\015')
ESC=$(printf '\033')
BEL=$(printf '\007')
unset _MONORAIL_UPDATING

if [ -z "$_MONORAIL_DIR" ]; then
	if [ "$XDG_DATA_HOME" ]; then
		_MONORAIL_DIR="$XDG_DATA_HOME/monorail"
	else
		_MONORAIL_DIR="$HOME/.local/share/data/monorail"
	fi
fi
if [ -z "$_MONORAIL_CONFIG" ]; then
	if [ "$XDG_CONFIG_HOME" ]; then
		_MONORAIL_CONFIG="$XDG_CONFIG_HOME/monorail"
	else
		_MONORAIL_CONFIG="$HOME/.config/monorail"
	fi
	mkdir -p "$_MONORAIL_CONFIG"
fi
# netbsd sets LC_CTYPE, Linux sets LANG
if [ "$XTERM_LOCALE" ]; then
	_MONORAIL_LANG=$XTERM_LOCALE
elif [ "$LANG" ]; then
	_MONORAIL_LANG=$LANG
else
	_MONORAIL_LANG=$LC_CTYPE
fi
_MONORAIL_NORMAL="|"
_MONORAIL_LINE_SEGMENT=_
_MONORAIL_OFFSET=0

case "$TERM" in
"vt"???)
	bind 'set enable-bracketed-paste off'
	_MONORAIL_ANSI_TERMINAL=1
	# vt100 or vt220 emulators normally do not support DEC alternate graphics
	# which is used to draw the horizontal line but sets "vt100" or "vt220"
	# as TERM for compatibility.
	# detect these terminals by checking if they have supported sizes
	if [ "$COLUMNS" = 80 ] || [ "$COLUMNS" = 132 ]; then
		if [ $LINES = 24 ] || [ "$LINES" = 14 ]; then
			_MONORAIL_LINE_SEGMENT=s
			_MONORAIL_VTXXX_TERMINAL=1
		fi
	fi
	;;
"wyse60" | "wy60" | "wy50" | "wy160")
	_MONORAIL_OFFSET=1
	# TODO: fix after the cursor positioning revamp
	#_MONORAIL_REVERSE="$_MONORAIL_PREHIDE${ESC}G4$_MONORAIL_POSTHIDE"
	#_MONORAIL_NORMAL="$_MONORAIL_PREHIDE${ESC}G0$_MONORAIL_POSTHIDE"
	bind 'set enable-bracketed-paste off'
	_MONORAIL_DUMB_TERMINAL=1
	;;
"dm2500" | "dumb" | "vt50")
	# uppercase only terminals have no underscore character
	bind 'set enable-bracketed-paste off'
	_MONORAIL_DUMB_TERMINAL=1
	_MONORAIL_LINE_SEGMENT=-
	_MONORAIL_NORMAL="!"
	_MONORAIL_OFFSET=1
	;;
"tek"*)
	# dumb lowercase terminals
	bind 'set enable-bracketed-paste off'
	_MONORAIL_DUMB_TERMINAL=1
	_MONORAIL_OFFSET=2
	if [ "$TERM" = "tek4010" ]; then
		_MONORAIL_LINE_SEGMENT=-
		_MONORAIL_NORMAL="!"
	else
		_MONORAIL_NORMAL="|"
	fi
	;;
vt?? | "ibm-327"* | "dp33"?? | "adm3a" | "hp2621" | "hz1500" | "wy30" | "vc404" | "dg2"*)
	# dumb lowercase terminals
	bind 'set enable-bracketed-paste off'
	_MONORAIL_OFFSET=1
	_MONORAIL_DUMB_TERMINAL=1
	_MONORAIL_NORMAL="|"
	;;
"tty"* | "tn"* | "ti"*)
	_MONORAIL_DUMB_TERMINAL=1
	_MONORAIL_NORMAL="|"

	;;
"xterm-color" | "xterm-16color")
	_MONORAIL_ANSI_TERMINAL=1
	_MONORAIL_XTERM_TERMINAL=1
	;;
"at386" | "hft" | "scoansi")
	bind 'set enable-bracketed-paste off'
	_MONORAIL_ANSI_TERMINAL=1
	_MONORAIL_OFFSET=1
	;;
"aaa" | "sun" | "wy370")
	bind 'set enable-bracketed-paste off'
	_MONORAIL_ANSI_TERMINAL=1
	;;
*)
	_MONORAIL_ANSI_TERMINAL=1
	_MONORAIL_XTERM_TERMINAL=1
	# shellcheck disable=SC2027,SC2086 # shellcheck confused on globbing
	if [ -n "$XTERM_VERSION" ] && [ "$(echo \"$XTERM_VERSION\" | cut -d'(' -f2 | cut -d')' -f1)" -gt 330 ]; then
		_MONORAIL_TRUECOLOR_TERMINAL=1
	fi
	# screen and linux vt accepts truecolor control sequencies, but do not display truecolor satisfactory
	if [ "$TERM_PROGRAM" = "GNUstep_Terminal" ]; then
		_MONORAIL_XTERM_TERMINAL=1
	fi
	if [ "$COLORTERM" = "truecolor" ] || [ "$COLORTERM" = "24bit" ] || [ "$COLORTERM" = "rxvt-xpm" ]; then
		if [ "$TERM" != "linux" ]; then
			_MONORAIL_TRUECOLOR_TERMINAL=1
		fi
	fi
	case "$_MONORAIL_LANG" in
	*.UTF-8)
		# UTF-8 "Lower one eighth block"
		_MONORAIL_LINE_SEGMENT=$(printf '\342\226\201')
		;;
	esac
	;;
esac
_MONORAIL_SHORT_HOSTNAME=$(hostname | cut -d. -f1 | awk '{print tolower($0)}')
if [ ! -f "$_MONORAIL_CONFIG"/colors-"$_MONORAIL_SHORT_HOSTNAME".sh ]; then
	cat "$_MONORAIL_DIR"/gradients/Default.sh "$_MONORAIL_DIR"/colors/Default.sh >"$_MONORAIL_CONFIG"/colors-"$_MONORAIL_SHORT_HOSTNAME".sh
fi
if [ "$_MONORAIL_XTERM_TERMINAL" ] || [ "$_MONORAIL_ANSI_TERMINAL" ]; then
	# vscode does not support disabling line wrap
	if [ "$TERM_PROGRAM" != "vscode" ]; then
		_MONORAIL_DISABLE_WRAP="${ESC}[?7l"
	fi
	_MONORAIL_REVERSE="${_MONORAIL_DISABLE_WRAP}${ESC}[7m"
	_MONORAIL_REVERSE="${ESC}[7m"
	_MONORAIL_NORMAL="${ESC}[?25h${ESC}[?7h${ESC}[0m"
fi

if [ "$ZSH_NAME" ]; then
	setopt prompt_subst
fi

if [ "$_MONORAIL_TRUECOLOR_TERMINAL" ]; then
	_COLORS() {
		# 0-15   `0`-`f` (hex) = ansi color
		# 16     `g`           = foreground
		# 17     `h`           = background
		# 18     `i`           = bold color
		# 19     `j`           = selection color
		# 20     `k`           = selected text color
		# 21     `l`           = cursor
		# 22     `m`           = cursor text (not present in any iTerm2-Color-Schemes)
		_MONORAIL_COLORS=""
		I=0
		while [ "$1" ]; do
			if [ $I -lt 16 ]; then
				_MONORAIL_COLORS="$_MONORAIL_COLORS$ESC]4;$I;#$1$BEL"
			elif [ $I = 16 ]; then
				_MONORAIL_COLORS="$_MONORAIL_COLORS$ESC]10;#$1$BEL"
			elif [ $I = 17 ]; then
				_MONORAIL_COLORS="$_MONORAIL_COLORS$ESC]11;#$1$BEL"
			elif [ $I = 18 ]; then
				_MONORAIL_CURSOR_COLOR=$1
			fi
			shift
			I=$((I + 1))
		done
	}
	_PROMPT_TEXT_LUT() {
		_PROMPT_TEXT_LUT=$1
	}
	_PROMPT_LUT() {
		LUT_SIZE=0
		# shellcheck disable=SC2034 # variable IGNORED is not used, I do not know a better way to count args in posix sh
		for IGNORED in "$@"; do
			LUT_SIZE=$((LUT_SIZE + 1))
		done
		if [ -z "$_PROMPT_TEXT_LUT" ]; then
			_PROMPT_TEXT_LUT="255;255;255"
		fi
		_MONORAIL_TEXT_LINE="${ESC}[38;2;${_PROMPT_TEXT_LUT}m"
		_MONORAIL_LINE="
${ESC}[A"
		POS=0
		OLDPOS=0
		I=0
		while [ "$I" -lt "$LINE_WIDTH" ]; do
			POS=$((LUT_SIZE * I / $((COLUMNS + 1))))
			SHIFT=$((POS - OLDPOS))
			if [ $SHIFT -gt 0 ]; then
				shift $SHIFT
			fi
			if [ "$I" = "$_MONORAIL_TEXT_LEN" ]; then
				RGB_CUR_COLOR="$1"
			fi
			OLDPOS=$POS
			_MONORAIL_LINE="$_MONORAIL_LINE${ESC}[38;2;${1}m$_MONORAIL_LINE_SEGMENT"
			if [ "$I" -lt "$((_MONORAIL_TEXT_LEN - 1))" ]; then
				_MONORAIL_TEXT_LINE="$_MONORAIL_TEXT_LINE${ESC}[48;2;$1m$(printf "%s" "$_MONORAIL_TEXT" | cut -c$((I + 1)))"
			fi
			I=$((I + 1))
		done
		_MONORAIL_LINE="$_MONORAIL_LINE
$_MONORAIL_TEXT_LINE"

		RGB_CUR_R=$(echo "${RGB_CUR_COLOR}" | cut -d';' -f1)
		RGB_CUR_G=$(echo "${RGB_CUR_COLOR}" | cut -d';' -f2)
		RGB_CUR_B=$(echo "${RGB_CUR_COLOR}" | cut -d';' -f3)
		HEX_CURSOR_COLOR=$(printf "%.2x%.2x%.2x" "$RGB_CUR_R" "$RGB_CUR_G" "$RGB_CUR_B")
		_MONORAIL_CURSOR="${ESC}]12;#${HEX_CURSOR_COLOR}${BEL}"
	}
else
	_COLORS() {
		:
	}

	_PROMPT_LUT() {
		_MONORAIL_LINE=""
		while [ "$I" -lt "$LINE_WIDTH" ]; do
			_MONORAIL_LINE="$_MONORAIL_LINE$_MONORAIL_LINE_SEGMENT"
			I=$((I + 1))
		done
		if [ "$_MONORAIL_VTXXX_TERMINAL" ]; then
			_MONORAIL_LINE="$ESC(0$_MONORAIL_LINE$ESC(B$ESC[7m$_MONORAIL_TEXT"
		else
			_MONORAIL_LINE="$_MONORAIL_LINE
$_MONORAIL_TEXT"
		fi
	}
fi

_MONORAIL_UPDATE() {
	if [ "$_MONORAIL_UPDATING" ]; then
		return
	fi
	_MONORAIL_UPDATING=1

	# COLUMNS does not update on 'busybox sh'

	# get COLUMNS if unset
	COLUMNS=$(stty size 2>/dev/null | cut -d" " -f2)
	LINES=$(stty size 2>/dev/null | cut -d" " -f1)
	# if `stty size` do not report valid size, default to 80x24
	if [ -z "$COLUMNS" ] || [ "$COLUMNS" = 0 ]; then
		COLUMNS=80
		LINES=24
	fi
	export COLUMNS
	export LINES
	_MONORAIL_COLORS=""

	_MONORAIL_GIT_PS1=$(
		TERM=dumb GIT_CONFIG_GLOBAL="" LC_MESSAGES=C LC_ALL=C __git_ps1 ""
	)
	# some shells do not set PWD
	PWD=$(pwd)
	_MONORAIL_PWD_BASENAME=$(basename "$PWD")
	[ -z "$PWD_BASENAME" ] && PWD_BASENAME=/
	case $PWD in
	"$HOME") _MONORAIL_PWD_BASENAME="~" ;;
	esac
	if [ "$HOME" = "$PWD" ]; then
		TITLE=$_MONORAIL_SHORT_HOSTNAME
	else
		TITLE=$_MONORAIL_PWD_BASENAME
	fi
	if [ "$_MONORAIL_XTERM_TERMINAL" ]; then
		_MONORAIL_TITLE="${ESC}]0;$TITLE$BEL${CR}"
	fi

	_MONORAIL_TEXT=" $_MONORAIL_PWD_BASENAME$_MONORAIL_GIT_PS1 "
	I=0
	# cannot draw the end column in some terminals
	LINE_WIDTH=$((COLUMNS - _MONORAIL_OFFSET))
	_MONORAIL_LINE=
	if [ "$_MONORAIL_XTERM_TERMINAL" ]; then
		_MONORAIL_LINE="$CR${ESC}[0m"
	elif [ "$_MONORAIL_VTXXX_TERMINAL" ]; then
		_MONORAIL_LINE="${ESC}[0m${ESC}(0$CR"
	fi

	# shellcheck disable=SC2000 # ${#variable} gives wrong results here
	_MONORAIL_TEXT_LEN=$(echo "${_MONORAIL_TEXT}" | wc -c)
	if [ ${_MONORAIL_TEXT_LEN} -gt $((COLUMNS / 3)) ]; then

		# posix sh does not support the unicode elipsis char
		_MONORAIL_TEXT=" ..."$(echo "${_MONORAIL_TEXT}" | cut -c$(($_MONORAIL_TEXT_LEN - $((COLUMNS / 3)) - 1))-${_MONORAIL_TEXT_LEN})
		_MONORAIL_TEXT_LEN=$(echo "${_MONORAIL_TEXT}" | wc -c)
	fi

if [ -e "$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".sh ];then
	# shellcheck disable=SC1090 # file will be available
	. "$_MONORAIL_CONFIG"/colors-"$_MONORAIL_SHORT_HOSTNAME".sh
else
_PROMPT_TEXT_LUT
_PROMPT_LUT
_COLORS
fi
	if [ "$_MONORAIL_XTERM_TERMINAL" ]; then
		_MONORAIL_LINE="$_MONORAIL_LINE$ESC(1"
	elif [ "$_MONORAIL_VTXXX_TERMINAL" ]; then
		_MONORAIL_LINE="$_MONORAIL_LINE$ESC(B${ESC}[7m"
	fi
	if [ "$_MONORAIL_ANSI_TERMINAL" ]; then
		PADDED__MONORAIL_TEXT_LEN=$((_MONORAIL_TEXT_LEN - 3))

		# shellcheck disable=SC1078,SC1079 # deliberate newline needed for line calculation
		CURSOR_POSITION_FIXUP="${ESC}[A
${ESC}["$(printf "%0${PADDED__MONORAIL_TEXT_LEN}d" "$_MONORAIL_TEXT_LEN")C
	fi
	PS1="$_MONORAIL_COLORS$_MONORAIL_TITLE$_MONORAIL_CURSOR$_MONORAIL_LINE$_MONORAIL_NORMAL $CURSOR_POSITION_FIXUP"
	# shellcheck disable=SC2329 # this function may be invoked
	cd() {
		# need to set/unset 'cd()' since not all shell have `builtin`
		unset -f cd 2>/dev/null
		if [ "$1" ]; then
			cd "$@" || return $?
		else
			cd "$HOME" || return $?
		fi
		_MONORAIL_UPDATE
	}
	unalias git 2>/dev/null
	# shellcheck disable=SC2329 # this function may be invoked
	_MONORAIL_GIT() {
		# need to set/unset 'git()' since not all shell have `builtin`
		unset -f git 2>/dev/null
		if [ "$1" ]; then
			$_MONORAIL_GIT_BIN "$@" || return $?
		else
			$_MONORAIL_GIT_BIN || return $?
		fi
		_MONORAIL_UPDATE
	}
	git() {
		_MONORAIL_GIT "$@"
	}
	unset _MONORAIL_UPDATING
}

# __git_ps1 posix sh compatible with version shipped in git
__git_ps1() {
	__GIT_PS1_REV=$(basename "$($_MONORAIL_GIT_BIN symbolic-ref HEAD 2>/dev/null)")
	if [ "$__GIT_PS1_REV" ]; then
		echo " ($__GIT_PS1_REV)"
	else
		__GIT_PS1_REV=$("$_MONORAIL_GIT_BIN" rev-parse HEAD 2>/dev/null | cut -c1-7)
		if [ "$__GIT_PS1_REV" ]; then
			echo " ((${__GIT_PS1_REV}...))"
		fi
	fi
	return 0
}

_ICON() {
	ICON="$1"
	shift
	case "$_MONORAIL_LANG" in *.UTF-8)
		# shellcheck disable=SC2086 # shellcheck incorrectly misses qoutes
		_TITLE "$ICON  $(basename \"$1\")"
		;;
	*)
		# shellcheck disable=SC2086 # shellcheck incorrectly misses qoutes
		_TITLE "$(basename \"$1\")"
		;;
	esac
	"$@"
}
if [ "$BASH_VERSION" ] || [ "$ZSH_VERSION" ]; then
	_MONORAIL_GIT_BIN=$(type -P git)
else
	_MONORAIL_GIT_BIN=$(which git)
fi
# update monorail on window resizing
trap "_MONORAIL_UPDATE" WINCH
kill -s WINCH $$
unalias monorail_color 2>/dev/null
monorail_color() {
	# shellcheck disable=SC2097,SC2098 # don't export variables only needed for monorail
	_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR "$0" "$_MONORAIL_DIR/scripts/color.sh"
}
unalias monorail_gradient 2>/dev/null
monorail_gradient() {
	# shellcheck disable=SC2097,SC2098 # don't export variables only needed for monorail
	_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR "$0" "$_MONORAIL_DIR/scripts/gradient.sh"
}
unalias monorail_image 2>/dev/null
monorail_image() {
	# shellcheck disable=SC2097,SC2098 # don't export variables only needed for monorail
	_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR "$0" "$_MONORAIL_DIR/scripts/image.sh"
}
unalias rgb 2>/dev/null
rgb() {
	"$0" "$_MONORAIL_DIR/scripts/rgb.sh"
}
unalias monorail_rgb 2>/dev/null
monorail_rgb() {
	"$0" "$_MONORAIL_DIR/scripts/rgb.sh"
}

if [ "$_MONORAIL_XTERM_TERMINAL" ]; then
	_TITLE() {
		# /dev/tty bypasses stdout/stdin so redirection is not disturbed
		printf "$ESC]0;%s$BEL" "$*" >/dev/tty 2>/dev/null
	}
else
	_TITLE() { :; }
fi
if [ "$ZSH_NAME" ]; then
	precmd() {
		_MONORAIL_UPDATE
	}
elif [ "$BASH_VERSION" ]; then
	unset -f precmd preexec
	PROMPT_COMMAND="_MONORAIL_UPDATE"
fi
