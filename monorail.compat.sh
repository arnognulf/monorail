#!/bin/sh
# Copyright (c) 2025 Thomas Eriksson
# SPDX-License-Identifier: BSD-3-Clause

# monorail.compat.sh is the fallback of monorail if using a non-supported terminal or a non-supported shell.

CR=$(printf '\015')
ESC=$(printf '\033')
BEL=$(printf '\007')
# use the 'Unit Separator' as a dummy intermediate 1 byte character that
# later will be translated to a 3 byte UTF-8 elipsis
US=$(printf '\037')
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
_MONORAIL_ELIPSIS="..."
_MONORAIL_OFFSET=0

# shellcheck disable=SC2153 # KSH_VERSION is spelled correctly
case $KSH_VERSION in
"Version "*93*)
	# ksh93u+m tries to parse control sequences itself, so skip the fixup code
	_MONORAIL_KSH93=1
	;;
esac
I=0
for SIZE in $(stty size); do
	if [ "$I" = 0 ]; then
		LINES=$SIZE
	else
		COLUMNS=$SIZE
	fi
	I=$((I + 1))
done
# if `stty size` do not report valid size, default to 80x24
if [ -z "$COLUMNS" ] || [ "$COLUMNS" = 0 ]; then
	COLUMNS=80
	LINES=24
fi
export COLUMNS
export LINES

case "$TERM" in
"vt"???)
	[ "$BASH_VERSION" ] && bind 'set enable-bracketed-paste off'
	_MONORAIL_ANSI_TERMINAL=1

	# vt100 or vt220 emulators normally do not support DEC alternate graphics
	# which is used to draw the horizontal line but sets "vt100" or "vt220"
	# as TERM for compatibility.
	# detect these terminals by checking if they have supported sizes
	if [ "$COLUMNS" = 80 ] || [ "$COLUMNS" = 132 ]; then
		if [ "$LINES" = 24 ] || [ "$LINES" = 14 ]; then
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
	[ "$BASH_VERSION" ] && bind 'set enable-bracketed-paste off'
	_MONORAIL_DUMB_TERMINAL=1
	;;
"dm2500" | "dumb" | "vt50")
	# uppercase only terminals have no underscore character
	[ "$BASH_VERSION" ] && bind 'set enable-bracketed-paste off'
	_MONORAIL_DUMB_TERMINAL=1
	_MONORAIL_LINE_SEGMENT=-
	_MONORAIL_NORMAL="!"
	_MONORAIL_OFFSET=1
	;;
"tek"*)
	# dumb lowercase terminals
	[ "$BASH_VERSION" ] && bind 'set enable-bracketed-paste off'
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
	[ "$BASH_VERSION" ] && bind 'set enable-bracketed-paste off'
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
	[ "$BASH_VERSION" ] && bind 'set enable-bracketed-paste off'
	_MONORAIL_ANSI_TERMINAL=1
	_MONORAIL_OFFSET=1
	;;
"aaa" | "sun" | "wy370")
	[ "$BASH_VERSION" ] && bind 'set enable-bracketed-paste off'
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
	case $COLORTERM in
	"" | "truecolor" | "24bit" | "rxvt-xpm")
		if [ "$TERM" != "linux" ]; then
			_MONORAIL_TRUECOLOR_TERMINAL=1
		fi
		;;
	esac
	case "$_MONORAIL_LANG" in
	*.UTF-8)
		# UTF-8 "Lower one eighth block"
		_MONORAIL_LINE_SEGMENT=$(printf '\342\226\201')
		_MONORAIL_ELIPSIS=$(printf '\xe2\x80\xa6')
		:
		;;
	esac
	;;
esac

# freebsd 15 sh(1) have some bugs which causes shell to segfault/block on amd64
if [ "$(command -v freebsd_wordexp 2>/dev/null)" = "freebsd_wordexp" ]; then
	_MONORAIL_DUMB_TERMINAL=1
	_MONORAIL_NORMAL="|"
	_MONORAIL_OFFSET=1
	_MONORAIL_LANG=""
	unset _MONORAIL_XTERM_TERMINAL
	unset _MONORAIL_ANSI_TERMINAL
	unset _MONORAIL_TRUECOLOR_TERMINAL
	_MONORAIL_LINE_SEGMENT=_
	_MONORAIL_ELIPSIS=...

fi
_MONORAIL_SHORT_HOSTNAME=$(hostname | cut -d. -f1 | awk '{print tolower($0)}')
if [ ! -f "$_MONORAIL_CONFIG"/colors-"$_MONORAIL_SHORT_HOSTNAME".sh ]; then
	mkdir -p "$_MONORAIL_CONFIG"
	cat "$_MONORAIL_DIR"/gradients/Default.sh "$_MONORAIL_DIR"/colors/Default.sh >"$_MONORAIL_CONFIG"/colors-"$_MONORAIL_SHORT_HOSTNAME".sh
fi
if [ "$_MONORAIL_XTERM_TERMINAL" ] || [ "$_MONORAIL_ANSI_TERMINAL" ]; then
	# vscode does not support disabling line wrap
	if [ "$TERM_PROGRAM" != "vscode" ]; then
		_MONORAIL_DISABLE_WRAP="${ESC}[?7l"
	fi
	_MONORAIL_REVERSE="${ESC}[7m"
	_MONORAIL_NORMAL="${ESC}[?25h${ESC}[?7h${ESC}[0m"
fi

if [ "$ZSH_NAME" ]; then
	setopt prompt_subst
fi

if [ "$_MONORAIL_TRUECOLOR_TERMINAL" ]; then

	# shellcheck disable=SC2120 # callback function, arguments passed in separate file
	_COLORS() {
		# 0-15   `0`-`f` (hex) = ansi color
		# 16     `g`           = foreground
		# 17     `h`           = background
		# 18     `i`           = bold color
		# 19     `j`           = selection color
		# 20     `k`           = selected text color
		# 2     `l`           = cursor
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
	# shellcheck disable=SC2120 # callback function, arguments passed in separate file
	_PROMPT_TEXT_LUT() {
		_PROMPT_TEXT_LUT=$1
	}
	# shellcheck disable=SC2120 # callback function, arguments passed in separate file
	_PROMPT_LUT() {
		LUT_SIZE=0
		# shellcheck disable=SC2034 # variable IGNORED is not used, I do not know a better way to count args in posix sh
		for IGNORED in "$@"; do
			LUT_SIZE=$((LUT_SIZE + 1))
		done
		if [ -z "$_PROMPT_TEXT_LUT" ]; then
			_PROMPT_TEXT_LUT="255;255;255"
		fi
		_MONORAIL_TEXT_LINE=""
		_MONORAIL_LINE=""
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
			# ksh93 tries to parse the control sequences itself,
			# unfortunately, ksh93u+m 1.0.10 does not parse all
			# control sequences correctly, this means that when the
			# prompt string is 1/3 of the screen and the text wraps
			# around: it cannot be unwrapped to previous line with
			# backspace.
			# Disabling gradient of the bar is the unfortunate
			# workaround here.
			if [ "$_MONORAIL_KSH93" ] && [ "$I" = "${_MONORAIL_TEXT_LEN}" ]; then
				_MONORAIL_TEXT_LINE_INIT="${ESC}[48;2;${1}m"
				_MONORAIL_TEXT_LINE="$_MONORAIL_TEXT"
			elif [ -z "$_MONORAIL_KSH93" ] && [ "$I" -lt "$((_MONORAIL_TEXT_LEN - 1))" ]; then
				_MONORAIL_TEXT_LINE="$_MONORAIL_TEXT_LINE${ESC}[48;2;${1}m"$(printf "%s" "$_MONORAIL_TEXT" | cut -c$((I + 1)))
			fi
			I=$((I + 1))
		done
		case "$_MONORAIL_LANG" in
		*.UTF-8)
			_MONORAIL_TEXT_LINE=$(printf "%s" "$_MONORAIL_TEXT_LINE" | LC_ALL=C sed "s/$US/$_MONORAIL_ELIPSIS/g")
			;;
		esac
		_MONORAIL_LINE="$_MONORAIL_LINE${ESC}[38;2;${_PROMPT_TEXT_LUT}m
${_MONORAIL_TEXT_LINE_INIT}$_MONORAIL_TEXT_LINE"

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
	_PROMPT_TEXT_LUT() {
		:
	}

	_PROMPT_LUT() {
		_MONORAIL_LINE=""
		while [ "$I" -lt "$LINE_WIDTH" ]; do
			_MONORAIL_LINE="$_MONORAIL_LINE$_MONORAIL_LINE_SEGMENT"
			I=$((I + 1))
		done
		if [ "$_MONORAIL_VTXXX_TERMINAL" ]; then
			_MONORAIL_LINE="$ESC(0$_MONORAIL_LINE${ESC}(B$_MONORAIL_REVERSE$_MONORAIL_TEXT"
		elif [ "$_MONORAIL_ANSI_TERMINAL" ]; then
			_MONORAIL_LINE="$_MONORAIL_LINE$_MONORAIL_REVERSE$_MONORAIL_TEXT"
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
	I=0
	for SIZE in $(stty size); do
		if [ "$I" = 0 ]; then
			LINES=$SIZE
		else
			COLUMNS=$SIZE
		fi
		I=$((I + 1))
	done
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

	# freebsd `wc` adds some cosmetic spacing that needs to be removed here
	# shellcheck disable=SC2000 # ${#variable} gives wrong results here
	_MONORAIL_TEXT_LEN=$(echo "${_MONORAIL_TEXT}" | wc -c | tr -d ' ')
	if [ "${_MONORAIL_TEXT_LEN}" -gt $((COLUMNS / 3)) ]; then

		# posix sh does not support the unicode elipsis char
		case "$_MONORAIL_LANG" in
		*.UTF-8)
			_MONORAIL_TEXT=" $US"$(echo "${_MONORAIL_TEXT}" | cut -c$((_MONORAIL_TEXT_LEN - $((COLUMNS / 3)) + 1))-"$_MONORAIL_TEXT_LEN")
			;;
		*)
			_MONORAIL_TEXT=" $_MONORAIL_ELIPSIS"$(echo "${_MONORAIL_TEXT}" | cut -c$((_MONORAIL_TEXT_LEN - $((COLUMNS / 3)) + 1))-"$_MONORAIL_TEXT_LEN")
			;;
		esac
		# shellcheck disable=SC2000 # ${#variable} gives wrong results here
		_MONORAIL_TEXT_LEN=$(echo "${_MONORAIL_TEXT}" | wc -c | tr -d ' ')
	fi

	if [ -e "$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".sh ]; then
		# shellcheck disable=SC1090 # file will be available
		. "$_MONORAIL_CONFIG"/colors-"$_MONORAIL_SHORT_HOSTNAME".sh
	else
		# shellcheck disable=SC2119 # called without arguments
		_PROMPT_TEXT_LUT
		# shellcheck disable=SC2119 # called without arguments
		_PROMPT_LUT
		# shellcheck disable=SC2119 # called without arguments
		_COLORS
	fi
	if [ "$_MONORAIL_XTERM_TERMINAL" ]; then
		_MONORAIL_LINE="$_MONORAIL_LINE$ESC(1"
	elif [ "$_MONORAIL_VTXXX_TERMINAL" ]; then
		_MONORAIL_LINE="$_MONORAIL_LINE$ESC(B$_MONORAIL_REVERSE"
	fi
	if [ "$_MONORAIL_KSH93" ]; then
		# ksh93u+m tries to parse control sequences itself, so skip the fixup code
		:
	elif [ "$_MONORAIL_ANSI_TERMINAL" ]; then
		# shellcheck disable=SC1078,SC1079 # deliberate newline needed for line calculation
		CURSOR_POSITION_FIXUP="${ESC}[A
${ESC}["$(printf "%0$((_MONORAIL_TEXT_LEN - 3))d" "$_MONORAIL_TEXT_LEN")C
	fi
	PS1="$_MONORAIL_COLORS$_MONORAIL_TITLE$_MONORAIL_CURSOR$_MONORAIL_LINE$_MONORAIL_NORMAL $CURSOR_POSITION_FIXUP"
	# shellcheck disable=SC2262 # cd needs to be aliased for ksh/bash/zsh
	if alias cd=_MONORAIL_CD >/dev/null 2>/dev/null; then
		# shellcheck disable=SC2329 # function is for interactive use
		_MONORAIL_CD() {
			unalias cd
			if [ "$1" ]; then
				# shellcheck disable=SC2164 # need to run _MONORAIL_UPDATE even if `cd` fails
				cd "$@"
				STATUS=$?
			else
				# shellcheck disable=SC2164 # need to run _MONORAIL_UPDATE even if `cd` fails
				cd "$HOME"
				STATUS=$?
			fi
			_MONORAIL_UPDATE
			return "$STATUS"
		}
	else
		# shellcheck disable=SC2329 # function is for interactive use
		cd() {
			# need to set/unset 'cd()' since not all shell have `builtin`
			unset -f cd 2>/dev/null
			if [ "$1" ]; then
				# shellcheck disable=SC2164 # need to run _MONORAIL_UPDATE even if `cd` fails
				cd "$@"
				STATUS=$?
			else
				# shellcheck disable=SC2164 # need to run _MONORAIL_UPDATE even if `cd` fails
				cd "$HOME"
				STATUS=$?
			fi
			_MONORAIL_UPDATE
			return "$STATUS"
		}
	fi
	unset _MONORAIL_UPDATING
}
unalias git 2>/dev/null
# shellcheck disable=SC2329 # function is for interactive use
git() {
	$(
		unset -f git >/dev/null 2>/dev/null
		unalias git >/dev/null 2>/dev/null
		command -v git
	) "$@"
	STATUS=$?
	_MONORAIL_UPDATE
	return $STATUS
}

# __git_ps1 posix sh compatible with version shipped in git
__git_ps1() {
	__GIT_PS1_REV=$(basename "$($(
		unset -f git >/dev/null 2>/dev/null
		unalias git >/dev/null 2>/dev/null
		command -v git
	) symbolic-ref HEAD 2>/dev/null)")
	if [ "$__GIT_PS1_REV" ]; then
		echo " ($__GIT_PS1_REV)"
	else
		__GIT_PS1_REV=$($(
			unset -f git >/dev/null 2>/dev/null
			unalias git >/dev/null 2>/dev/null
			command -v git
		) rev-parse HEAD 2>/dev/null | cut -c1-7)
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
