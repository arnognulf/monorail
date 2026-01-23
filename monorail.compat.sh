#!/bin/sh
# Copyright (c) 2025 Thomas Eriksson
# SPDX-License-Identifier: BSD-3-Clause

# monorail.compat.sh is the fallback of monorail if using a non-supported terminal or a non-supported shell.
# monorail.compat.sh can also be used separately but will be slower than the full version.

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
{
	CR=$(printf '\015')
	ESC=$(printf '\033')
	BEL=$(printf '\007')

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
	case "$TERM" in
	"ansi" | "tek"* | "ibm-327"* | "dp33"?? | "dumb" | "wyse60" | "dm2500" | "adm3a" | "vt"* | "linux" | "xterm-color" | "xgterm" | "wsvt"* | "cons"* | "pc"* | "xterm-16color" | "screen."* | "Eterm" | "tty"* | "tn"* | "ti"*)
		# screen and linux vt accepts truecolor control sequencies, but do not display truecolor satisfactory
		# shellcheck disable=SC2086 # incomprehensible quoting suggestions from shellcheck
		case "$TERM" in
		tek* | vt52)
			_MONORAIL_DUMB_TERMINAL=1
			;;
		*)
			if [ -n "$XTERM_VERSION" ] && [ "$(echo \"$XTERM_VERSION\" | cut -d'(' -f2 | cut -d')' -f1)" -gt 330 ]; then
				_MONORAIL_TRUECOLOR_TERMINAL=1
			fi
			;;
		esac
		if [ "$TERM_PROGRAM" = "GNUstep_Terminal" ]; then
			_MONORAIL_XTERM_TERMINAL=1
		fi
		;;
	*)
		if [ "$COLORTERM" = "truecolor" ] || [ "$COLORTERM" = "24bit" ] || [ "$COLORTERM" = "rxvt-xpm" ]; then
			if [ "$TERM" != "linux" ]; then
				_MONORAIL_TRUECOLOR_TERMINAL=1
			fi
		fi
		;;
	esac
	_MONORAIL_SHORT_HOSTNAME=$(hostname | cut -d. -f1 | awk '{print tolower($0)}')
	if [ ! -f "$_MONORAIL_CONFIG"/colors-"$_MONORAIL_SHORT_HOSTNAME".sh ]; then
		cat "$_MONORAIL_DIR"/gradients/Default.sh "$_MONORAIL_DIR"/colors/Default.sh >"$_MONORAIL_CONFIG"/colors-"$_MONORAIL_SHORT_HOSTNAME".sh
	fi
	# get COLUMNS if unset
	COLUMNS=$(stty size 2>/dev/null | cut -d" " -f2)
	# if `stty size` do not report valid size, default to 80x24
	if [ -z "$COLUMNS" ] || [ "$COLUMNS" = 0 ]; then
		COLUMNS=80
		LINES=24
	fi
	export COLUMNS
	export LINES

	_MONORAIL_ELIPSIS="..."
	_MONORAIL_LINE_SEGMENT=_
	_MONORAIL_OFFSET=0

	case "$TERM" in
	"xterm-color")
		_MONORAIL_XTERM_TERMINAL=1
		;;
	"xterm"* | "tmux"* | "screen"* | "alacritty"* | "rio" | "rxvt-unicode"*)
		_MONORAIL_XTERM_TERMINAL=1
		# netbsd sets LC_CTYPE, Linux sets LANG
		if [ "$LANG" ]; then
			_MONORAIL_LANG=$LANG
		else
			_MONORAIL_LANG=$LC_CTYPE
		fi
		case "$_MONORAIL_LANG" in
		*.UTF-8)
			_MONORAIL_ELIPSIS=$(printf '\342\200\246')
			# UTF-8 "Lower one eighth block"
			_MONORAIL_LINE_SEGMENT=$(printf '\342\226\201')
			;;
		esac
		;;
	"Eterm" | "rxvt"*)
		_MONORAIL_XTERM_TERMINAL=1
		;;
		#    "ibm3151")
		#        rev=$(printf '\1b')$(printf '\34' 2161
		#    ;;
	"at386" | "hft" | "scoansi")
		bind 'set enable-bracketed-paste off'
		_MONORAIL_ANSI_TERMINAL=1
		_MONORAIL_OFFSET=1
		;;
	"aaa" | "sun" | "wy370")
		bind 'set enable-bracketed-paste off'
		_MONORAIL_ANSI_TERMINAL=1
		;;
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
	"ibm-327"* | "dp33"?? | "adm3a" | "vt"?? | "hp2621" | "hz1500" | "wy30" | "vc404" | "dg2"*)
		# dumb lowercase terminals
		bind 'set enable-bracketed-paste off'
		_MONORAIL_OFFSET=1
		_MONORAIL_DUMB_TERMINAL=1
		_MONORAIL_NORMAL="|"
		;;
	"wyse60" | "wy60" | "wy50" | "wy160")
		_MONORAIL_OFFSET=1
		_MONORAIL_REVERSE="$_MONORAIL_PREHIDE${ESC}G4$_MONORAIL_POSTHIDE"
		_MONORAIL_NORMAL="$_MONORAIL_PREHIDE${ESC}G0$_MONORAIL_POSTHIDE"
		bind 'set enable-bracketed-paste off'
		_MONORAIL_DUMB_TERMINAL=1
		;;
	*)
		_MONORAIL_NORMAL="|"
		;;
	esac
	if [ "$_MONORAIL_XTERM_TERMINAL" ] || [ "$_MONORAIL_ANSI_TERMINAL" ]; then
        # vscode does not support disabling line wrap
        if [ "$TERM_PROGRAM" != "vscode" ];then
            _MONORAIL_DISABLE_WRAP="${ESC}[?7l"
        fi
		_MONORAIL_REVERSE="$_MONORAIL_PREHIDE${_MONORAIL_DISABLE_WRAP}${ESC}[7m$_MONORAIL_POSTHIDE"
		_MONORAIL_REVERSE="$_MONORAIL_PREHIDE${ESC}[7m$_MONORAIL_POSTHIDE"
		_MONORAIL_NORMAL="$_MONORAIL_PREHIDE${ESC}[?25h${ESC}[?7h${ESC}[0m$_MONORAIL_POSTHIDE"
	fi

	if [ "$ZSH_NAME" ]; then
		setopt prompt_subst
		_MONORAIL_PREHIDE='%{'
		_MONORAIL_POSTHIDE='%}'
	elif [ "$BASH_VERSION" ] || [ "$OKSH_VERSION" ] || PATH='' freebsd_wordexp 2>/dev/null; then
		_MONORAIL_PREHIDE='\['
		_MONORAIL_POSTHIDE='\]'
	fi

	_MONORAIL_SHOW_GRADIENT_PROMPT() {
		if [ "$KSH_VERSION" ] ||
			[ "$BASH_VERSION" ] ||
			[ "$ZSH_VERSION" ]; then
			if [ "$_MONORAIL_TRUECOLOR_TERMINAL" ]; then
				# shellcheck disable=SC3054 # ksh
				if [ "${#_PROMPT_LUT[*]}" -gt 0 ]; then
					return 0
				fi
			fi
		fi
		return 1
	}
	_MONORAIL_GRADIENT_PROMPT() {
		# shellcheck disable=SC1090 # file will be available
		. "$_MONORAIL_CONFIG"/colors-"$_MONORAIL_SHORT_HOSTNAME".sh
		while [ "$I" -lt "$LINE_WIDTH" ]; do

			# the following warning is for using arrays in a file that is specified as
			# having posix shell syntax.
			# For this particular section we want 'ksh' syntax
			# shellcheck disable=SC3054 # ksh
			_MONORAIL_LINE="$_MONORAIL_LINE${ESC}[38;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]} * I / $((COLUMNS + 1))))]}m$_MONORAIL_LINE_SEGMENT"

			I=$((I + 1))
		done
		I=0
		unset _MONORAIL_TEXT_ARRAY
		while [ $I -lt "${#_MONORAIL_TEXT_ARRAY[*]}" ]; do
			_MONORAIL_TEXT_ARRAY[I]=""
			I=$((I + 1))
		done
		# shellcheck disable=SC3054
		[ -z "${_PROMPT_TEXT_LUT[*]}" ] && _PROMPT_TEXT_LUT[0]="255;255;255"
		if [ "$ZSH_NAME" ]; then
			I=0
			while [ $I -lt ${#_MONORAIL_TEXT} ]; do
				# shellcheck disable=SC3054 # ksh
				_MONORAIL_TEXT_ARRAY[I]="${_MONORAIL_TEXT[I]}"
				I=$((I + 1))
			done
		elif [ "$OKSH_VERSION" ]; then
			I=0
			while [ $I -lt "${#_MONORAIL_TEXT}" ]; do
				_MONORAIL_TEXT_ARRAY[I]=$(echo "$_MONORAIL_TEXT" | cut -c$((I + 1)))
				I=$((I + 1))
			done
		else
			I=0
			while [ $I -lt ${#_MONORAIL_TEXT} ]; do
				# shellcheck disable=SC3054,SC3057 # ksh, expect to be parsed by ksh93 or bash compatible
				_MONORAIL_TEXT_ARRAY[I]="${_MONORAIL_TEXT:I:1}"
				I=$((I + 1))
			done
		fi

		# shellcheck disable=SC3054 # ksh
		_MONORAIL_TEXT_ARRAY_LEN=${#_MONORAIL_TEXT_ARRAY[*]}
		I=0
		_MONORAIL_TEXT_FORMATTED=""
		while [ "$I" -lt "${_MONORAIL_TEXT_ARRAY_LEN}" ]; do
			LUT=$((${#_PROMPT_LUT[*]} * I / $((COLUMNS + 1))))
			TEXT_LUT=$((${#_PROMPT_TEXT_LUT[*]} * I / $((COLUMNS + 1))))
			# shellcheck disable=SC3054 # ksh
			_MONORAIL_TEXT_FORMATTED="$_MONORAIL_TEXT_FORMATTED$_MONORAIL_PREHIDE${ESC}[0m${ESC}[48;2;${_PROMPT_LUT[LUT]}m${ESC}[38;2;${_PROMPT_TEXT_LUT[TEXT_LUT]}m$_MONORAIL_POSTHIDE${_MONORAIL_TEXT_ARRAY[I]}"
			I=$((I + 1))
		done
		# shellcheck disable=SC3054 # ksh
		RGB_CUR_COLOR=${_PROMPT_LUT[$((${#_PROMPT_LUT[*]} * $((_MONORAIL_TEXT_ARRAY_LEN + 1)) / $((COLUMNS + 1))))]}
		RGB_CUR_R=$(echo "${RGB_CUR_COLOR}" | cut -d';' -f1)
		RGB_CUR_G=$(echo "${RGB_CUR_COLOR}" | cut -d';' -f2)
		RGB_CUR_B=$(echo "${RGB_CUR_COLOR}" | cut -d';' -f3)
		HEX_CURSOR_COLOR=$(printf "%.2x%.2x%.2x" "$RGB_CUR_R" "$RGB_CUR_G" "$RGB_CUR_B")
		# shellcheck disable=SC3054 # ksh
		[ ${#_PROMPT_LUT[*]} = 0 ] && HEX_CURSOR_COLOR="${_COLORS[21]}"
		_MONORAIL_CURSOR="${ESC}]12;#${HEX_CURSOR_COLOR}${BEL}"

	}
	_MONORAIL_UPDATE() {
		_MONORAIL_GIT_PS1=$(

			TERM=dumb GIT_CONFIG_GLOBAL="" LC_MESSAGES=C LC_ALL=C __git_ps1 "" | LC_ALL=C sed "s/\.\.\./$_MONORAIL_ELIPSIS/g"
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
			_MONORAIL_TITLE="${ESC}]0;$TITLE$BEL"
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
		# shellcheck disable=SC1090 # file will be available
		. "$_MONORAIL_CONFIG"/colors-"$_MONORAIL_SHORT_HOSTNAME".sh
		if _MONORAIL_SHOW_GRADIENT_PROMPT; then
			_MONORAIL_GRADIENT_PROMPT
		else
			while [ "$I" -lt "$LINE_WIDTH" ]; do
				_MONORAIL_LINE="$_MONORAIL_LINE$_MONORAIL_LINE_SEGMENT"
				I=$((I + 1))
			done
			_MONORAIL_TEXT_FORMATTED="$_MONORAIL_TEXT"
		fi
		if [ "$_MONORAIL_XTERM_TERMINAL" ]; then
			_MONORAIL_LINE="$_MONORAIL_LINE$ESC(1"
		elif [ "$_MONORAIL_VTXXX_TERMINAL" ]; then
			_MONORAIL_LINE="$_MONORAIL_LINE$ESC(B${ESC}[7m"
		fi

		PS1="$_MONORAIL_TITLE$_MONORAIL_CURSOR$_MONORAIL_LINE
$_MONORAIL_REVERSE$_MONORAIL_TEXT_FORMATTED$_MONORAIL_NORMAL "
		# update the prompt when the user calls 'cd'
		if [ "$KSH_VERSION" ] || [ "$ZSH_NAME" ] || [ "$BASH_VERSION" ]; then
			:
		else
			# shellcheck disable=SC2329 # this function may be invoked
			cd() {
				# need to set/unset 'cd()' since not all shell have `builtin`
				unset -f cd 2>/dev/null
				if [ "$1" ]; then
					cd "$1" || return $?
				else
					cd "$HOME" || return $?
				fi
				_MONORAIL_UPDATE
			}
			# shellcheck disable=SC2329 # this function may be invoked
			git() {
				# need to set/unset 'git()' since not all shell have `builtin`
				unset -f cd 2>/dev/null
				if [ "$1" ]; then
					git "$1" || return $?
				else
					git "$HOME" || return $?
				fi
				_MONORAIL_UPDATE
			}
		fi

	}
	# update monorail on window resizing
	trap "_MONORAIL_UPDATE" WINCH

	# __git_ps1 ksh compatible with version shipped in git
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
	if [ "$KSH_VERSION" ] || [ "$ZSH_NAME" ] || [ "$BASH_VERSION" ]; then
		_MONORAIL_CD() {
			cd "$@" || return $?
			_MONORAIL_UPDATE
		}
		alias cd=_MONORAIL_CD
		_MONORAIL_GIT_BIN=$(which git)
		_MONORAIL_GIT() {
			"$_MONORAIL_GIT_BIN" "$@" || return $?
			_MONORAIL_UPDATE
		}
		alias git=_MONORAIL_GIT
		# shellcheck disable=SC2139
		alias monorail_color="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR ""$0"" $_MONORAIL_DIR/scripts/color.sh"
		# shellcheck disable=SC2139
		alias monorail_gradient="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR ""$0"" $_MONORAIL_DIR/scripts/gradient.sh"
		# shellcheck disable=SC2139
		alias monorail_image="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR ""$0"" $_MONORAIL_DIR/scripts/image.sh"
		# shellcheck disable=SC2139
		alias monorail_textgradient="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR ""$0"" $_MONORAIL_DIR/scripts/gradient.sh --text"
		# shellcheck disable=SC2139
		alias monorail_rgb="$0"" $_MONORAIL_DIR/scripts/rgb.sh"
		# shellcheck disable=SC2139
		alias rgb="ksh $_MONORAIL_DIR/scripts/rgb.sh"
		# shellcheck disable=SC2139
		alias monorail_save="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR ksh $_MONORAIL_DIR/scripts/save.sh"

	fi
	kill -s WINCH $$

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
}
