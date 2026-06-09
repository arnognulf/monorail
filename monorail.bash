#!/bin/bash
# Copyright (c) 2025 Thomas Eriksson
#
# Contains code from bash-preexec
# Copyright (c) 2017 Ryan Caloras and contributors (see https://github.com/rcaloras/bash-preexec)
# SPDX-License-Identifier: BSD-3-Clause
# see FAST_SHELL_GUIDELINES.md on coding guidelines for this file.
{
[[ $_MONORAIL_DIR ]]||_MONORAIL_DIR=$HOME/.local/share/monorail
[[ $HOSTNAME ]]||HOSTNAME=$(hostname)
if [[ $CRAFT_STATE_DIR ]];then
_MONORAIL_SHORT_HOSTNAME=snapcraft
_MONORAIL_HAS_SUFFIX=1
_MONORAIL_SUFFIX () {
_MONORAIL_TITLE="$_MONORAIL_TITLE on $_MONORAIL_SHORT_HOSTNAME"
}
elif [[ $SSH_CLIENT ]]||[[ $TMUX ]];then
_MONORAIL_HAS_SUFFIX=1
_MONORAIL_SUFFIX () {
_MONORAIL_TITLE="$_MONORAIL_TITLE on $_MONORAIL_SHORT_HOSTNAME"
}
_MONORAIL_SHORT_HOSTNAME=${HOSTNAME%%.*}
elif [[ -e /.dockerenv ]];then
_MONORAIL_SHORT_HOSTNAME=docker
_MONORAIL_HAS_SUFFIX=1
_MONORAIL_SUFFIX () {
_MONORAIL_TITLE="$_MONORAIL_TITLE on $_MONORAIL_SHORT_HOSTNAME"
}
elif [[ -e /run/containerenv ]];then
_MONORAIL_HAS_SUFFIX=1
_MONORAIL_SHORT_HOSTNAME=podman
_MONORAIL_SUFFIX () {
_MONORAIL_TITLE="$_MONORAIL_TITLE on $_MONORAIL_SHORT_HOSTNAME"
}
else
_MONORAIL_SHORT_HOSTNAME=${HOSTNAME%%.*}
fi
if [[ $ZSH_NAME ]];then
setopt KSH_ARRAYS
setopt prompt_subst
_MONORAIL_PREHIDE='%{'
_MONORAIL_POSTHIDE='%}'
_MONORAIL_SHORT_HOSTNAME=${_MONORAIL_SHORT_HOSTNAME:l}
elif [[ $BRUSH_VERSION ]];then
_MONORAIL_COMPAT=1
else
_MONORAIL_SHORT_HOSTNAME=${_MONORAIL_SHORT_HOSTNAME,,}
_MONORAIL_PREHIDE='\['
_MONORAIL_POSTHIDE='\]'

__bp_last_argument_prev_command=$_
unset __bp_inside_preexec
__bp_preexec_interactive_mode=
declare -a preexec_functions

__bp_preexec_interactive_mode=1
__bp_preexec_invoke_exec(){
[[ $_MONORAIL_CACHE ]]||return
__bp_last_argument_prev_command=${1:-}
[[ $__bp_inside_preexec ]]&&return
local __bp_inside_preexec=1
[[ ! -t 1 ]]&&return
if [[ ${COMP_POINT:-} || ${READLINE_POINT:-} ]];then
return
fi
if [[ ${__bp_preexec_interactive_mode:-} ]];then
if [[ 0 -eq ${BASH_SUBSHELL:-} ]];then
__bp_preexec_interactive_mode=
else
return
fi
fi
local prompt_command_array IFS=$'\n;'
read -rd '' -a prompt_command_array <<<"${PROMPT_COMMAND[*]:-}"
local arg=${BASH_COMMAND:-}
arg=${arg#"${arg%%[![:space:]]*}"}
arg=${arg%"${arg##*[![:space:]]}"}
local cmd
for cmd in "${prompt_command_array[@]:-}";do
cmd=${cmd#"${cmd%%[![:space:]]*}"}
cmd=${cmd%"${cmd##*[![:space:]]}"}
[[ $cmd = "$arg" ]]&&return
done
local this_command
this_command=$(LC_ALL=C HISTTIMEFORMAT='' builtin history 1)
this_command=${this_command#*[[:digit:]][* ] }
[[ -z $this_command ]]&&return
local preexec_function
for preexec_function in "${preexec_functions[@]:-}";do
if type -t "$preexec_function" >/dev/null;then
if [[ ${__bp_last_ret_value-0} = 0 ]];then
:
else
(exit "${__bp_last_ret_value-0}")
fi
"$preexec_function" "$this_command"
fi
done
return "${__bp_last_ret_value-0}"
}
__bp_install(){
[[ ${PROMPT_COMMAND[*]:-} = *"precmd"* ]]&&return 1
trap '__bp_preexec_invoke_exec "$_"' DEBUG
eval "local trap_argv=(${__bp_trap_string:-})"
local prior_trap=${trap_argv[2]:-}
unset __bp_trap_string
if [[ $prior_trap ]];then
eval '__bp_original_debug_trap() {
            '"$prior_trap"'
        }'
preexec_functions+=(__bp_original_debug_trap)
fi
local histcontrol
histcontrol=${HISTCONTROL:-}
histcontrol=${histcontrol//ignorespace/}
if [[ $histcontrol = *"ignoreboth"* ]];then
histcontrol=ignoredups:${histcontrol//ignoreboth/}
fi
export HISTCONTROL=$histcontrol
local cur_prompt_cmd
cur_prompt_cmd=${PROMPT_COMMAND:-}
cur_prompt_cmd=${cur_prompt_cmd//$'__bp_trap_string="$(trap -p DEBUG)"\ntrap - DEBUG\n__bp_install'/:}
cur_prompt_cmd=${cur_prompt_cmd//$'\n':$'\n'/$'\n'}
cur_prompt_cmd=${cur_prompt_cmd//$'\n':;/$'\n'}
cur_prompt_cmd=${cur_prompt_cmd#"${cur_prompt_cmd%%[![:space:]]*}"}
cur_prompt_cmd=${cur_prompt_cmd%"${cur_prompt_cmd##*[![:space:]]}"}
cur_prompt_cmd=${cur_prompt_cmd%;}
cur_prompt_cmd=${cur_prompt_cmd#;}
[[ ${cur_prompt_cmd:-:} = ":" ]]&&cur_prompt_cmd=
PROMPT_COMMAND='precmd'
PROMPT_COMMAND+=${cur_prompt_cmd:+$'\n'$cur_prompt_cmd}
PROMPT_COMMAND+=('__bp_preexec_interactive_mode=1')
preexec_functions+=(preexec)
__bp_inside_precmd=1 precmd
__bp_preexec_interactive_mode=1
}
prompt_cmd=${PROMPT_COMMAND:-}
prompt_cmd=${prompt_cmd#"${prompt_cmd%%[![:space:]]*}"}
prompt_cmd=${prompt_cmd%"${prompt_cmd##*[![:space:]]}"}
prompt_cmd=${prompt_cmd%;}
prompt_cmd=${prompt_cmd#;}

[[ $prompt_cmd ]]&&PROMPT_COMMAND=("$prompt_cmd")
PROMPT_COMMAND+=($'__bp_trap_string="$(trap -p DEBUG)"\ntrap - DEBUG\n__bp_install')
fi
preexec(){
{
local FC=$(fc -l -1)
# TODO: report and move to bash-preexec: SIGWINCH causes preexec to run again
[[ $FC = "$_MONORAIL_PREV_CMD" ]]&&return
_MONORAIL_PREV_CMD=$FC
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
local XCMD IGNORED_TITLE=
for XCMD in "${_MONORAIL_CMD_IGNORED[@]}"
do
[[ $XCMD = "${_TIMER_CMD%% *}" ]]&&IGNORED_TITLE=1
done
ICON="*️⃣"
_MONORAIL_TITLE="$ICON  $_TIMER_CMD"
[[ $_MONORAIL_HAS_SUFFIX ]]&&_MONORAIL_SUFFIX
CMD=${_TIMER_CMD%% *}
CMD=${CMD%%;*}
unset _MONORAIL_CUSTOM_TITLE
alias "$CMD" >&- 2>&-&&_MONORAIL_CUSTOM_TITLE=1
for COMMAND in "${CUSTOM_TITLE_COMMANDS[@]}";do
[[ $COMMAND = "${_TIMER_CMD:0:${#COMMAND}}" ]]&&_MONORAIL_CUSTOM_TITLE=1
done
_MEASURE=1
_START_SECONDS=$SECONDS
_MONORAIL_TITLE+=" in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M)"
local _MONORAIL_TITLE_FORMATTED=
[[ $IGNORED_TITLE ]]||_MONORAIL_TITLE_FORMATTED=$'\e'"]0;"$_MONORAIL_TITLE$'\a\r\e[K'
[[ $_MONORAIL_HAS_SUFFIX ]]&&_MONORAIL_SUFFIX
# shellcheck disable=SC2059 # keep printf compact
printf "$_MONORAIL_TITLE_FORMATTED\e]11;#${_COLORS[17]}\a\e]10;#${_COLORS[16]}\a\e]12;#${_COLORS[21]}\a\r\e[K" >/dev/tty 2>&-
unset _MONORAIL_CUSTOM_TITLE
# zsh cannot have closed fd's here
} &>/dev/null
}
_monorail_gradient ()
{
unset "_PROMPT_LUT[*]"
_PROMPT_LUT=()
while [[ $1 ]];do
_PROMPT_LUT[${#_PROMPT_LUT[@]}]=$1
shift
done
}
_monorail_textgradient ()
{
unset "_PROMPT_TEXT_LUT[*]"
_PROMPT_TEXT_LUT=()
while [[ $1 ]];do
_PROMPT_TEXT_LUT[${#_PROMPT_TEXT_LUT[@]}]=$1
shift
done
}
_monorail_colors ()
{
unset "_COLORS[*]"
_COLORS=()
while [[ "$1" ]];do
_COLORS[${#_COLORS[@]}]=$1
shift
done
}
_MONORAIL_SET_TITLE(){
unset _MONORAIL_TITLE_OVERRIDE
[[ $1 ]]&&_MONORAIL_TITLE_OVERRIDE=$*
}
alias title=_MONORAIL_SET_TITLE
_MONORAIL_SET_ICON(){
unset _MONORAIL_ICON_OVERRIDE
[[ $1 ]]&&_MONORAIL_ICON_OVERRIDE=$*
}
alias icon=_MONORAIL_SET_ICON
_TITLE_RAW(){
[[ $_MONORAIL_NOSTYLING ]]&&return 0
printf "\e]0;%s\a\r\e[K" "$*" >/dev/tty 2>&-
}
[[ ! $_MONORAIL_CONFIG ]]&&_MONORAIL_CONFIG=$HOME/.config/monorail
_MONORAIL_NAME(){
unset NAME
[[ $1 ]]&&NAME=$*
}
alias name=_MONORAIL_NAME
precmd(){
{
if [[ $_MONORAIL_LAUNCHED ]];then
# bash line editor (ble.sh) do not like others messing with the tty
# enable stty echo in case some command has disabled it up
[[ $BLE_ATTACHED ]]||LC_MESSAGES=C LC_ALL=C stty echo >/dev/tty
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
[[ $DURATION_H -gt 0 ]]&&DURATION="${DURATION_H}h "
[[ $DURATION_M -gt 0 ]]&&DURATION+="${DURATION_M}m "
DURATION+="${DURATION_S}s, finished at "$(LC_MESSAGES=C LC_ALL=C date +%H:%M).
echo "$DURATION"
(exec notify-send -a "Completed $_TIMER_CMD" -i terminal "$_TIMER_CMD" "Command took $DURATION"&)
(exec mplayer -quiet /usr/share/sounds/gnome/default/alerts/glass.ogg >&- 2>&-&)
_MONORAIL_LONGRUNNING=1
fi
unset _MEASURE
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
elif [[ $_MONORAIL_PENULTIMATE = "$_MONORAIL_HISTCMD_PREV" ]];then
if [[ -z $_MONORAIL_CR_FIRST ]] &&[[ $CMD_STATUS = 0 ]]&&[[ -z $_MONORAIL_CTRLC ]];then
case $CR_LEVEL in
0)ls
CR_LEVEL=3
if \git status;then
CR_LEVEL=1
else
printf "\e[J\n\n" >/dev/tty
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
[[ $BASH_VERSION ]]&&history -a
if [[ $_MONORAIL_LONGRUNNING ]] ;then
_MONORAIL_TITLE="✅ Completed $_TIMER_CMD"
[[ $_MONORAIL_HAS_SUFFIX ]]&&_MONORAIL_SUFFIX
unset _MONORAIL_LONGRUNNING
return 0
fi
else
alias for='_MONORAIL_NOSTYLING=1;for'
alias while='_MONORAIL_NOSTYLING=1;while'
alias until='_MONORAIL_NOSTYLING=1;until'
_MONORAIL_LAUNCHED=1
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
PROMPT_PWD=${PROMPT_PWD%/*}
done
if [[ -z $_MONORAIL_GIT_LOADED ]];then
local DIR
DIR=$PWD
while [[ $DIR ]];do
if [[ -e "$DIR/.git" ]]&&[[ -e /usr/lib/git-core/git-sh-prompt ]];then
. /usr/lib/git-core/git-sh-prompt
_MONORAIL_GIT_LOADED=1
fi
DIR=${DIR%/*}
done
fi
# shellcheck disable=SC2329 # _TITLE function is invoked by __git_ps1 which is assigned later
_MONORAIL_GIT_PS1=$(_TITLE () { shift;"$@";};TERM=dumb GIT_CONFIG_GLOBAL= LC_MESSAGES=C LC_ALL=C __git_ps1 "")
esac
local ICON TITLE_BASE
TITLE_BASE=${PWD##*/}
if [[ $MONORAIL_REPO ]];then
ICON=🏗️
elif [[ $_MONORAIL_GIT_PS1 ]];then
ICON=🚧
else
case $PWD in
*/etc|*/etc/*)ICON=🗂️;;
*/bin|*/sbin)ICON=⚙️ ;;
*/lib|*/lib64|*/lib32)ICON=🔩;;
*/tmp|*/tmp/*|*/.cache|*/.cache/*)ICON=🚽;;
"$HOME/Trash"*)ICON=🗑️;;
"$HOME/.local/share/Trash/files"*)ICON=♻️;;
/boot|/boot/*)ICON=🥾;;
/)ICON=💻; TITLE_BASE=/;;
*/.*)ICON=📌;;
/media/*)ICON=💾;;
/proc/*|/sys/*|/dev/*|/proc|/sys|/dev)ICON=🤖;;
*/Documents|*/Documents/*|*/doc|*/docs|*/doc/*|*/docs/*|"$XDG_DOCUMENTS_DIR"|"$XDG_DOCUMENTS_DIR"/*)ICON=📑;;
*/out|*/out/*)ICON="🚀  ${PWD##*/}";;
*/src|*/src/*|*/sources|*/sources/*)ICON=🚧;;
"$XDG_MUSIC_DIR"|"$XDG_MUSIC_DIR"/*)ICON=🎵;;
"$XDG_PICTURES_DIR"|"$XDG_PICTURES_DIR"/*)ICON=🖼️;;
"$XDG_VIDEOS_DIR"|"$XDG_VIDEOS_DIR"/*)ICON=🎬;;
*/Downloads|*/Downloads/*|"$XDG_DOWNLOAD_DIR"|"$XDG_DOWNLOAD_DIR"/*)ICON=📦;;
*)ICON=📂
esac
case $_MONORAIL_REALPWD in
"$HOME")
if [[ $CRAFT_STATE_DIR ]];then
TITLE_BASE=$_MONORAIL_SHORT_HOSTNAME
ICON=🛠️
elif [[ $SSH_CLIENT ]]
then
TITLE_BASE=$_MONORAIL_SHORT_HOSTNAME
ICON=🌐
elif [[ -e /.dockerenv ]]
then
TITLE_BASE=$_MONORAIL_SHORT_HOSTNAME
ICON=🐋
elif [[ -e /run/containerenv ]]
then
TITLE_BASE=$_MONORAIL_SHORT_HOSTNAME
ICON=🦭
else
ICON=🏠
TITLE_BASE=$_MONORAIL_SHORT_HOSTNAME
fi
;;
*)
esac
fi
_MONORAIL_TITLE="${_MONORAIL_ICON_OVERRIDE-${ICON}}  ${_MONORAIL_TITLE_OVERRIDE-${TITLE_BASE}}"
[[ $PWD != "$HOME" ]]&&[[ $_MONORAIL_HAS_SUFFIX ]]&&_MONORAIL_SUFFIX
local PWD_BASENAME=${PWD##*/}
[[ $PWD_BASENAME ]]||PWD_BASENAME=/
case $PWD in
"$HOME")_MONORAIL_PWD_BASENAME=\~;;
*)_MONORAIL_PWD_BASENAME=${NAME-$PWD_BASENAME}
esac
_MONORAIL_TEXT=" $_MONORAIL_PWD_BASENAME$_MONORAIL_GIT_PS1 "
_MONORAIL_ELIPSIS=$'\xe2\x80\xa6'
_MONORAIL_TEXT=${_MONORAIL_TEXT//\.\.\./${_MONORAIL_ELIPSIS}}
if [[ ${#_MONORAIL_TEXT} -gt $((COLUMNS / 3)) ]];then
# frequently, the last of the text is the most relevant, cut beginning if too long path
_MONORAIL_TEXT=" ${_MONORAIL_ELIPSIS}${_MONORAIL_TEXT:$((${#_MONORAIL_TEXT} -  $((COLUMNS / 3))))}"
fi
_MONORAIL_TEXT_ARRAY=()
if [[ $ZSH_NAME ]]
then
for ((I=0; I < ${#_MONORAIL_TEXT}; I++))
do
_MONORAIL_TEXT_ARRAY[I]=${_MONORAIL_TEXT[I]}
done
else
for ((I=0; I < ${#_MONORAIL_TEXT}; I++))
do
_MONORAIL_TEXT_ARRAY[I]=${_MONORAIL_TEXT:I:1}
done
fi
_MONORAIL_TEXT_ARRAY_LEN=${#_MONORAIL_TEXT_ARRAY[@]}
local RGB_CUR_COLOR RGB_CUR_R RGB_CUR_GB RGB_CUR_G RGB_CUR_B
if [[ $_MONORAIL_CACHE != "$COLUMNS$_MONORAIL_TEXT" ]];then
unset _MONORAIL_CACHE "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]" _MEASURE
if [[ ! -f "$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".conf ]];then
mkdir -p "$_MONORAIL_CONFIG"
if [[ -f "$_MONORAIL_DIR/gradients/Default.conf" ]];then
if [[ $(gsettings get org.gnome.desktop.interface color-scheme) = prefer-dark ]];then
LC_ALL=C LC_MESSAGES=C \cat "$_MONORAIL_DIR"/colors/DefaultDark.conf "$_MONORAIL_DIR"/gradients/Default.conf > "$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".conf 2>&-
else
LC_ALL=C LC_MESSAGES=C \cat "$_MONORAIL_DIR"/colors/Default.conf "$_MONORAIL_DIR"/gradients/Default.conf > "$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".conf 2>&-
fi
else
printf "\
monorail: warning: Monorail was not found in $_MONORAIL_DIR.
                   Do this to make colors and gradients work:
                     1. Move monorail directory to $_MONORAIL_DIR
                     2. rm -rf $_MONORAIL_CONFIG
                     3. Restart terminal." >/dev/tty
fi
fi
# shellcheck disable=SC1090,SC1091 # file will be copied
. "$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".conf
local I=0
_MONORAIL_LINE=
_MONORAIL_UNDERLINE=
while [[ $I -lt $COLUMNS ]]
do
_MONORAIL_LINE+=$'\e'"[38;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*I/$((COLUMNS+1))))]}m"$'\xe2\x96\x81'
I=$((I+1))
done
_MONORAIL_LINE+=$'\e'"[38;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*I/$((COLUMNS+1))))]}m"$'\xe2\x96\x81'
local I=0
if [[ -z ${_PROMPT_LUT[0]} ]];then
_MONORAIL_TEXT_FORMATTED=$_MONORAIL_PREHIDE$'\e'"[0;7m${_MONORAIL_POSTHIDE}"
while [[ $I -lt ${_MONORAIL_TEXT_ARRAY_LEN} ]];do
_MONORAIL_TEXT_FORMATTED+=${_MONORAIL_TEXT_ARRAY[I]}
I=$((I+1))
done
_MONORAIL_TEXT_FORMATTED+=$_MONORAIL_PREHIDE$'\e[0;8m'"${_MONORAIL_POSTHIDE}|"
else
_MONORAIL_TEXT_FORMATTED=
[[ -z ${_PROMPT_TEXT_LUT[*]} ]]&&_PROMPT_TEXT_LUT[0]="255;255;255"
while [[ $I -lt ${_MONORAIL_TEXT_ARRAY_LEN} ]];do
_MONORAIL_TEXT_FORMATTED+="$_MONORAIL_PREHIDE"$'\e['"$((_MONORAIL_TEXT_ARRAY_LEN + 1))C"$'\e'["$((_MONORAIL_TEXT_ARRAY_LEN + 1))"D$'\e'"[48;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*I/$((COLUMNS+1))))]}m"$'\e'"[38;2;${_PROMPT_TEXT_LUT[$((${#_PROMPT_TEXT_LUT[*]}*I/$((COLUMNS+1))))]}m$_MONORAIL_POSTHIDE${_MONORAIL_TEXT_ARRAY[I]}"
I=$((I+1))
done
# The invisible vertical bar is added to make the prompt more readable when copied to a chat or text doc.
# This is not normally visible if your terminal supports "invisible SGR8" `^[8m`
# Notably PuTTY, Kitty, rxvt-unicode, zutty, and cool-retro-term does not support these.
# In this case the horizontal bar is colored with background color.
_MONORAIL_TEXT_FORMATTED+="$_MONORAIL_PREHIDE"$'\e'"[0;8m"$'\e'"[38;2;$((0x${_COLORS[17]:0:2}));$((0x${_COLORS[17]:2:2}));$((0x${_COLORS[17]:4:2}))m$_MONORAIL_POSTHIDE|"
fi
RGB_CUR_COLOR=${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*$((_MONORAIL_TEXT_ARRAY_LEN+1))/$((COLUMNS+1))))]}
RGB_CUR_R=${RGB_CUR_COLOR%%;*}
RGB_CUR_GB=${RGB_CUR_COLOR#*;}
RGB_CUR_G=${RGB_CUR_GB%%;*}
RGB_CUR_B=${RGB_CUR_GB##*;}
HEX_CURSOR_COLOR=$(printf "%.2x%.2x%.2x" "$RGB_CUR_R" "$RGB_CUR_G" "$RGB_CUR_B")
[[ ${_PROMPT_LUT[0]} ]]||HEX_CURSOR_COLOR=${_COLORS[21]}
_MONORAIL_CACHE=$COLUMNS$_MONORAIL_TEXT
fi
# shellcheck disable=SC2059 # keep printf compact
unset _MONORAIL_NOSTYLING
# shellcheck disable=SC2025,SC1078,SC1079 # no need to enclose in \[ \] as cursor position is calculated from after newline, quoting is supposed to span multiple lines
PS1=$'\e[?7l\e]0;'$_MONORAIL_TITLE$'\a\e[0m\r'"$_MONORAIL_LINE
$_MONORAIL_TEXT_FORMATTED$_MONORAIL_PREHIDE"$'\r\e['$((${#_MONORAIL_TEXT} + 1))C$'\e[?7h\e[?25h\e]12;#$HEX_CURSOR_COLOR\a\e[0m'"${_MONORAIL_POSTHIDE}"

} >&- 2>&-
printf "\e[?25l\e[?7l\e[${COLUMNS}C\e]11;#${_COLORS[17]}\a\e]10;#${_COLORS[16]}\a\e]4;0;#${_COLORS[0]}\a\e]4;1;#${_COLORS[1]}\a\e]4;2;#${_COLORS[2]}\a\e]4;3;#${_COLORS[3]}\a\e]4;4;#${_COLORS[4]}\a\e]4;5;#${_COLORS[5]}\a\e]4;6;#${_COLORS[6]}\a\e]4;7;#${_COLORS[7]}\a\e]4;8;#${_COLORS[8]}\a\e]4;9;#${_COLORS[9]}\a\e]4;10;#${_COLORS[10]}\a\e]4;11;#${_COLORS[11]}\a\e]4;12;#${_COLORS[12]}\a\e]4;13;#${_COLORS[13]}\a\e]4;14;#${_COLORS[14]}\a\e]4;15;#${_COLORS[15]}\a\r" >/dev/tty

}
_TITLE(){
local _MONORAIL_TITLE=$*
if [[ $_MEASURE ]];then
_MONORAIL_TITLE+=" in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M 2>&-)"
elif [[ $PWD = "$HOME" ]];then
:
else
_MONORAIL_TITLE+=" in ${PWD##*/}"
fi
[[ $_MONORAIL_HAS_SUFFIX ]]&&_MONORAIL_SUFFIX
_TITLE_RAW "$_MONORAIL_TITLE"
}
_NO_MEASURE(){
unset _MEASURE
"$@"
}
_ICON(){
local ICON="$1"
shift
if [[ -z ${FUNCNAME[1]} ]]||[[ ${FUNCNAME[1]} = "_NO_MEASURE" ]];then
local FIRST_ARG="$1"
(case $FIRST_ARG in
_*)shift
esac
FIRST_ARG="$1"
FIRST_NON_OPTION="$2"
while [[ ${FIRST_NON_OPTION:0:1} = '-' ]]||[ "${FIRST_NON_OPTION:0:1}" = '_' ]||[ "$FIRST_NON_OPTION" = '.' ];do
if [ "$FIRST_NON_OPTION" = '-u' ];then
shift 2
else
shift
fi
FIRST_NON_OPTION="$2"
done
[[ $ICON ]]&&if [[ -z "$FIRST_NON_OPTION" ]];then
_TITLE "${_MONORAIL_ICON_OVERRIDE-${ICON}}  ${FIRST_ARG##*/}"
else
_TITLE "${_MONORAIL_ICON_OVERRIDE-${ICON}}  ${FIRST_NON_OPTION##*/}"
fi
) >&- 2>&-
fi
"$@"
}
trap "unset _MONORAIL_CACHE" WINCH
_LOW_PRIO(){
if type -P chrt&&type -P ionice&&type -P ionice;then
_LOW_PRIO(){
# As an ordinary user, you cannot raise the priority and mark the importance
# of a process.
# However, you can mark which processes are less important than low-prio tasks
# such as video calls or music.
# The idea is to mark batch processes as less important to get better 
# interactivity.
#
# `choom -n +1000` will make the OOM killer kill this process first
# `ionice -c idle` will deprioritize IO from this process
# `chrt --idle 0`  will set the cpu priority to the lowest possible
choom -n +1000 -- ionice -c idle -- chrt --idle 0 "$@"
}
else
_LOW_PRIO(){
# `nice -n19` is the lowest priority on non-Linux systems
nice -n19 "$@"
}
# zsh cannot handle closed stdout here
fi >&- 2>/dev/null
_LOW_PRIO "$@"
}
# shellcheck disable=SC2329
_monorail_cmd_interactive(){
# shellcheck disable=SC2139 # variable is intended to be set when defined
command -v "$2"&&alias "$2=_NO_MEASURE _ICON $1 $2"
}
# shellcheck disable=SC2329
_monorail_cmd_batch(){
# shellcheck disable=SC2139
command -v "$2"&&alias "$2=_ICON $1 _LOW_PRIO $2"
}
_MONORAIL_CMD_IGNORED=()
_monorail_cmd_ignored (){
_MONORAIL_CMD_IGNORED[${#_MONORAIL_CMD_IGNORED[@]}]=$1
}
[[ -e $_MONORAIL_CONFIG/commands-${_MONORAIL_SHORT_HOSTNAME}.conf ]]||cat "$_MONORAIL_DIR/commands/default.conf" > "$_MONORAIL_CONFIG/commands-${_MONORAIL_SHORT_HOSTNAME}.conf"
. "$_MONORAIL_CONFIG/commands-${_MONORAIL_SHORT_HOSTNAME}.conf"
__git_ps1(){ :;}
_MONORAIL_MAGIC_SHELLBALL(){
local A PAD i
PAD=
i=0
case $RANDOM in
*[0-4])case $RANDOM in
*0)A="IT IS CERTAIN.";;
*1)A="IT IS DECIDEDLY SO.";;
*2)A="WITHOUT A DOUBT.";;
*3)A="YES – DEFINITELY.";;
*4)A="YOU MAY RELY ON IT.";;
*5)A="AS I SEE IT, YES.";;
*6)A=MOST\ LIKELY.;;
*7)A=OUTLOOK\ GOOD.;;
*8)A=YES.;;
*)A="SIGNS POINT TO YES."
esac
;;
*)case $RANDOM in
*0)A="REPLY HAZY, TRY AGAIN.";;
*1)A="ASK AGAIN LATER.";;
*2)A="BETTER NOT TELL YOU NOW.";;
*3)A="CANNOT PREDICT NOW.";;
*4)A="CONCENTRATE AND ASK AGAIN.";;
*5)A="DON'T COUNT ON IT.";;
*6)A="MY REPLY IS NO.";;
*7)A="MY SOURCES SAY NO.";;
*8)A="OUTLOOK NOT SO GOOD.";;
*)A=VERY\ DOUBTFUL.
esac
esac
while [[ $i -lt $((COLUMNS/2-${#A}/2)) ]];do
PAD="$PAD "
i=$((i+1))
done
echo -e "\e[?25l\e[3A\r\e[K$PAD$A"
}
if [[ $TERM = xterm-256color ]];then
# zutty (vterm) doesn't handle background color, nor hidden text.
# thus the horizontal bar  "|" gets visible
[[ $ZUTTY_VERSION ]]&&_MONORAIL_COMPAT=1
# vscode does not support disabling line wrapping
# 
[[ $TERM_PROGRAM = vscode ]]&&_MONORAIL_COMPAT=1
elif [[ $MC_TMPDIR ]];then
_MONORAIL_COMPAT=1
else
case $TERM in
xterm-color|xterm-16color)
_MONORAIL_COMPAT=1
;;
xterm*|alacritty|rio|rxvt-unicode-256color|mlterm|st-256color|foot)
printf "\e[?25l\e[?7l\e[%sC\e]0; \a\r\e[K" "${COLUMNS}" >/dev/tty 2>&-
# ghostty adds a ssh function which causes parsing error since monorail adds an ssh alias
[[ $TERM = xterm-ghostty ]]&&unalias ssh 2>/dev/null
# FreeBSD console lacks UTF-8 and truecolor
[[ $(tty) =~ "/dev/ttyv"* ]]&&_MONORAIL_COMPAT=1
# cool-retro-term does not support invisible SGR8
[[ $WINDOWID = 0 ]]&&_MONORAIL_COMPAT=1
# if not using UTF-8 locale in xterm or not using xterm use compat
case $XTERM_LOCALE in
""|*.UTF-8):;;
*)_MONORAIL_COMPAT=1
esac
;;
*)
_MONORAIL_COMPAT=1
esac
fi
[[ $_MONORAIL_COMPAT ]]&&if [[ ! $_MONORAIL_DISABLE_COMPAT ]];then
unalias git >/dev/null 2>/dev/null
unset -f precmd preexec 2>/dev/null
. "$_MONORAIL_DIR/monorail.sh"
fi
# shellcheck disable=SC2139
alias monorail_color="_MONORAIL_SHORT_HOSTNAME=$_MONORAIL_SHORT_HOSTNAME _MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR sh $_MONORAIL_DIR/scripts/color.sh"
#shellcheck disable=SC2139
alias sh_monorail_color="_MONORAIL_SHORT_HOSTNAME=$_MONORAIL_SHORT_HOSTNAME _MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR sh $_MONORAIL_DIR/scripts/color.sh"
# shellcheck disable=SC2139
alias monorail_gradient="_MONORAIL_SHORT_HOSTNAME=$_MONORAIL_SHORT_HOSTNAME _MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR sh $_MONORAIL_DIR/scripts/gradient.sh"
# shellcheck disable=SC2139
alias monorail_image="_MONORAIL_SHORT_HOSTNAME=$_MONORAIL_SHORT_HOSTNAME _MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR sh $_MONORAIL_DIR/scripts/image.sh"
# shellcheck disable=SC2139
alias monorail_textgradient="_MONORAIL_SHORT_HOSTNAME=$_MONORAIL_SHORT_HOSTNAME _MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR sh $_MONORAIL_DIR/scripts/gradient.sh --text"
# shellcheck disable=SC2139
alias rgb="sh $_MONORAIL_DIR/scripts/rgb.sh"
} >&- 2>&-
