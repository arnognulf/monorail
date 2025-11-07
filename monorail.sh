#!/bin/bash
# Copyright (c) 2025 Thomas Eriksson
#
# Contains code from bash-preexec
# Copyright (c) 2017 Ryan Caloras and contributors (see https://github.com/rcaloras/bash-preexec)
# SPDX-License-Identifier: BSD-3-Clause
# see FAST_SHELL_GUIDELINES.md on coding guidelines for this file.
{
if ! [[ $_MONORAIL_DIR ]];then
_MONORAIL_DIR=${XDG_DATA_HOME-$HOME/.local/share}/monorail
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

BP_PIPESTATUS=("${PIPESTATUS[@]}")
__bp_last_argument_prev_command="$_"
unset __bp_inside_precmd __bp_inside_preexec
__bp_install_string=$'__bp_trap_string="$(trap -p DEBUG)"\ntrap - DEBUG\n__bp_install'
__bp_adjust_histcontrol(){
local histcontrol
histcontrol="${HISTCONTROL:-}"
histcontrol="${histcontrol//ignorespace/}"
if [[ $histcontrol == *"ignoreboth"* ]];then
histcontrol="ignoredups:${histcontrol//ignoreboth/}"
fi
export HISTCONTROL="$histcontrol"
}
__bp_preexec_interactive_mode=""
declare -a precmd_functions
declare -a preexec_functions
__bp_trim_whitespace(){
local var=${1:?} text=${2:-}
text="${text#"${text%%[![:space:]]*}"}"
text="${text%"${text##*[![:space:]]}"}"
printf -v "$var" '%s' "$text"
}
__bp_sanitize_string(){
local var=${1:?} text=${2:-} sanitized
__bp_trim_whitespace sanitized "$text"
sanitized=${sanitized%;}
sanitized=${sanitized#;}
__bp_trim_whitespace sanitized "$sanitized"
printf -v "$var" '%s' "$sanitized"
}
__bp_preexec_interactive_mode="on"
__bp_precmd_invoke_cmd(){
__bp_last_ret_value="$?" BP_PIPESTATUS=("${PIPESTATUS[@]}")
if [[ $__bp_inside_precmd ]];then
return
fi
local __bp_inside_precmd=1
local precmd_function
for precmd_function in "${precmd_functions[@]}";do
if type -t "$precmd_function" 1>/dev/null;then
__bp_set_ret_value "$__bp_last_ret_value" "$__bp_last_argument_prev_command"
"$precmd_function"
fi
done
__bp_set_ret_value "$__bp_last_ret_value"
}
__bp_set_ret_value(){
return ${1:+"$1"}
}
__bp_in_prompt_command(){
local prompt_command_array IFS=$'\n;'
read -rd '' -a prompt_command_array <<<"${PROMPT_COMMAND[*]:-}"
local trimmed_arg
__bp_trim_whitespace trimmed_arg "${1:-}"
local command trimmed_command
for command in "${prompt_command_array[@]:-}";do
__bp_trim_whitespace trimmed_command "$command"
if [[ $trimmed_command == "$trimmed_arg" ]];then
return 0
fi
done
return 1
}
__bp_preexec_invoke_exec(){
__bp_last_argument_prev_command="${1:-}"
if [[ $__bp_inside_preexec ]];then
return
fi
local __bp_inside_preexec=1
if [[ ! -t 1 && -z ${__bp_delay_install:-} ]];then
return
fi
if [[ -n ${COMP_POINT:-} || -n ${READLINE_POINT:-} ]];then
return
fi
if [[ -z ${__bp_preexec_interactive_mode:-} ]];then
return
else
if [[ 0 -eq ${BASH_SUBSHELL:-} ]];then
__bp_preexec_interactive_mode=""
fi
fi
if __bp_in_prompt_command "${BASH_COMMAND:-}";then
__bp_preexec_interactive_mode=""
return
fi
local this_command
this_command=$(LC_ALL=C HISTTIMEFORMAT='' builtin history 1)
this_command="${this_command#*[[:digit:]][* ] }"
if [[ -z $this_command ]];then
return
fi
local preexec_function
local preexec_function_ret_value
local preexec_ret_value=0
for preexec_function in "${preexec_functions[@]:-}";do
if type -t "$preexec_function" 1>/dev/null;then
__bp_set_ret_value "${__bp_last_ret_value:-}"
"$preexec_function" "$this_command"
preexec_function_ret_value="$?"
if [[ $preexec_function_ret_value != 0 ]];then
preexec_ret_value="$preexec_function_ret_value"
fi
fi
done
__bp_set_ret_value "$preexec_ret_value" "$__bp_last_argument_prev_command"
}
__bp_install(){
if [[ ${PROMPT_COMMAND[*]:-} == *"__bp_precmd_invoke_cmd"* ]];then
return 1
fi
trap '__bp_preexec_invoke_exec "$_"' DEBUG
eval "local trap_argv=(${__bp_trap_string:-})"
local prior_trap=${trap_argv[2]:-}
unset __bp_trap_string
if [[ -n $prior_trap ]];then
eval '__bp_original_debug_trap() {
            '"$prior_trap"'
        }'
preexec_functions+=(__bp_original_debug_trap)
fi
__bp_adjust_histcontrol
if [[ -n ${__bp_enable_subshells:-} ]];then
set -o functrace >/dev/null 2>&1
shopt -s extdebug >/dev/null 2>&1
fi
local existing_prompt_command
existing_prompt_command="${PROMPT_COMMAND:-}"
existing_prompt_command="${existing_prompt_command//$__bp_install_string/:}"
existing_prompt_command="${existing_prompt_command//$'\n':$'\n'/$'\n'}"
existing_prompt_command="${existing_prompt_command//$'\n':;/$'\n'}"
__bp_sanitize_string existing_prompt_command "$existing_prompt_command"
if [[ ${existing_prompt_command:-:} == ":" ]];then
existing_prompt_command=
fi
PROMPT_COMMAND='__bp_precmd_invoke_cmd'
PROMPT_COMMAND+=${existing_prompt_command:+$'\n'$existing_prompt_command}
if ((BASH_VERSINFO[0]>5||(BASH_VERSINFO[0]==5&&BASH_VERSINFO[1]>=1)));then
PROMPT_COMMAND+=('__bp_preexec_interactive_mode="on"')
else
PROMPT_COMMAND+=$'\n__bp_interactive_mode'
fi
precmd_functions+=(precmd)
preexec_functions+=(preexec)
__bp_precmd_invoke_cmd
__bp_preexec_interactive_mode="on"
}
__bp_install_after_session_init(){
local sanitized_prompt_command
__bp_sanitize_string sanitized_prompt_command "${PROMPT_COMMAND:-}"
if [[ -n $sanitized_prompt_command ]];then
PROMPT_COMMAND=$sanitized_prompt_command$'\n'
fi
PROMPT_COMMAND+=$__bp_install_string
}
if [[ -z ${__bp_delay_install:-} ]];then
__bp_install_after_session_init
fi
fi
preexec(){
{
# TODO: report and move to bash-preexec: SIGWINCH causes preexec to run again
[[ $(fc -l -1) == "$_MONORAIL_PREV_CMD" ]] && return
_MONORAIL_PREV_CMD=$(fc -l -1)
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
_TIMER_CMD=${C/\\\007/<BEL>}
case $_TIMER_CMD in
"c "*|"cd "*|".."*):;;
*)[[ -z $_MONORAIL_DATE ]]&&_MONORAIL_DATE=$(LC_MESSAGES=C LC_ALL=C date +%m-%d)
case $_MONORAIL_DATE in
10-2*|10-3*)ICON=🎃
;;
12*)ICON=🎄
;;
*)ICON="*️⃣"
esac
_MONORAIL_TITLE="$ICON  $_TIMER_CMD"
[[ $_MONORAIL_HAS_SUFFIX ]] && _MONORAIL_SUFFIX
CMD=${_TIMER_CMD%% *}
CMD=${CMD%%;*}
unset _MONORAIL_CUSTOM_TITLE
alias "$CMD" >&- 2>&-&&_MONORAIL_CUSTOM_TITLE=1
for COMMAND in "${CUSTOM_TITLE_COMMANDS[@]}";do
if [[ $COMMAND == "${_TIMER_CMD:0:${#COMMAND}}" ]];then
_MONORAIL_CUSTOM_TITLE=1
fi
done
_MEASURE=1
_START_SECONDS=$SECONDS
_MONORAIL_TITLE+=" in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M)"
# shellcheck disable=SC2059 # keep printf compact
printf "\e]11;#${_COLORS[17]}\a\e]10;#${_COLORS[16]}\a\e]12;#${_COLORS[21]}\a" >/dev/tty 2>&-
esac
unset _MONORAIL_CUSTOM_TITLE
# zsh cannot have closed fd's here
#} &>/dev/null
}
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
printf "\n\aCommand took "
DURATION=
[ $DURATION_H -gt 0 ]&&DURATION="${DURATION_H}h "
[ $DURATION_M -gt 0 ]&&DURATION+="${DURATION_M}m "
DURATION+="${DURATION_S}s, finished at "$(LC_MESSAGES=C LC_ALL=C date +%H:%M).
echo "$DURATION"
(exec notify-send -a "Completed $_TIMER_CMD" -i terminal "$_TIMER_CMD" "Command took $DURATION"&)
_MONORAIL_ALERT
_MONORAIL_LONGRUNNING=1
fi
unset _MEASURE
} 2>&-
}
_MONORAIL_SET_TITLE(){
if [[ $1 ]];then
_MONORAIL_TITLE_OVERRIDE="$*"
else
unset _MONORAIL_TITLE_OVERRIDE
fi
}
alias title=_MONORAIL_SET_TITLE
_TITLE_RAW(){
if [[ $_MONORAIL_NOSTYLING ]];then
return 0
fi
printf "\e]0;%s\a" "$*" >/dev/tty 2>&-
}
if [[ $XDG_CONFIG_HOME ]];then
_MONORAIL_CONFIG=$XDG_CONFIG_HOME/monorail
else
_MONORAIL_CONFIG=$HOME/.config/monorail
fi
_MONORAIL_NAME(){
if [[ $1 ]];then
NAME="$*"
else
unset NAME
fi
}
alias name=_MONORAIL_NAME
precmd(){
if [[ $_MONORAIL_LAUNCHED ]];then
_MONORAIL_STOP_TIMER
_MONORAIL_COMMAND
else
alias for='_MONORAIL_NOSTYLING=1;for'
alias while='_MONORAIL_NOSTYLING=1;while'
alias until='_MONORAIL_NOSTYLING=1;until'
_MONORAIL_LAUNCHED=1
fi
if [[ $_MONORAIL_LONGRUNNING ]] ;then
_MONORAIL_TITLE="✅ Completed $_TIMER_CMD"
[[ $_MONORAIL_HAS_SUFFIX ]] && _MONORAIL_SUFFIX
unset _MONORAIL_LONGRUNNING
return 0
fi
local _MONORAIL_REALPWD
_MONORAIL_REALPWD=$PWD
case $PWD in
/run/user/*/gvfs/*)_MONORAIL_GIT_PS1=;;
*)local PROMPT_PWD MONORAIL_REPO
PROMPT_PWD=$PWD
MONORAIL_REPO=
while [[ "$PROMPT_PWD" ]];do
if [[ -d "$PROMPT_PWD/.repo" ]];then
MONORAIL_REPO=1
break
fi
PROMPT_PWD="${PROMPT_PWD%/*}"
done
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
# shellcheck disable=SC2329 # _TITLE function is invoked by __git_ps1 which is assigned later
_MONORAIL_GIT_PS1=$(_TITLE () { shift;"$@";};TERM=dumb GIT_CONFIG_GLOBAL="" LC_MESSAGES=C LC_ALL=C __git_ps1 "")
esac
local ICON TITLE_BASE
TITLE_BASE="${PWD##*/}"
if [[ "$MONORAIL_REPO" ]];then
ICON="🏗️"
[[ $_MONORAIL_HAS_SUFFIX ]] && _MONORAIL_SUFFIX
elif [[ "$_MONORAIL_GIT_PS1" ]];then
ICON="🚧"
[[ $_MONORAIL_HAS_SUFFIX ]] && _MONORAIL_SUFFIX
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
case "$_MONORAIL_REALPWD" in
"$HOME")
if [[ $SSH_CLIENT ]]
then
TITLE_BASE="$_MONORAIL_SHORT_HOSTNAME"
ICON="🌐"
elif [[ -e /.dockerenv ]]
then
TITLE_BASE="docker"
ICON="🐋"
else
ICON="🏠"
TITLE_BASE="$_MONORAIL_SHORT_HOSTNAME"
fi
;;
*)
[[ $_MONORAIL_HAS_SUFFIX ]] && _MONORAIL_SUFFIX
esac
fi
_MONORAIL_TITLE="$ICON  ${_MONORAIL_TITLE_OVERRIDE-${TITLE_BASE}}"
local PWD_BASENAME="${PWD##*/}"
[ -z "$PWD_BASENAME" ]&&PWD_BASENAME=/
case $PWD in
"$HOME")_MONORAIL_PWD_BASENAME="~";;
*)_MONORAIL_PWD_BASENAME="${NAME-$PWD_BASENAME}"
esac
_MONORAIL_TEXT=" $_MONORAIL_PWD_BASENAME$_MONORAIL_GIT_PS1 "
_MONORAIL_TEXT="${_MONORAIL_TEXT//\.\.\./…}"
if [[ ${#_MONORAIL_TEXT} -gt $((COLUMNS / 3)) ]];then
# frequently, the last of the text is the most relevant, cut beginning if too long path
_MONORAIL_TEXT=" …${_MONORAIL_TEXT:$((${#_MONORAIL_TEXT} -  $((COLUMNS / 3))))}"
fi
_MONORAIL_TEXT_ARRAY=()
if [[ $ZSH_NAME ]]
then
for ((I=0; I < ${#_MONORAIL_TEXT}; I++))
do
_MONORAIL_TEXT_ARRAY[I]="${_MONORAIL_TEXT[I]}"
done
else
for ((I=0; I < ${#_MONORAIL_TEXT}; I++))
do
_MONORAIL_TEXT_ARRAY[I]="${_MONORAIL_TEXT:I:1}"
done
fi
_MONORAIL_TEXT_ARRAY_LEN=${#_MONORAIL_TEXT_ARRAY[@]}
local RGB_CUR_COLOR RGB_CUR_R RGB_CUR_GB RGB_CUR_G RGB_CUR_B
if [[ $_MONORAIL_CACHE != "$COLUMNS$_MONORAIL_TEXT" ]];then
unset _MONORAIL_DATE _MONORAIL_CACHE "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]" _MEASURE
if [[ ! -f "$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".sh ]];then
LC_ALL=C LC_MESSAGES=C \cat "$_MONORAIL_DIR"/colors/Default.sh "$_MONORAIL_DIR"/gradients/Default.sh > "$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".sh 2>&-
fi
# shellcheck disable=SC1090,SC1091 # file will be copied
. "$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".sh
local I=0
_MONORAIL_LINE=
while [[ $I -lt $COLUMNS ]]
do
_MONORAIL_LINE+=$'\e'"[38;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*I/$((COLUMNS+1))))]}m"$'\xe2\x96\x81'
I=$((I+1))
done
local I=0
if [[ -z ${_PROMPT_LUT[0]} ]];then
_MONORAIL_TEXT_FORMATTED="$_MONORAIL_PREHIDE"$'\e'"[0;7m${_MONORAIL_POSTHIDE}"
while [[ $I -lt ${_MONORAIL_TEXT_ARRAY_LEN} ]];do
_MONORAIL_TEXT_FORMATTED+="${_MONORAIL_TEXT_ARRAY[I]}"
I=$((I+1))
done
_MONORAIL_TEXT_FORMATTED+="$_MONORAIL_PREHIDE"$'\e'"[0;8m${_MONORAIL_POSTHIDE}▎"
else
_MONORAIL_TEXT_FORMATTED=
[[ -z ${_PROMPT_TEXT_LUT[*]} ]] && _PROMPT_TEXT_LUT[0]="255;255;255"
while [[ $I -lt ${_MONORAIL_TEXT_ARRAY_LEN} ]];do
_MONORAIL_TEXT_FORMATTED+="$_MONORAIL_PREHIDE"$'\e'"[48;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*I/$((COLUMNS+1))))]}m"$'\e'"[38;2;${_PROMPT_TEXT_LUT[$(((${#_PROMPT_TEXT_LUT[*]}*I)/$((COLUMNS+1))))]}m$_MONORAIL_POSTHIDE${_MONORAIL_TEXT_ARRAY[I]}"
I=$((I+1))
done
# the invisible vertical bar is added to make the prompt displayed better when copied to a chat or text doc
# this is not normally visible, but on some terminals not supporting ^[8m it will fall back the same color as the monorail bar
_MONORAIL_TEXT_FORMATTED+="$_MONORAIL_PREHIDE"$'\e'"[0;8m"$'\e'"[38;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*I/$((COLUMNS+1))))]}m$_MONORAIL_POSTHIDE▎"
fi
RGB_CUR_COLOR=${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*$((_MONORAIL_TEXT_ARRAY_LEN+1))/$((COLUMNS+1))))]}
RGB_CUR_R=${RGB_CUR_COLOR%%;*}
RGB_CUR_GB=${RGB_CUR_COLOR#*;}
RGB_CUR_G=${RGB_CUR_GB%%;*}
RGB_CUR_B=${RGB_CUR_GB##*;}
HEX_CURSOR_COLOR=$(\printf "%.2x%.2x%.2x" "$RGB_CUR_R" "$RGB_CUR_G" "$RGB_CUR_B" 2>&-)
[[ ${_PROMPT_LUT[0]} ]]||HEX_CURSOR_COLOR="${_COLORS[21]}"
_MONORAIL_CACHE="$COLUMNS$_MONORAIL_TEXT"
fi
# shellcheck disable=SC2059 # keep printf compact
printf "\e]11;#${_COLORS[17]}#\a\e]10;#${_COLORS[16]}\a\e]12;#$HEX_CURSOR_COLOR\a\e]4;0;#${_COLORS[0]}\a\e]4;1;#${_COLORS[1]}\a\e]4;2;#${_COLORS[2]}\a\e]4;3;#${_COLORS[3]}\a\e]4;4;#${_COLORS[4]}\a\e]4;5;#${_COLORS[5]}\a\e]4;6;#${_COLORS[6]}\a\e]4;7;#${_COLORS[7]}\a\e]4;8;#${_COLORS[8]}\a\e]4;9;#${_COLORS[9]}\a\e]4;10;#${_COLORS[10]}\a\e]4;11;#${_COLORS[11]}\a\e]4;12;#${_COLORS[12]}\a\e]4;13;#${_COLORS[13]}\a\e]4;14;#${_COLORS[14]}\a\e]4;15;#${_COLORS[15]}\a"

# shellcheck disable=SC2025,SC1078,SC1079 # no need to enclose in \[ \] as cursor position is calculated from after newline, quoting is supposed to span multiple lines
PS1=$'\e'"]0;"'$_MONORAIL_TITLE'$'\a'$'\r'$'\e'"[0m$_MONORAIL_LINE
$_MONORAIL_PREHIDE$_MONORAIL_POSTHIDE$_MONORAIL_TEXT_FORMATTED$_MONORAIL_PREHIDE"$'\e'"[0m"$'\e'"[?25h${_MONORAIL_POSTHIDE}"
unset _MONORAIL_NOSTYLING
}
_TITLE(){
if [[ $_MEASURE ]];then
_TITLE_RAW "$* in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M 2>&-)"
else
_TITLE_RAW "$* in ${PWD##*/}"
fi
}
_NO_MEASURE(){
unset _MEASURE
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
[[ "$ICON" ]] && if [[ -z "$FIRST_NON_OPTION" ]];then
_TITLE "$ICON  ${FIRST_ARG##*/}"
else
_TITLE "$ICON  ${FIRST_NON_OPTION##*/}"
fi
) >&- 2>&-
fi
"$@"
}
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
echo -e "\e[?25l\e[3A\r\e[K$SPACES$ANSWER"
}

_MONORAIL_COMMAND(){
local CMD_STATUS
CMD_STATUS=$?
printf "%$((COLUMNS-1))s\\r"
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
printf "\e[J\n\n"
fi
;;
2)CR_LEVEL=3
\git -c color.status=always status|\head -n$((LINES-2))|\head -n$((LINES-4))
echo -e "        ...\n\n"
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
trap "_MONORAIL_CTRLC=1;echo -n" INT
trap "_MONORAIL_CTRLC=1;echo -n" ERR
[[ $BASH_VERSION ]]&&history -a >&- 2>&-
}

if [[ "$TERM" = "xterm-256color" ]] && [[ $COLORTERM = "truecolor" ]];then
# blank terminal at startup to reduce flicker
printf '\e]0; \a\e[?25l' >/dev/tty 2>&-
elif [[ "$MC_TMPDIR" ]];then
unalias git >/dev/null 2>/dev/null
. "$_MONORAIL_DIR/monorail.compat.sh"
else
case "$TERM" in
"rxvt-unicode-256color"|"alacritty"|"rio"|"xterm-kitty"|"xterm-ghostty")
printf '\e]0; \a\e[?25l' >/dev/tty 2>&-
# ghostty adds a ssh function which causes parsing error since monorail adds an ssh alias
[[ "$TERM" = "xterm-ghostty" ]] && unalias ssh 2>/dev/null
;;
"ansi" | "tek"* | "ibm-327"* | "dp33"?? | "dumb" | "wyse60" | "dm2500" | "adm3a" | "vt"* | "linux" | "xterm-color" | "wsvt"* | "cons"* | "pc"* | "xterm-16color" | "xgterm" | "screen."* | "Eterm" | "tty"* | "tn"* | "ti"* | "cygwin")
# needed to avoid syntax error in monorail.compat.sh
unalias git >/dev/null 2>/dev/null
. "$_MONORAIL_DIR/monorail.compat.sh"
;;
*)
printf '\e]0; \a\e[?25l' >/dev/tty 2>&-
if [[ "$COLORTERM" = "truecolor" ]] || [[ "$XTERM_VERSION" ]];then
:
else
# COLORTERM may be filtered (eg. by SSH) or missing (eg. in xterm)
# manual detection is needed
# detect if truecolor sequence is parsed and not printed
# multiple terminals supports truecolor but not reporting of color
printf '\e[48:2:1:2:3m\e[6n\e[0m\e]0g' >/dev/tty
read -r -t 0.5 -n7 _MONORAIL_RESPONSE
case "$_MONORAIL_RESPONSE" in
*";1R")
# restore color after detection, needed for xterm
# shellcheck disable=SC2059 # keep printf compact
printf "\e]11;#${_COLORS[17]}\a\e]10;#${_COLORS[16]}\a\e]12;#${_COLORS[21]}\a" >/dev/tty 2>&-
;;
*)
unalias git >/dev/null 2>/dev/null
. "$_MONORAIL_DIR/monorail.compat.sh"
esac
fi
esac
:
fi
if [[ $SSH_CLIENT ]] || [[ $TMUX ]];then
_MONORAIL_HAS_SUFFIX=1
_MONORAIL_SUFFIX () {
_MONORAIL_TITLE="$_MONORAIL_TITLE on $_MONORAIL_SHORT_HOSTNAME"
}
elif [[ -e /.dockerenv ]];then
_MONORAIL_HAS_SUFFIX=1
_MONORAIL_SUFFIX () {
_MONORAIL_TITLE="$_MONORAIL_TITLE on docker"
}
fi
# shellcheck disable=SC2139
alias monorail_color="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR $ZSH_NAME$BASH $_MONORAIL_DIR/scripts/color.sh"
# shellcheck disable=SC2139
alias monorail_gradient="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR $ZSH_NAME$BASH $_MONORAIL_DIR/scripts/gradient.sh"
# shellcheck disable=SC2139
alias monorail_image="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR $ZSH_NAME$BASH $_MONORAIL_DIR/scripts/image.sh"
# shellcheck disable=SC2139
alias monorail_textgradient="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR $ZSH_NAME$BASH $_MONORAIL_DIR/scripts/gradient.sh --text"
# shellcheck disable=SC2139
alias rgb="bash $_MONORAIL_DIR/scripts/rgb.sh"
} >&- 2>&-
