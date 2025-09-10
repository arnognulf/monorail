#!/bin/sh
# Copyright (c) 2025 Thomas Eriksson
# SPDX-License-Identifier: BSD-3-Clause

# This file is written with the aim to be compatible with most terminals
# and posix shells

# Terminals tested:
# DEC VT100, VT52, VT05
# xterm
# Wyse 60
# Tek 40xx
# ADM-3a
# IBM 3270
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
CR=$(echo 0d | xxd -r -p)
ESC=$(echo 1b | xxd -r -p)
BEL=$(echo 07 | xxd -r -p)
# serial terminals do not set SIZE
[ -z "$COLUMNS" ] && COLUMNS=78
case "$TERM" in
"xterm"* | "alacritty"*)
	_MONORAIL_XTERM_TERMINAL=1
	# UTF-8 "Lower one eighth block"
	case "$LANG" in
	*.UTF-8) _MONORAIL_LINE_SEGMENT=$(echo E29681 | xxd -p -r) ;;
	*) _MONORAIL_LINE_SEGMENT=_ ;;
	esac
	;;
"vt"???)
	_MONORAIL_VTXXX_TERMINAL=1
	;;
"wyse60")
	_MONORAIL_REVERSE="$_MONORAIL_PREHIDE$(echo 1b4734 | xxd -p -r)$_MONORAIL_POSTHIDE"
	_MONORAIL_NORMAL="$_MONORAIL_PREHIDE$(echo 1b281b48031b47301b6344 | xxd -p -r)$_MONORAIL_POSTHIDE"
	bind 'set enable-bracketed-paste off'
	_MONORAIL_WYSE60_TERMINAL=1
	_MONORAIL_DUMB_TERMINAL=1
	;;
"tek"* | "ibm-327"* | "dp33"?? | "dumb" | "dm2500" | "adm3a" | "vt"??)
	bind 'set enable-bracketed-paste off'
	_MONORAIL_DUMB_TERMINAL=1
	_MONORAIL_NORMAL="!"
	;;
*)
	_MONORAIL_NORMAL="|"
	;;
esac
if [ "$_MONORAIL_XTERM_TERMINAL" ] || [ "$_MONORAIL_VTXXX_TERMINAL" ]; then
	# workaround for shellcheck and zsh parsers
	_MONORAIL_REVERSE="[7m$_MONORAIL_REVERSE"
	_MONORAIL_REVERSE="$_MONORAIL_PREHIDE$ESC$_MONORAIL_REVERSE"
	_MONORAIL_NORMAL="[0m$_MONORAIL_POSTHIDE"
	_MONORAIL_NORMAL="$_MONORAIL_PREHIDE$ESC$_MONORAIL_NORMAL"
fi
case "$TERM" in
"xterm"* | "alacritty"*)
	# UTF-8 "Lower one eighth block"
	case "$LANG" in
	*.UTF-8) _MONORAIL_LINE_SEGMENT=$(echo E29681 | xxd -p -r) ;;
	*) _MONORAIL_LINE_SEGMENT=_ ;;
	esac
	;;
"vt"???)
	# See DEC Special graphics (https://en.wikipedia.org/wiki/DEC_Special_Graphics)
	_MONORAIL_LINE_SEGMENT=s
	;;
"dm2500" | "dumb")
	# uppercase only terminals have no underscore character
	_MONORAIL_LINE_SEGMENT=-
	;;
*)
	_MONORAIL_LINE_SEGMENT=_
	;;
esac
if [ -n "$ZSH_NAME" ]; then
	setopt prompt_subst
	_MONORAIL_PREHIDE='%{'
	_MONORAIL_POSTHIDE='%}'
elif [ -n "$BASH_VERSION" ] || [ -n "$OKSH_VERSION" ]; then
	_MONORAIL_PREHIDE='\['
	_MONORAIL_POSTHIDE='\]'
fi
[ -f /usr/lib/git-core/git-sh-prompt ] && . /usr/lib/git-core/git-sh-prompt 2>/dev/null
_MONORAIL_UPDATE() {
	_MONORAIL_GIT_PS1=$(
		TERM=dumb GIT_CONFIG_GLOBAL="" LC_MESSAGES=C LC_ALL=C __git_ps1 ""
	)
	# some shells do not set PWD
	PWD=$(pwd)
	PWD_BASENAME=$(basename "$PWD")
	[ -z "$PWD_BASENAME" ] && PWD_BASENAME=/
	case $PWD in
	"$HOME") _MONORAIL_PWD_BASENAME="~" ;;
	*) _MONORAIL_PWD_BASENAME="${NAME-$PWD_BASENAME}" ;;
	esac

	_MONORAIL_TEXT=" $_MONORAIL_PWD_BASENAME$_MONORAIL_GIT_PS1 "
	I=0
	LINE_WIDTH=$COLUMNS
	_MONORAIL_LINE=

	if [ -n "$_MONORAIL_VTXXX_TERMINAL" ]; then
		# double width line in VTXXX terminals for faster drawing
		# line needs to be broken due to zsh having issue parsing it
		# also shellcheck complains
		_MONORAIL_LINE="[0m$ESC#6$ESC(0"
		_MONORAIL_LINE="$CR$ESC$_MONORAIL_LINE"
		LINE_WIDTH=$((COLUMNS / 2))
	elif [ -n "$_MONORAIL_XTERM_TERMINAL" ]; then
		# line needs to be broken due to zsh having issue parsing it
		# also shellcheck complains
		_MONORAIL_LINE="[0m"
		_MONORAIL_LINE="$CR$ESC$_MONORAIL_LINE"
	elif [ -n "$_MONORAIL_DUMB_TERMINAL" ]; then
		# cannot draw the end column in some terminals
		LINE_WIDTH=$((COLUMNS - 2))
	else
		LINE_WIDTH=$COLUMNS
	fi

	while [ "$I" -lt "$LINE_WIDTH" ]; do
		_MONORAIL_LINE="$_MONORAIL_LINE$_MONORAIL_LINE_SEGMENT"
		I=$((I + 1))
	done

	if [ -n "$_MONORAIL_VTXXX_TERMINAL" ]; then
		# double width line in VTXXX terminals for faster drawing
		_MONORAIL_LINE="$_MONORAIL_LINE$ESC(1"
		LINE_WIDTH=$((COLUMNS / 2))
	elif [ -n "$_MONORAIL_XTERM_TERMINAL" ]; then
		_MONORAIL_LINE="$_MONORAIL_LINE$ESC(1"
	elif [ -n "$_MONORAIL_DUMB_TERMINAL" ]; then
		# cannot draw the end column in some terminals
		LINE_WIDTH=$((COLUMNS - 2))
	else
		LINE_WIDTH=$COLUMNS
	fi

	PS1="$_MONORAIL_LINE
$_MONORAIL_REVERSE$_MONORAIL_TEXT$_MONORAIL_NORMAL "
	# update the prompt when the user calls 'cd'
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
}
# update monorail on window resizing
trap "_MONORAIL_UPDATE" WINCH

# shellcheck disable=SC2329
__git_ps1() { :; }

_ICON() {
	ICON="$1"
	shift
	case "$LANG" in *.UTF-8)
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
if [ -n "$_MONORAIL_XTERM_TERMINAL" ]; then
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
elif [ -n "$BASH_VERSION" ]; then
	unset -f precmd preexec
	if [ -n "$PROMPT_COMMAND" ]; then
		PROMPT_COMMAND="$PROMPT_COMMAND;_MONORAIL_UPDATE"
	else
		PROMPT_COMMAND="_MONORAIL_UPDATE"
	fi
else
	_MONORAIL_UPDATE
fi
