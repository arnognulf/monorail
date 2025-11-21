#!/bin/bash
# Copyright (c) 2025 Thomas Eriksson
#
# Contains code from bash-preexec
# Copyright (c) 2017 Ryan Caloras and contributors (see https://github.com/rcaloras/bash-preexec)
# SPDX-License-Identifier: BSD-3-Clause
# see FAST_SHELL_GUIDELINES.md on coding guidelines for this file.
{
[[ $_MR_DIR ]]||_MR_DIR=${XDG_DATA_HOME-$HOME/.local/share}/monorail
_MR_HOST=${HOSTNAME%%.*}
if [[ $ZSH_NAME ]];then
setopt KSH_ARRAYS
setopt prompt_subst
_MR_PREHIDE='%{'
_MR_POSTHIDE='%}'
_MR_HOST=$_MR_HOST:l
else
_MR_HOST=${_MR_HOST,,}
_MR_PREHIDE='\['
_MR_POSTHIDE='\]'
_MR_last_argument_prev_command="$_"
unset _MR_inside_preexec
_MR_preexec_interactive_mode=""
declare -a preexec_functions
_MR_preexec_interactive_mode="on"
_MR_in_prompt_command(){
local prompt_command_array IFS=$'\n;'
read -rd '' -a prompt_command_array <<<"${PROMPT_COMMAND[*]:-}"
local trimmed_arg
local text=${1:-}
text="${text#"${text%%[![:space:]]*}"}"
text="${text%"${text##*[![:space:]]}"}"
trimmed_arg="$text"
local command trimmed_command
for command in "${prompt_command_array[@]:-}";do
text=${command}
text="${text#"${text%%[![:space:]]*}"}"
text="${text%"${text##*[![:space:]]}"}"
trimmed_command="$text"
[[ $trimmed_command == "$trimmed_arg" ]]&&return 0
done
return 1
}
_MR_preexec_invoke_exec(){
_MR_last_argument_prev_command="${1:-}"
[[ $_MR_inside_preexec ]]&&return
local _MR_inside_preexec=1
[[ ! -t 1 ]]&&return
[[ ${COMP_POINT:-}||${READLINE_POINT:-} ]]&&return
if [[ -z ${_MR_preexec_interactive_mode:-} ]];then
return
else
[[ 0 -eq ${BASH_SUBSHELL:-} ]]&&_MR_preexec_interactive_mode=""
fi
if _MR_in_prompt_command "${BASH_COMMAND:-}";then
_MR_preexec_interactive_mode=""
return
fi
local this_command
this_command=$(LC_ALL=C HISTTIMEFORMAT='' builtin history 1)
this_command="${this_command#*[[:digit:]][* ] }"
[[ -z $this_command ]]&&return
local preexec_function
for preexec_function in "${preexec_functions[@]:-}";do
if type -t "$preexec_function" 1>/dev/null;then
if [[ ${_MR_last_ret_value-0} = 0 ]];then
true
else
(exit "${_MR_last_ret_value-0}")
fi
"$preexec_function" "$this_command"
fi
done
return "${_MR_last_ret_value-0}"
}
_MR_install(){
[[ ${PROMPT_COMMAND[*]:-} == *"precmd"* ]]&&return 1
trap '_MR_preexec_invoke_exec "$_"' DEBUG
eval "local trap_argv=(${_MR_trap_string:-})"
local prior_trap=${trap_argv[2]:-}
unset _MR_trap_string
if [[ $prior_trap ]];then
eval '_MR_original_debug_trap() {
            '"$prior_trap"'
        }'
preexec_functions+=(_MR_original_debug_trap)
fi
local histcontrol
histcontrol="${HISTCONTROL:-}"
histcontrol="${histcontrol//ignorespace/}"
[[ $histcontrol == *"ignoreboth"* ]]&&histcontrol="ignoredups:${histcontrol//ignoreboth/}"
export HISTCONTROL="$histcontrol"
if [[ ${_MR_enable_subshells:-} ]];then
set -o functrace >/dev/null 2>&1
shopt -s extdebug >/dev/null 2>&1
fi
local existing_prompt_command
existing_prompt_command="${PROMPT_COMMAND:-}"
existing_prompt_command="${existing_prompt_command//$'_MR_trap_string="$(trap -p DEBUG)"\ntrap - DEBUG\n_MR_install'/:}"
existing_prompt_command="${existing_prompt_command//$'\n':$'\n'/$'\n'}"
existing_prompt_command="${existing_prompt_command//$'\n':;/$'\n'}"
local text="$existing_prompt_command"
text="${text#"${text%%[![:space:]]*}"}"
existing_prompt_command="${text%"${text##*[![:space:]]}"}"
existing_prompt_command=${existing_prompt_command%;}
existing_prompt_command=${existing_prompt_command#;}
[[ ${existing_prompt_command:-:} == ":" ]]&&existing_prompt_command=
PROMPT_COMMAND='precmd'
PROMPT_COMMAND+=${existing_prompt_command:+$'\n'$existing_prompt_command}
PROMPT_COMMAND+=('_MR_preexec_interactive_mode="on"')
preexec_functions+=(preexec)
_MR_inside_precmd=1 precmd
_MR_preexec_interactive_mode="on"
}
text="${PROMPT_COMMAND:-}"
text="${text#"${text%%[![:space:]]*}"}"
sanitized_prompt_command="${text%"${text##*[![:space:]]}"}"
sanitized_prompt_command=${sanitized_prompt_command%;}
sanitized_prompt_command=${sanitized_prompt_command#;}
[[ $sanitized_prompt_command ]]&&PROMPT_COMMAND=("$sanitized_prompt_command")
PROMPT_COMMAND+=($'_MR_trap_string="$(trap -p DEBUG)"\ntrap - DEBUG\n_MR_install')
fi
preexec(){
{
# TODO: report and move to bash-preexec: SIGWINCH causes preexec to run again
[[ $(fc -l -1) == "$_MR_PREV_CMD" ]]&&return
_MR_PREV_CMD=$(fc -l -1)
local C ICON CMD
C=${1/\\\a/\\\\\a}
C=${C/\\\b/\\\\\b}
C=${C/\\\c/\\\\\c}
C=${C/\\\d/\\\\\d}
C=${C/\\\e/\\\\\e}
C=${C/\\\f/\\\\\f}
C=${C/\\\g/\\\\\g}
C=${C/\\\h/\\\\\h}
C=${C/\\\i/\\\\\i}
C=${C/\\\j/\\\\\j}
C=${C/\\\k/\\\\\k}
C=${C/\\\l/\\\\\l}
C=${C/\\\m/\\\\\m}
C=${C/\\\n/\\\\\n}
C=${C/\\\o/\\\\\o}
C=${C/\\\p/\\\\\p}
C=${C/\\\q/\\\\\q}
C=${C/\\\r/\\\\\r}
C=${C/\\\s/\\\\\s}
C=${C/\\\t/\\\\\t}
C=${C/\\\u/\\\\\u}
C=${C/\\\v/\\\\\v}
C=${C/\\\w/\\\\\w}
C=${C/\\\x/\\\\\x}
C=${C/\\\y/\\\\\y}
C=${C/\\\z/\\\\\z}
C=${C/\\\033/<ESC>}
_MR_CMD=${C/\\\007/<BEL>}
case $_MR_CMD in
"c "*|"cd "*|".."*):;;
*)[[ -z $_MR_DATE ]]&&_MR_DATE=$(LC_MESSAGES=C LC_ALL=C date +%m-%d)
case $_MR_DATE in
10-2*|10-3*)ICON=🎃
;;
12*)ICON=🎄
;;
*)ICON="*️⃣"
esac
_MR_TITLE="$ICON  $_MR_CMD"
[[ $_MR_HAS_SUFFIX ]]&&_MR_SUFFIX
CMD=${_MR_CMD%% *}
CMD=${CMD%%;*}
unset _MR_CUSTOM_TITLE
alias "$CMD" >&- 2>&-&&_MR_CUSTOM_TITLE=1
for COMMAND in "${CUSTOM_TITLE_COMMANDS[@]}";do
[[ $COMMAND == "${_MR_CMD:0:${#COMMAND}}" ]]&&_MR_CUSTOM_TITLE=1
done
_MR_MEASURE=1
_START_SECONDS=$SECONDS
_MR_TITLE+=" in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M)"
# shellcheck disable=SC2059 # keep printf compact
printf "\e]11;#${_COLORS[17]}\a\e]10;#${_COLORS[16]}\a\e]12;#${_COLORS[21]}\a" >/dev/tty 2>&-
esac
unset _MR_CUSTOM_TITLE
# zsh cannot have closed fd's here
} &>/dev/null
}
_MR_SET_TITLE(){
unset _MR_TITLE_OVERRIDE
[[ $1 ]]&&_MR_TITLE_OVERRIDE="$*"
}
alias title=_MR_SET_TITLE
_TITLE_RAW(){
[[ $_MR_NOSTYLING ]]&&return 0
printf "\e]0;%s\a" "$*" >/dev/tty 2>&-
}
if [[ $XDG_CONFIG_HOME ]];then
_MR_CONFIG=$XDG_CONFIG_HOME/monorail
else
_MR_CONFIG=$HOME/.config/monorail
fi
_MR_NAME(){
unset NAME
[[ $1 ]]&&NAME="$*"
}
alias name=_MR_NAME
precmd(){
local CMD_STATUS
CMD_STATUS=$?
if [[ $_MR_LAUNCHED ]];then
{
# bash line editor (ble.sh) do not like others messing with the tty
# enable stty echo in case some command has disabled it up
[[ $BLE_ATTACHED ]]||LC_MESSAGES=C LC_ALL=C stty echo 2>&-
local SECONDS_M DURATION_H DURATION_M DURATION_S CURRENT_SECONDS DURATION DIFF
CURRENT_SECONDS=$SECONDS
DIFF=$((CURRENT_SECONDS-_START_SECONDS))
if [[ $_MR_MEASURE ]]&&[[ $DIFF -gt ${_MR_TIMEOUT-29} ]];then
SECONDS_M=$((DIFF%3600))
DURATION_H=$((DIFF/3600))
DURATION_M=$((SECONDS_M/60))
DURATION_S=$((SECONDS_M%60))
printf "\n\aCommand took "
DURATION=
[ $DURATION_H -gt 0 ]&&DURATION="${DURATION_H}h "
[ $DURATION_M -gt 0 ]&&DURATION+="${DURATION_M}m "
DURATION+="${DURATION_S}s, finished at "$(LC_MESSAGES=C LC_ALL=C date +%H:%M).
echo "$DURATION"
(exec notify-send -a "Completed $_MR_CMD" -i terminal "$_MR_CMD" "Command took $DURATION"&)
(exec mplayer -quiet /usr/share/sounds/gnome/default/alerts/glass.ogg >&- 2>&-&)
_MR_LONGRUNNING=1
fi
unset _MR_MEASURE
} 2>&-
printf "%$((COLUMNS-1))s\\r"
HISTCONTROL=
_MR_HISTCMD_PREV=$(fc -l -1)
_MR_HISTCMD_PREV=${_MR_HISTCMD_PREV%%$'[\t ]'*}
if [[ -z $_MR_PENULTIMATE ]];then
_MR_CR_FIRST=1
_MR_CR_COUNT=0
unset _MR_CTRLC
elif [[ $_MR_PENULTIMATE == "$_MR_HISTCMD_PREV" ]];then
if [[ -z $_MR_CR_FIRST ]] &&[[ $CMD_STATUS == 0 ]]&&[[ -z $_MR_CTRLC ]];then
case "$_MR_CR_COUNT" in
0)ls
_MR_CR_COUNT=3
if \git status >&- 2>&-;then
_MR_CR_COUNT=1
else
printf "\e[J\n\n"
fi
;;
2)_MR_CR_COUNT=3
\git -c color.status=always status|\head -n$((LINES-2))|\head -n$((LINES-4))
echo -e "        ...\n\n"
;;
*)_MR_MAGIC_SHELLBALL
esac
_MR_CR_COUNT=$((_MR_CR_COUNT+1))
fi
unset _MR_CR_FIRST
else
unset _MR_CR_FIRST
_MR_CR_COUNT=0
fi
unset _MR_CTRLC
_MR_PENULTIMATE=$_MR_HISTCMD_PREV
trap "_MR_CTRLC=1;echo -n" INT
trap "_MR_CTRLC=1;echo -n" ERR
[[ $BASH_VERSION ]]&&history -a >&- 2>&-
else
alias for='_MR_NOSTYLING=1;for'
alias while='_MR_NOSTYLING=1;while'
alias until='_MR_NOSTYLING=1;until'
_MR_LAUNCHED=1
fi
if [[ $_MR_LONGRUNNING ]] ;then
_MR_TITLE="✅ Completed $_MR_CMD"
[[ $_MR_HAS_SUFFIX ]]&&_MR_SUFFIX
unset _MR_LONGRUNNING
return 0
fi
case $PWD in
/run/user/*/gvfs/*)_MR_GIT_PS1=;;
*)local PROMPT_PWD MR_REPO
PROMPT_PWD=$PWD
MR_REPO=
while [[ "$PROMPT_PWD" ]];do
if [[ -d "$PROMPT_PWD/.repo" ]];then
MR_REPO=1
break
fi
PROMPT_PWD="${PROMPT_PWD%/*}"
done
if [[ -z $_MR_GIT_LOADED ]];then
local DIR
DIR="$PWD"
while [[ $DIR ]];do
if [[ -e "$DIR/.git" ]]&&[[ -e /usr/lib/git-core/git-sh-prompt ]];then
. /usr/lib/git-core/git-sh-prompt
_MR_GIT_LOADED=1
fi
DIR=${DIR%/*}
done
fi
# shellcheck disable=SC2329 # _TITLE function is invoked by __git_ps1 which is assigned later
_MR_GIT_PS1=$(_TITLE () { shift;"$@";};TERM=dumb GIT_CONFIG_GLOBAL="" LC_MESSAGES=C LC_ALL=C __git_ps1 "")
esac
local I ICON TITLE_BASE
TITLE_BASE="${PWD##*/}"
if [[ "$MR_REPO" ]];then
ICON="🏗️"
[[ $_MR_HAS_SUFFIX ]]&&_MR_SUFFIX
elif [[ "$_MR_GIT_PS1" ]];then
ICON="🚧"
[[ $_MR_HAS_SUFFIX ]]&&_MR_SUFFIX
else
case "$PWD" in
*/etc|*/etc/*)ICON="️🗂️";;
*/bin|*/sbin)ICON="️⚙️ ";;
*/lib|*/lib64|*/lib32)ICON="🔩";;
*/tmp|*/tmp/*|*/.cache|*/.cache/*)ICON="🚽";;
"$HOME/Trash"*)ICON="🗑️";;
"$HOME/.local/share/Trash/files"*)ICON="♻️";;
/boot|/boot/*)ICON="🥾";;
/)ICON="💻"; TITLE_BASE="/";;
*/.*)ICON="📌";;
/media/*)ICON="💾";;
/proc/*|/sys/*|/dev/*|/proc|/sys|/dev)ICON="🤖";;
*/Documents|*/Documents/*|*/doc|*/docs|*/doc/*|*/docs/*|"$XDG_DOCUMENTS_DIR"|"$XDG_DOCUMENTS_DIR"/*)ICON="📑";;
*/out|*/out/*)ICON="🚀  ${PWD##*/}";;
*/src|*/src/*|*/sources|*/sources/*)ICON="🚧";;
"$XDG_MUSIC_DIR"|"$XDG_MUSIC_DIR"/*)ICON="🎵";;
"$XDG_PICTURES_DIR"|"$XDG_PICTURES_DIR"/*)ICON="🖼️";;
"$XDG_VIDEOS_DIR"|"$XDG_VIDEOS_DIR"/*)ICON="🎬";;
*/Downloads|*/Downloads/*|"$XDG_DOWNLOAD_DIR"|"$XDG_DOWNLOAD_DIR"/*)ICON="📦";;
*)ICON="📂"
esac
case "$PWD" in
"$HOME")
if [[ $SSH_CLIENT ]]
then
TITLE_BASE="$_MR_HOST"
ICON="🌐"
elif [[ -e /.dockerenv ]]
then
TITLE_BASE="docker"
ICON="🐋"
else
ICON="🏠"
TITLE_BASE="$_MR_HOST"
fi
;;
*)
[[ $_MR_HAS_SUFFIX ]]&&_MR_SUFFIX
esac
fi
_MR_TITLE="$ICON  ${_MR_TITLE_OVERRIDE-${TITLE_BASE}}"
local PWD_BASENAME="${PWD##*/}"
[ -z "$PWD_BASENAME" ]&&PWD_BASENAME=/
case $PWD in
"$HOME")_MR_PWD_BASENAME="~";;
*)_MR_PWD_BASENAME="${NAME-$PWD_BASENAME}"
esac
_MR_TEXT=" $_MR_PWD_BASENAME$_MR_GIT_PS1 "
_MR_TEXT="${_MR_TEXT//\.\.\./…}"
if [[ ${#_MR_TEXT} -gt $((COLUMNS / 3)) ]];then
# frequently, the last of the text is the most relevant, cut beginning if too long path
_MR_TEXT=" …${_MR_TEXT:$((${#_MR_TEXT} -  $((COLUMNS / 3))))}"
fi
_MR_TEXT_ARRAY=()
if [[ $ZSH_NAME ]]
then
for ((I=0; I < ${#_MR_TEXT}; I++))
do
_MR_TEXT_ARRAY[I]="${_MR_TEXT[I]}"
done
else
for ((I=0; I < ${#_MR_TEXT}; I++))
do
_MR_TEXT_ARRAY[I]="${_MR_TEXT:I:1}"
done
fi
_MR_TEXT_ARRAY_LEN=${#_MR_TEXT_ARRAY[@]}
local RGB R GB G B
if [[ $_MR_CACHE != "$COLUMNS$_MR_TEXT" ]];then
unset _MR_DATE _MR_CACHE "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]" _MR_MEASURE
if [[ ! -f "$_MR_CONFIG/colors-$_MR_HOST".sh ]];then
LC_ALL=C LC_MESSAGES=C \cat "$_MR_DIR"/colors/Default.sh "$_MR_DIR"/gradients/Default.sh > "$_MR_CONFIG/colors-$_MR_HOST".sh 2>&-
fi
# shellcheck disable=SC1090,SC1091 # file will be copied
. "$_MR_CONFIG/colors-$_MR_HOST".sh
I=0
_MR_LINE=
while [[ $I -lt $COLUMNS ]]
do
_MR_LINE+=$'\e'"[38;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*I/$((COLUMNS+1))))]}m"$'\xe2\x96\x81'
I=$((I+1))
done
local I=0
if [[ -z ${_PROMPT_LUT[0]} ]];then
_MR_TEXT_FORMATTED="$_MR_PREHIDE"$'\e'"[0;7m${_MR_POSTHIDE}"
while [[ $I -lt ${_MR_TEXT_ARRAY_LEN} ]];do
_MR_TEXT_FORMATTED+="${_MR_TEXT_ARRAY[I]}"
I=$((I+1))
done
_MR_TEXT_FORMATTED+="$_MR_PREHIDE"$'\e'"[0;8m${_MR_POSTHIDE}▎"
else
_MR_TEXT_FORMATTED=
[[ -z ${_PROMPT_TEXT_LUT[*]} ]]&&_PROMPT_TEXT_LUT[0]="255;255;255"
while [[ $I -lt ${_MR_TEXT_ARRAY_LEN} ]];do
_MR_TEXT_FORMATTED+="$_MR_PREHIDE"$'\e'"[48;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*I/$((COLUMNS+1))))]}m"$'\e'"[38;2;${_PROMPT_TEXT_LUT[$((${#_PROMPT_TEXT_LUT[*]}*I/$((COLUMNS+1))))]}m$_MR_POSTHIDE${_MR_TEXT_ARRAY[I]}"
I=$((I+1))
done
# the invisible vertical bar is added to make the prompt displayed better when copied to a chat or text doc
# this is not normally visible, but on some terminals not supporting ^[8m it will fall back the same color as the monorail bar
_MR_TEXT_FORMATTED+="$_MR_PREHIDE"$'\e'"[0;8m"$'\e'"[38;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*I/$((COLUMNS+1))))]}m$_MR_POSTHIDE▎"
fi
RGB=${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*$((_MR_TEXT_ARRAY_LEN+1))/$((COLUMNS+1))))]}
R=${RGB%%;*}
GB=${RGB#*;}
G=${GB%%;*}
B=${GB##*;}
_MR_CURCOLOR=$(\printf "%.2x%.2x%.2x" "$R" "$G" "$B" 2>&-)
[[ ${_PROMPT_LUT[0]} ]]||_MR_CURCOLOR="${_COLORS[21]}"
_MR_CACHE="$COLUMNS$_MR_TEXT"
fi
# shellcheck disable=SC2059 # keep printf compact
printf "\e]11;#${_COLORS[17]}\a\e]10;#${_COLORS[16]}\a\e]12;#$_MR_CURCOLOR\a\e]4;0;#${_COLORS[0]}\a\e]4;1;#${_COLORS[1]}\a\e]4;2;#${_COLORS[2]}\a\e]4;3;#${_COLORS[3]}\a\e]4;4;#${_COLORS[4]}\a\e]4;5;#${_COLORS[5]}\a\e]4;6;#${_COLORS[6]}\a\e]4;7;#${_COLORS[7]}\a\e]4;8;#${_COLORS[8]}\a\e]4;9;#${_COLORS[9]}\a\e]4;10;#${_COLORS[10]}\a\e]4;11;#${_COLORS[11]}\a\e]4;12;#${_COLORS[12]}\a\e]4;13;#${_COLORS[13]}\a\e]4;14;#${_COLORS[14]}\a\e]4;15;#${_COLORS[15]}\a"
# workaround: a data races frequently causes gnome-terminal to ignore setting the colors; set them again after 0.1 seconds as a workaround
# shellcheck disable=SC2059 # keep printf compact
( { sleep 0.1;printf "\e]11;#${_COLORS[17]}\a\e]10;#${_COLORS[16]}\a\e]12;#$_MR_CURCOLOR\a" >/dev/tty 2>&-;} & )

# shellcheck disable=SC2025,SC1078,SC1079 # no need to enclose in \[ \] as cursor position is calculated from after newline, quoting is supposed to span multiple lines
PS1=$'\e'"]0;"'$_MR_TITLE'$'\a'$'\r'$'\e'"[0m$_MR_LINE
$_MR_TEXT_FORMATTED$_MR_PREHIDE"$'\e'"[0m"$'\e'"[?25h${_MR_POSTHIDE}"
unset _MR_NOSTYLING
}
_TITLE(){
if [[ $_MR_MEASURE ]];then
_TITLE_RAW "$* in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M 2>&-)"
else
_TITLE_RAW "$* in ${PWD##*/}"
fi
}
_NO_MEASURE(){
unset _MR_MEASURE
"$@"
}
_ICON(){
local ICON="$1"
shift
if [[ -z ${FUNCNAME[1]} ]]||[[ ${FUNCNAME[1]} == "_NO_MEASURE" ]];then
local FIRST_ARG="$1"
(case "$FIRST_ARG" in
_*)shift
esac
FIRST_ARG="$1"
FIRST_NON_OPTION="$2"
while [[ ${FIRST_NON_OPTION:0:1} == '-' ]]||[ "${FIRST_NON_OPTION:0:1}" = '_' ]||[ "$FIRST_NON_OPTION" = '.' ];do
if [ "$FIRST_NON_OPTION" = '-u' ];then
shift 2
else
shift
fi
FIRST_NON_OPTION="$2"
done
[[ "$ICON" ]]&&if [[ -z "$FIRST_NON_OPTION" ]];then
_TITLE "$ICON  ${FIRST_ARG##*/}"
else
_TITLE "$ICON  ${FIRST_NON_OPTION##*/}"
fi
) >&- 2>&-
fi
"$@"
}
trap "unset _MR_CACHE" WINCH
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
. "$_MR_DIR"/default_commands.sh
unalias interactive_command batch_command
unset -f _INTERACTIVE_COMMAND _BATCH_COMMAND
__git_ps1(){ :;}
_MR_MAGIC_SHELLBALL(){
local A S SPACES i
S=
i=0
case "$RANDOM" in
*[0-4])case "$RANDOM" in
*0)A="IT IS CERTAIN.";;
*1)A="IT IS DECIDEDLY SO.";;
*2)A="WITHOUT A DOUBT.";;
*3)A="YES – DEFINITELY.";;
*4)A="YOU MAY RELY ON IT.";;
*5)A="AS I SEE IT, YES.";;
*6)A="MOST LIKELY.";;
*7)A="OUTLOOK GOOD.";;
*8)A="YES.";;
*)A="SIGNS POINT TO YES."
esac
;;
*)case "$RANDOM" in
*0)A="REPLY HAZY, TRY AGAIN.";;
*1)A="ASK AGAIN LATER.";;
*2)A="BETTER NOT TELL YOU NOW.";;
*3)A="CANNOT PREDICT NOW.";;
*4)A="CONCENTRATE AND ASK AGAIN.";;
*5)A="DON'T COUNT ON IT.";;
*6)A="MY REPLY IS NO.";;
*7)A="MY SOURCES SAY NO.";;
*8)A="OUTLOOK NOT SO GOOD.";;
*)A="VERY DOUBTFUL."
esac
esac
while [[ $i -lt $((COLUMNS/2-${#A}/2)) ]];do
S="$S "
i=$((i+1))
done
echo -e "\e[?25l\e[3A\r\e[K$S$A"
}

if [[ "$TERM" = "xterm-256color" ]]&&[[ $COLORTERM = "truecolor" ]];then
:
elif [[ "$MC_TMPDIR" ]];then
unalias git >/dev/null 2>/dev/null
. "$_MR_DIR/monorail.compat.sh"
else
case "$TERM" in
"alacritty"|"rio"|"xterm-kitty"|"xterm-ghostty"|"rxvt-unicode-256color")
printf '\e]0; \a\e[?25l' >/dev/tty 2>&-
# ghostty adds a ssh function which causes parsing error since monorail adds an ssh alias
[[ "$TERM" = "xterm-ghostty" ]]&&unalias ssh 2>/dev/null
;;
"ansi"|"tek"*|"ibm-327"*|"dp33"??|"dumb"|"wyse60"|"dm2500"|"adm3a"|"vt"*|"linux"|"xterm-color"|"wsvt"*|"cons"*|"pc"*|"xterm-16color"|"xgterm"|"screen."*|"Eterm"|"tty"*|"tn"*|"ti"*|"cygwin"|"aaa"|"at386"|"hft"|"sun"|"wy370"|"scoansi"|"dg2"*)
# needed to avoid syntax error in monorail.compat.sh
unalias git >/dev/null 2>/dev/null
. "$_MR_DIR/monorail.compat.sh"
;;
*)
printf '\e]0; \a\e[?25l' >/dev/tty 2>&-
if [[ $XTERM_VERSION ]] && [[ "$XTERM_LOCALE" = *"UTF-8" ]];then
:
else
. "$_MR_DIR/monorail.compat.sh"
fi
if [[ "$COLORTERM" = "truecolor" ]];then
:
else
# COLORTERM may be filtered (eg. by SSH) or missing (eg. in xterm)
# manual detection is needed
# detect if truecolor sequence is parsed and not printed
# multiple terminals supports truecolor but not reporting of color
printf '\e[48:2:1:2:3m\e[6n\e[0m\e]0g' >/dev/tty
read -r -t 0.5 -n7 _MR_RESPONSE
case "$_MR_RESPONSE" in
*";1R")
# restore color after detection, needed for xterm
# shellcheck disable=SC2059 # keep printf compact
printf "\e]11;#${_COLORS[17]}\a\e]10;#${_COLORS[16]}\a\e]12;#${_COLORS[21]}\a" >/dev/tty 2>&-
;;
*)
unalias git >/dev/null 2>/dev/null
. "$_MR_DIR/monorail.compat.sh"
esac
fi
esac
:
fi
if [[ $SSH_CLIENT ]]||[[ $TMUX ]];then
_MR_HAS_SUFFIX=1
_MR_SUFFIX () {
_MR_TITLE="$_MR_TITLE on $_MR_HOST"
}
elif [[ -e /.dockerenv ]];then
_MR_HAS_SUFFIX=1
_MR_SUFFIX () {
_MR_TITLE="$_MR_TITLE on docker"
}
fi
# shellcheck disable=SC2139
alias monorail_color="_MR_CONFIG=$_MR_CONFIG _MR_DIR=$_MR_DIR $ZSH_NAME$BASH $_MR_DIR/scripts/color.sh"
# shellcheck disable=SC2139
alias monorail_gradient="_MR_CONFIG=$_MR_CONFIG _MR_DIR=$_MR_DIR $ZSH_NAME$BASH $_MR_DIR/scripts/gradient.sh"
# shellcheck disable=SC2139
alias monorail_image="_MR_CONFIG=$_MR_CONFIG _MR_DIR=$_MR_DIR $ZSH_NAME$BASH $_MR_DIR/scripts/image.sh"
# shellcheck disable=SC2139
alias monorail_textgradient="_MR_CONFIG=$_MR_CONFIG _MR_DIR=$_MR_DIR $ZSH_NAME$BASH $_MR_DIR/scripts/gradient.sh --text"
# shellcheck disable=SC2139
alias rgb="bash $_MR_DIR/scripts/rgb.sh"
} >&- 2>&-
