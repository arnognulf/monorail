#!/bin/bash
# Copyright (c) 2025 Thomas Eriksson
# SPDX-License-Identifier: BSD-3-Clause
{
if ! [[ $_MONORAIL_DIR ]];then
if [[ ${BASH_ARGV[0]} != "/"* ]];then
_MONORAIL_DIR=$PWD/${BASH_ARGV[0]}
else
_MONORAIL_DIR="${BASH_ARGV[0]}"
fi
_MONORAIL_DIR="${_MONORAIL_DIR%/*}"
fi
_MONORAIL_SHORT_HOSTNAME=${HOSTNAME%%.*}
if [[ $ZSH_NAME ]];then
setopt KSH_ARRAYS
setopt prompt_subst
_MONORAIL_PREHIDE='%{'
_MONORAIL_POSTHIDE='%}'
_MONORAIL_SHORT_HOSTNAME=$_MONORAIL_SHORT_HOSTNAME:l
else
_MONORAIL_SHORT_HOSTNAME=${_MONORAIL_SHORT_HOSTNAME,,}
_MONORAIL_PREHIDE='\['
_MONORAIL_POSTHIDE='\]'
fi
preexec(){
{
# TODO: report and move to bash-preexec: SIGWINCH causes preexec to run again
[[ $(fc -l -1) == "$_MONORAIL_PREV_CMD" ]] && return
_MONORAIL_PREV_CMD=$(fc -l -1)
local CMD
CMD=${_TIMER_CMD%% *}
CMD=${CMD%%;*}
_MEASURE=1
_START_SECONDS=$SECONDS
# zsh cannot have closed fd's here
} &>/dev/null
}
_MONORAIL_STOP_TIMER(){
{
LC_MESSAGES=C LC_ALL=C stty echo 2>&-
local SECONDS_M DURATION_H DURATION_M DURATION_S CURRENT_SECONDS DURATION DIFF
CURRENT_SECONDS=$SECONDS
DIFF=$((CURRENT_SECONDS-_START_SECONDS))
if [[ $_MEASURE ]]&&[[ $DIFF -gt ${_MONORAIL_TIMEOUT-29} ]];then
SECONDS_M=$((DIFF%3600))
DURATION_H=$((DIFF/3600))
DURATION_M=$((SECONDS_M/60))
DURATION_S=$((SECONDS_M%60))
\printf "\n\aCommand took "
DURATION=
[ $DURATION_H -gt 0 ]&&DURATION="${DURATION_H}h "
[ $DURATION_M -gt 0 ]&&DURATION+="${DURATION_M}m "
DURATION+="${DURATION_S}s, finished at "$(LC_MESSAGES=C LC_ALL=C date +%H:%M).
\echo "$DURATION"
_MONORAIL_ALERT
_MONORAIL_LONGRUNNING=1
fi
unset _MEASURE
} 2>&-
}
if [[ $XDG_CONFIG_HOME ]];then
_MONORAIL_CONFIG="$XDG_CONFIG_HOME/monorail"
else
_MONORAIL_CONFIG="$HOME/.config/monorail"
fi
precmd(){
if [[ $_MONORAIL_LAUNCHED ]];then
_MONORAIL_STOP_TIMER
_MONORAIL_COMMAND
else
_MONORAIL_LAUNCHED=1
fi
local _MONORAIL_REALPWD
_MONORAIL_REALPWD="$PWD"
case "$PWD" in
/run/user/*/gvfs/*)_MONORAIL_GIT_PS1=;;
*)
if [[ -z $_MONORAIL_GIT_LOADED ]];then
local DIR
DIR="$PWD"
while [[ $DIR ]];do
if [[ -e "$DIR/.git" ]]&&[[ -e /usr/lib/git-core/git-sh-prompt ]];then
. /usr/lib/git-core/git-sh-prompt
_MONORAIL_GIT_LOADED=1
fi
DIR=${DIR%/*}
done
fi
_MONORAIL_GIT_PS1=$(TERM=dumb GIT_CONFIG_GLOBAL="" LC_MESSAGES=C LC_ALL=C __git_ps1 "")
esac
local PWD_BASENAME="${PWD##*/}"
[ -z "$PWD_BASENAME" ]&&PWD_BASENAME=/
case $PWD in
"$HOME")_MONORAIL_PWD_BASENAME="~";;
*)_MONORAIL_PWD_BASENAME="${NAME-$PWD_BASENAME}"
esac
_MONORAIL_TEXT=" $_MONORAIL_PWD_BASENAME$_MONORAIL_GIT_PS1 "
local CHAR
if [[ $_MONORAIL_CACHE != "$COLUMNS" ]];then
unset _MONORAIL_DATE _MONORAIL_CACHE _MEASURE
if [[ $TERM == "dm2500" ]]||[[ $TERM == "dumb" ]];then
CHAR=-
else
CHAR=_
fi
local I=0
local TEMP_COLUMNS=$COLUMNS
_MONORAIL_LINE=
if [[ $_MONORAIL_VTXXX_TERMINAL ]];then
_MONORAIL_LINE=$'\e'"[0;1m"$'\e'"#6"$'\e'"(0"
while [[ $I -lt $((TEMP_COLUMNS / 2)) ]];do
_MONORAIL_LINE+="s"
I=$((I+1))
done
else
[[ $_MONORAIL_DUMB_TERMINAL ]] &&TEMP_COLUMNS=$((COLUMNS-2))
while [ $I -lt $TEMP_COLUMNS ];do
_MONORAIL_LINE+="$CHAR"
I=$((I+1))
done
fi
_MONORAIL_TEXT_FORMATTED=
_MONORAIL_CACHE="$COLUMNS"
fi
if [[ $_MONORAIL_VTXXX_TERMINAL ]]; then
# shellcheck disable=SC2025,SC1078,SC1079 # no need to enclose in \[ \] as cursor position is calculated from after newline, quoting is supposed to span multiple lines
PS1=$'\r'$'\e'"[0m$_MONORAIL_LINE"$'\e'"[0;7m"$'\e'"(1
$_MONORAIL_TEXT$_MONORAIL_PREHIDE"$'\e'"[0m"$'\e'"[?25h$_MONORAIL_POSTHIDE "
else
local REVERSE NORMAL
REVERSE=$(LC_MESSAGES=C LC_ALL=C tput rev 2>&-)
if [[ "$REVERSE" ]];then
NORMAL="$_MONORAIL_PREHIDE$(LC_MESSAGES=C LC_ALL=C tput sgr0 2>&-)$_MONORAIL_POSTHIDE"
REVERSE="$_MONORAIL_PREHIDE$REVERSE$_MONORAIL_POSTHIDE"
elif [[ $TERM == "dumb" ]];then
REVERSE=
NORMAL="!"
else
REVERSE=
NORMAL="|"
fi
PS1=$_MONORAIL_LINE"
$REVERSE$_MONORAIL_TEXT$NORMAL "
fi
unset _MONORAIL_NOSTYLING
}
_NO_MEASURE(){
unset _MEASURE
"$@"
}
_ICON(){
trap "unset _MONORAIL_CACHE" WINCH
_LOW_PRIO(){
if type -P chrt >/dev/null 2>&-;then
_LOW_PRIO(){
ionice -c idle chrt -i 0 "$@"
}
else
_LOW_PRIO(){
nice -n19 "$@"
}
fi
_LOW_PRIO "$@"
}
# shellcheck disable=SC2329
_INTERACTIVE_COMMAND(){
# shellcheck disable=SC2139 # variable is intended to be set when defined
command -v "$2"&&alias "$2=_NO_MEASURE _ICON $1 $2"
}
# shellcheck disable=SC2329
_BATCH_COMMAND(){
# shellcheck disable=SC2139
command -v "$2"&&alias "$2=_ICON $1 _LOW_PRIO $2"
}
alias interactive_command=_INTERACTIVE_COMMAND
alias batch_command=_BATCH_COMMAND
. "$_MONORAIL_DIR"/default_commands.sh
unalias interactive_command batch_command
unset -f _INTERACTIVE_COMMAND _BATCH_COMMAND
__git_ps1(){ :;}
. "$_MONORAIL_DIR"/bash-preexec/bash-preexec.sh
_MONORAIL_ALERT(){
(exec mplayer -quiet /usr/share/sounds/gnome/default/alerts/glass.ogg >&- 2>&-&)
}
_MONORAIL_MAGIC_SHELLBALL(){
local ANSWER SPACES i
SPACES=
i=0
case "$RANDOM" in
*[0-4])case "$RANDOM" in
*0)ANSWER="IT IS CERTAIN.";;
*1)ANSWER="IT IS DECIDEDLY SO.";;
*2)ANSWER="WITHOUT A DOUBT.";;
*3)ANSWER="YES – DEFINITELY.";;
*4)ANSWER="YOU MAY RELY ON IT.";;
*5)ANSWER="AS I SEE IT, YES.";;
*6)ANSWER="MOST LIKELY.";;
*7)ANSWER="OUTLOOK GOOD.";;
*8)ANSWER="YES.";;
*)ANSWER="SIGNS POINT TO YES."
esac
;;
*)case "$RANDOM" in
*0)ANSWER="REPLY HAZY, TRY AGAIN.";;
*1)ANSWER="ASK AGAIN LATER.";;
*2)ANSWER="BETTER NOT TELL YOU NOW.";;
*3)ANSWER="CANNOT PREDICT NOW.";;
*4)ANSWER="CONCENTRATE AND ASK AGAIN.";;
*5)ANSWER="DON'T COUNT ON IT.";;
*6)ANSWER="MY REPLY IS NO.";;
*7)ANSWER="MY SOURCES SAY NO.";;
*8)ANSWER="OUTLOOK NOT SO GOOD.";;
*)ANSWER="VERY DOUBTFUL."
esac
esac
while [[ $i -lt $((COLUMNS/2-${#ANSWER}/2)) ]];do
SPACES="$SPACES "
i=$((i+1))
done
\echo -e "\e[?25l\e[3A\r\e[K$SPACES$ANSWER"
}
_MONORAIL_COMMAND(){
local CMD_STATUS
CMD_STATUS=$?
\printf "%$((COLUMNS-1))s\\r"
HISTCONTROL=
_MONORAIL_HISTCMD_PREV=$(fc -l -1)
_MONORAIL_HISTCMD_PREV=${_MONORAIL_HISTCMD_PREV%%$'[\t ]'*}
if [[ -z $_MONORAIL_PENULTIMATE ]];then
_MONORAIL_CR_FIRST=1
CR_LEVEL=0
unset _MONORAIL_CTRLC
elif [[ $_MONORAIL_PENULTIMATE == "$_MONORAIL_HISTCMD_PREV" ]];then
if [[ -z $_MONORAIL_CR_FIRST ]] &&[[ $CMD_STATUS == 0 ]]&&[[ -z $_MONORAIL_CTRLC ]];then
case "$CR_LEVEL" in
0)ls
CR_LEVEL=3
if \git status >&- 2>&-;then
CR_LEVEL=1
else
\printf "\e[J\n\n"
fi
;;
2)CR_LEVEL=3
if [[ $_MONORAIL_DUMB_TERMINAL ]]
then
\git -c color.status=never status|\head -n$((LINES-2))|\head -n$((LINES-4))
else
\git -c color.status=always status|\head -n$((LINES-2))|\head -n$((LINES-4))
fi
\echo -e "        ...\n\n"
;;
*)_MONORAIL_MAGIC_SHELLBALL
esac
CR_LEVEL=$((CR_LEVEL+1))
fi
unset _MONORAIL_CR_FIRST
else
unset _MONORAIL_CR_FIRST
CR_LEVEL=0
fi
unset _MONORAIL_CTRLC
_MONORAIL_PENULTIMATE=$_MONORAIL_HISTCMD_PREV
trap "_MONORAIL_CTRLC=1;\echo -n" INT
trap "_MONORAIL_CTRLC=1;\echo -n" ERR
[[ $BASH_VERSION ]]&&history -a >&- 2>&-
}
if [[ $TERM = "vt"??? ]];then
printf '\e[?25l' >/dev/tty 2>&-
_MONORAIL_VTXXX_TERMINAL=1
elif [[ $TERM = "linux" ]];then
_MONORAIL_LINUX_TERMINAL=1
elif [[ $TERM == "tek"* ]]||[[ $TERM == "ibm-327"* ]]||[[ $TERM == "dp33"?? ]] ||[[ $TERM == "dumb" ]]||[[ $TERM == "wyse60" ]]||[[ $TERM == "dm2500" ]]||[[ $TERM == "adm3a" ]]||[[ $TERM == "vt"?? ]];then
bind 'set enable-bracketed-paste off'
_MONORAIL_DUMB_TERMINAL=1
else
printf '\e[?25l' >/dev/tty 2>&-
fi
}
}
#} >&- 2>&-
