#!/bin/bash
{
if ! [[ $_MONORAIL_DIR ]];then
if [[ ${BASH_ARGV[0]} != "/"* ]];then
_MONORAIL_DIR=$PWD/${BASH_ARGV[0]}
else
_MONORAIL_DIR="${BASH_ARGV[0]}"
fi
_MONORAIL_DIR="${_MONORAIL_DIR%/*}"
fi
if [[ $ZSH_NAME ]];then
setopt KSH_ARRAYS
setopt prompt_subst
fi
_MONORAIL_INITIAL_CURSOR_WORKAROUND(){
printf "\e]12;#%s\a" "$_PROMPT_FGCOLOR" >/dev/tty 2>&-
}
_TITLE(){
_MONORAIL_INITIAL_CURSOR_WORKAROUND
_TITLE_RAW "$* in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M 2>&-)"
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
if [ -z "$FIRST_NON_OPTION" ];then
_TITLE "$ICON  ${FIRST_ARG##*/}"
else
_TITLE "$ICON  ${FIRST_NON_OPTION##*/}"
fi) >&- 2>&-
fi
"$@"
}
_MONORAIL_INVALIDATE_CACHE(){
unset _MONORAIL_DATE _MONORAIL_CACHE "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]" _MEASURE
if [[ ! -f $_MONORAIL_CONFIG/colors.sh ]];then
LC_ALL=C LC_MESSAGES=C \cp "$_MONORAIL_DIR"/colors/Default.sh "$_MONORAIL_CONFIG"/colors.sh >&- 2>&-
fi
. "$_MONORAIL_CONFIG"/colors.sh
}
trap _MONORAIL_INVALIDATE_CACHE WINCH
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
command -v "$2"&&alias "$2=_NO_MEASURE _ICON $1 $2"
}
# shellcheck disable=SC2329
_BATCH_COMMAND(){
command -v "$2"&&alias "$2=_ICON $1 _LOW_PRIO $2"
}
alias interactive_command=_INTERACTIVE_COMMAND
alias batch_command=_BATCH_COMMAND
. "$_MONORAIL_DIR"/default_commands.sh
unalias interactive_command batch_command
unset -f _INTERACTIVE_COMMAND _BATCH_COMMAND
__git_ps1(){ :;}
_MONORAIL_GIT_LAZYLOAD(){
local DIR
DIR="$PWD"
while [[ "$DIR" ]];do
if [[ -e "$DIR/.git" ]]&&[[ -e /usr/lib/git-core/git-sh-prompt ]];then
. /usr/lib/git-core/git-sh-prompt
# this function is mistankenly reported as not being called again
# shellcheck disable=SC2329
_MONORAIL_GIT_LAZYLOAD(){ :;}
fi
DIR=${DIR%/*}
done
}
. "$_MONORAIL_DIR"/bash-preexec/bash-preexec.sh
_MONORAIL_ALERT(){
(exec mplayer -quiet /usr/share/sounds/gnome/default/alerts/glass.ogg >&- 2>&-&)
}
_MONORAIL_MAGIC_SHELLBALL(){
local ANSWER SPACES i
SPACES=""
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
if _MONORAIL_DUMB_TERMINAL
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
# blank terminal at startup to reduce flicker
_MONORAIL_BLANK () {
printf '\e]0 ;m\e[?25l' >/dev/tty 2>&-
}
# xterm-256color is the TERM variable for `konsole` and `gnome-terminal`
# this is the "fast path", if this fails, more thorough testing is needed
if [[ $TERM = "xterm-256color" ]];then
_MONORAIL_BLANK
_MONORAIL_DUMB_TERMINAL () { false;}
_MONORAIL_SUPPORTED_TERMINAL(){ :;}
_MONORAIL_VTXXX_TERMINAL(){ false;}
_MONORAIL_MLTERM_TERMINAL(){ false;}
_MONORAIL_LINUX_TERMINAL(){ false;}
_MONORAIL_LINUX_TERMINAL(){ false;}
else 
if [[ $TERM = "mlterm" ]];then
_MONORAIL_MLTERM_TERMINAL(){ :;}
else
_MONORAIL_MLTERM_TERMINAL(){ false;}
fi
if [[ $TERM = "vt"??? ]];then
_MONORAIL_VTXXX_TERMINAL(){ :;}
else
_MONORAIL_VTXXX_TERMINAL(){ false;}
fi
if [[ $TERM = "linux" ]];then
_MONORAIL_LINUX_TERMINAL(){ :;}
else
_MONORAIL_LINUX_TERMINAL(){ false;}
fi
if [[ $TERM == "tek"* ]]||[[ $TERM == "ibm-327"* ]]||[[ $TERM == "dumb" ]]||[[ $TERM == "wyse60" ]]||[[ $TERM == "dm2500" ]]||[[ $TERM == "adm3a" ]]||[[ $TERM == "vt"?? ]];then
bind 'set enable-bracketed-paste off'
_MONORAIL_DUMB_TERMINAL(){
:
}
else
_MONORAIL_DUMB_TERMINAL(){
false
}
fi
if _MONORAIL_DUMB_TERMINAL;then
_MONORAIL_SUPPORTED_TERMINAL(){
false
}
elif [[ $TERM != "vt"??? ]]&&[[ $TERM != "linux" ]]&&[[ $TERM != "freebsd" ]]&&[[ $TERM != "bsdos" ]]&&[[ $TERM != "netbsd" ]]&&[[ -z $MC_TMPDIR ]]&&[[ $TERM != "xterm-color" ]]&&[[ $TERM != "xterm-16color" ]]&&[[ $TERM_PROGRAM != "Apple_Terminal" ]]&&[[ $TERM != "screen."* ]];then
_MONORAIL_SUPPORTED_TERMINAL(){
:
}
elif [[ $TERM == "alacritty" ]]||[[ $TERM == "rxvt-unicode-256colors" ]];then
_MONORAIL_BLANK
_MONORAIL_SUPPORTED_TERMINAL(){
:
}
else
_MONORAIL_SUPPORTED_TERMINAL(){
false
}
fi
fi
preexec(){
{
_MONORAIL_INITIAL_CURSOR_WORKAROUND(){ :;}
_TIMER_CMD="${1/\\\a/\\\\\a}"
_TIMER_CMD="${_TIMER_CMD/\\\b/\\\\\b}"
_TIMER_CMD="${_TIMER_CMD/\\\c/\\\\\c}"
_TIMER_CMD="${_TIMER_CMD/\\\d/\\\\\d}"
_TIMER_CMD="${_TIMER_CMD/\\\e/\\\\\e}"
_TIMER_CMD="${_TIMER_CMD/\\\f/\\\\\f}"
_TIMER_CMD="${_TIMER_CMD/\\\g/\\\\\g}"
_TIMER_CMD="${_TIMER_CMD/\\\h/\\\\\h}"
_TIMER_CMD="${_TIMER_CMD/\\\i/\\\\\i}"
_TIMER_CMD="${_TIMER_CMD/\\\j/\\\\\j}"
_TIMER_CMD="${_TIMER_CMD/\\\k/\\\\\k}"
_TIMER_CMD="${_TIMER_CMD/\\\l/\\\\\l}"
_TIMER_CMD="${_TIMER_CMD/\\\m/\\\\\m}"
_TIMER_CMD="${_TIMER_CMD/\\\n/\\\\\n}"
_TIMER_CMD="${_TIMER_CMD/\\\o/\\\\\o}"
_TIMER_CMD="${_TIMER_CMD/\\\p/\\\\\p}"
_TIMER_CMD="${_TIMER_CMD/\\\q/\\\\\q}"
_TIMER_CMD="${_TIMER_CMD/\\\r/\\\\\r}"
_TIMER_CMD="${_TIMER_CMD/\\\s/\\\\\s}"
_TIMER_CMD="${_TIMER_CMD/\\\t/\\\\\t}"
_TIMER_CMD="${_TIMER_CMD/\\\u/\\\\\u}"
_TIMER_CMD="${_TIMER_CMD/\\\v/\\\\\v}"
_TIMER_CMD="${_TIMER_CMD/\\\w/\\\\\w}"
_TIMER_CMD="${_TIMER_CMD/\\\x/\\\\\x}"
_TIMER_CMD="${_TIMER_CMD/\\\y/\\\\\y}"
_TIMER_CMD="${_TIMER_CMD/\\\z/\\\\\z}"
_TIMER_CMD="${_TIMER_CMD/\\\033/<ESC>}"
_TIMER_CMD="${_TIMER_CMD/\\\007/<BEL>}"
local CHAR SHORT_HOSTNAME CMD
case "$_TIMER_CMD" in
"c "*|"cd "*|".."*):;;
*)[[ -z $_MONORAIL_DATE ]]&&_MONORAIL_DATE=$(LC_MESSAGES=C LC_ALL=C date +%m-%d)
case $_MONORAIL_DATE in
10-2*|10-3*)CHAR=🎃
;;
12*)CHAR=🎄
;;
*)CHAR="*️⃣"
esac
TITLE="$CHAR  $_TIMER_CMD"
if [[ "$TMUX" ]];then
SHORT_HOSTNAME=${HOSTNAME%%.*}
SHORT_HOSTNAME=${SHORT_HOSTNAME,,}
TITLE="$TITLE on $SHORT_HOSTNAME"
fi
if [[ "$SCHROOT_ALIAS_NAME" ]];then
TITLE="$TITLE on $SCHROOT_ALIAS_NAME"
fi
local CMD
CMD=${_TIMER_CMD%% *}
CMD=${CMD%%;*}
_MONORAIL_CUSTOM_TITLE(){ false;}
alias "$CMD" >&- 2>&-&&_MONORAIL_CUSTOM_TITLE(){ :;}
for COMMAND in "${CUSTOM_TITLE_COMMANDS[@]}";do
if [[ $COMMAND == "${_TIMER_CMD:0:${#COMMAND}}" ]];then
_MONORAIL_CUSTOM_TITLE(){ :;}
fi
done
if _MONORAIL_CUSTOM_TITLE;then
_TITLE "$TITLE"
fi
_MEASURE=1
_START_SECONDS=$SECONDS
if _MONORAIL_SUPPORTED_TERMINAL;then
\printf "\e]11;#%s\a\e]10;#%s\a\e]12;#%s\a" "$_PROMPT_BGCOLOR" "$_PROMPT_FGCOLOR" "$_PROMPT_FGCOLOR" >/dev/tty 2>&-
fi
esac
_MONORAIL_CUSTOM_TITLE(){
false
}
} >&- 2>&-
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
DURATION=""
[ $DURATION_H -gt 0 ]&&DURATION="$DURATION${DURATION_H}h "
[ $DURATION_M -gt 0 ]&&DURATION="$DURATION${DURATION_M}m "
DURATION="$DURATION${DURATION_S}s, finished at "$(LC_MESSAGES=C LC_ALL=C date +%H:%M).""
\echo "$DURATION"
(exec notify-send -a "Completed $_TIMER_CMD" -i terminal "$_TIMER_CMD" "Command took $DURATION"&)
_MONORAIL_ALERT
_MONORAIL_LONGRUNNING=1
fi
unset _MEASURE
} 2>&-
}
title(){
TITLE_OVERRIDE="$*"
}
_MONORAIL(){
if [[ $_MONORAIL_LONGRUNNING ]] ;then
TITLE="✅ Completed $_TIMER_CMD"
if [[ "$SSH_CLIENT" ]];then
local SHORT_HOSTNAME=${HOSTNAME%%.*}
SHORT_HOSTNAME=${SHORT_HOSTNAME,,}
TITLE="$TITLE on $SHORT_HOSTNAME"
fi
if [[ "$SCHROOT_ALIAS_NAME" ]];then
TITLE="$TITLE on $SCHROOT_ALIAS_NAME"
fi
unset _MONORAIL_LONGRUNNING
return 0
fi
local _MONORAIL_REALPWD
_MONORAIL_REALPWD="$PWD"
case "$PWD" in
/run/user/*/gvfs/*)_MONORAIL_GIT_PS1="";;
*)local PROMPT_PWD MONORAIL_REPO
PROMPT_PWD="$PWD"
MONORAIL_REPO=""
while [[ "$PROMPT_PWD" ]];do
if [[ -d "$PROMPT_PWD/.repo" ]];then
MONORAIL_REPO=1
break
fi
PROMPT_PWD="${PROMPT_PWD%/*}"
done
_MONORAIL_GIT_LAZYLOAD
_MONORAIL_GIT_PS1=$(TERM=dumb GIT_CONFIG_GLOBAL="" LC_MESSAGES=C LC_ALL=C __git_ps1 "")
esac
if [[ $TITLE_OVERRIDE == "" ]];then
local SHORT_HOSTNAME=${HOSTNAME%%.*}
if [[ $ZSH_NAME ]];then
SHORT_HOSTNAME=$SHORT_HOSTNAME:l
else
SHORT_HOSTNAME=${SHORT_HOSTNAME,,}
fi
if [[ "$MONORAIL_REPO" ]];then
TITLE="🏗️  ${PWD##*/}"
if [[ "$SSH_CLIENT" ]];then
TITLE="$TITLE on $SHORT_HOSTNAME"
fi
if [[ "$SCHROOT_ALIAS_NAME" ]];then
TITLE="$TITLE on $SCHROOT_ALIAS_NAME"
fi
elif [[ "$_MONORAIL_GIT_PS1" ]];then
TITLE="🚧  ${PWD##*/}"
if [[ "$SSH_CLIENT" ]];then
TITLE="$TITLE on $SHORT_HOSTNAME"
fi
if [[ "$SCHROOT_ALIAS_NAME" ]];then
TITLE="$TITLE on $SCHROOT_ALIAS_NAME"
fi
else
case "$PWD" in
*/etc|*/etc/*)TITLE="️🗂️  ${PWD##*/}";;
*/bin|*/sbin)TITLE="️⚙️  ${PWD##*/}";;
*/lib|*/lib64|*/lib32)TITLE="🔩  ${PWD##*/}";;
*/tmp|*/tmp/*|*/.cache|*/.cache/*)TITLE="🚽  ${PWD##*/}";;
"$HOME/Trash"*)TITLE="🗑️   ${PWD##*/}";;
"$HOME/.local/share/Trash/files"*)TITLE="♻️  ${PWD##*/}";;
/boot|/boot/*)TITLE="🥾  ${PWD##*/}";;
/)TITLE="💻  /";;
*/.*)TITLE="📌  ${PWD##*/}";;
/media/*)TITLE="💾  ${PWD##*/}";;
/proc/*|/sys/*|/dev/*|/proc|/sys|/dev)TITLE="🤖  ${PWD##*/}";;
*/Documents|*/Documents/*|*/doc|*/docs|*/doc/*|*/docs/*|"$XDG_DOCUMENTS_DIR"|"$XDG_DOCUMENTS_DIR"/*)TITLE="📑  ${PWD##*/}";;
*/out|*/out/*)TITLE="🚀  ${PWD##*/}";;
*/src|*/src/*|*/sources|*/sources/*)TITLE="🚧  ${PWD##*/}";;
"$XDG_MUSIC_DIR"|"$XDG_MUSIC_DIR"/*)TITLE="🎵  ${PWD##*}";;
"$XDG_PICTURES_DIR"|"$XDG_PICTURES_DIR"/*)TITLE="🖼️  ${PWD##*/}";;
"$XDG_VIDEOS_DIR"|"$XDG_VIDEOS_DIR"/*)TITLE="🎬  ${PWD##*/}";;
*/Downloads|*/Downloads/*|"$XDG_DOWNLOAD_DIR"|"$XDG_DOWNLOAD_DIR"/*)TITLE="📦  ${PWD##*/}";;
*)TITLE="📂  ${PWD##*/}"
esac
case "$_MONORAIL_REALPWD" in
"$HOME")if
[[ "$SCHROOT_ALIAS_NAME" ]]
then
TITLE="🏠  $SCHROOT_ALIAS_NAME"
else
TITLE="🏠  $SHORT_HOSTNAME"
fi
;;
*)if
[[ "$SSH_CLIENT" ]]
then
TITLE="$TITLE on $SHORT_HOSTNAME"
fi
if [[ "$SCHROOT_ALIAS_NAME" ]];then
TITLE="$TITLE on $SCHROOT_ALIAS_NAME"
fi
esac
fi
else
TITLE="$TITLE_OVERRIDE"
fi
local PREHIDE POSTHIDE
if [[ $ZSH_NAME ]];then
PREHIDE='%{'
POSTHIDE='%}'
else
PREHIDE='\['
POSTHIDE='\]'
fi
local PWD_BASENAME="${PWD##*/}"
[ -z "$PWD_BASENAME" ]&&PWD_BASENAME=/
case $PWD in
"$HOME")_MONORAIL_PWD_BASENAME="~";;
*)_MONORAIL_PWD_BASENAME="${NAME-$PWD_BASENAME}"
esac
_MONORAIL_TEXT=" $_MONORAIL_PWD_BASENAME$_MONORAIL_GIT_PS1 "
local CURSORPOS RGB_CUR_COLOR RGB_CUR_R RGB_CUR_GB RGB_CUR_G RGB_CUR_B HEX_CUR_COLOR CHAR
if [[ $_MONORAIL_CACHE != "$COLUMNS$_MONORAIL_TEXT" ]];then
_MONORAIL_INVALIDATE_CACHE
if _MONORAIL_SUPPORTED_TERMINAL;then
CHAR=$'\xe2\x96\x81'
elif [[ $TERM == "dm2500" ]]||[[ $TERM == "dumb" ]];then
CHAR=-
else
CHAR="_"
fi
local I=0
if _MONORAIL_VTXXX_TERMINAL;then
CHAR=s
_MONORAIL_LINE=$'\e'"[0;1m"$'\e'"#6"$'\e'"(0"
_MONORAIL_ATTRIBUTE=$'\e'"(1"$'\e'"[0;7m"
elif [[ ${#_PROMPT_LUT[@]} -gt 0 ]]&&_MONORAIL_SUPPORTED_TERMINAL;then
_MONORAIL_ATTRIBUTE=""
_MONORAIL_LINE=""
else
_MONORAIL_ATTRIBUTE=$'\e'"[7m"
_MONORAIL_LINE=""
fi
local TEMP_COLUMNS=$COLUMNS
_MONORAIL_DUMB_TERMINAL&&TEMP_COLUMNS=$((COLUMNS-2))
if _MONORAIL_VTXXX_TERMINAL;then
while [ $I -lt $TEMP_COLUMNS ];do
if [ $I -lt $((TEMP_COLUMNS/2)) ];then
_MONORAIL_LINE="$_MONORAIL_LINE$CHAR"
else
:
fi
I=$((I+1))
done
elif _MONORAIL_SUPPORTED_TERMINAL;then
while [ $I -lt $TEMP_COLUMNS ];do
_MONORAIL_LINE="$_MONORAIL_LINE"$'\e'"[38;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*I/$((TEMP_COLUMNS+1))))]}m$CHAR"
I=$((I+1))
done
else
while [ $I -lt $TEMP_COLUMNS ];do
_MONORAIL_LINE="$_MONORAIL_LINE$CHAR"
I=$((I+1))
done
fi
_MONORAIL_TEXT_FORMATTED=""
local I=0
if [[ ${#_PROMPT_LUT[@]} == 0 ]]||_MONORAIL_VTXXX_TERMINAL||_MONORAIL_LINUX_TERMINAL||[[ "$MC_TMPDIR" ]];then
while [ $I -lt ${#_MONORAIL_TEXT} ];do
_MONORAIL_TEXT_FORMATTED="$_MONORAIL_TEXT_FORMATTED${_MONORAIL_TEXT:I:1}"
I=$((I+1))
done
else
while [ $I -lt ${#_MONORAIL_TEXT} ];do
local LUT
LUT=$((${#_PROMPT_LUT[*]}*I/$((COLUMNS+1))))
if [ -z "${_PROMPT_TEXT_LUT[0]}" ];then
local _PROMPT_TEXT_LUT
_PROMPT_TEXT_LUT[0]="255;255;255"
fi
local TEXT_LUT=$(((${#_PROMPT_TEXT_LUT[*]}*I)/$((COLUMNS+1))))
_MONORAIL_TEXT_FORMATTED="$_MONORAIL_TEXT_FORMATTED$PREHIDE"$'\e'"[48;2;${_PROMPT_LUT[$LUT]}m"$'\e'"[38;2;${_PROMPT_TEXT_LUT[$TEXT_LUT]}m$POSTHIDE${_MONORAIL_TEXT:I:1}"
I=$((I+1))
done
fi
_MONORAIL_CACHE="$COLUMNS$_MONORAIL_TEXT"
fi
CURSORPOS=$((${#_MONORAIL_TEXT}+1))
RGB_CUR_COLOR=${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*CURSORPOS/$((COLUMNS+1))))]}
RGB_CUR_R=${RGB_CUR_COLOR%%;*}
RGB_CUR_GB=${RGB_CUR_COLOR#*;}
RGB_CUR_G=${RGB_CUR_GB%%;*}
RGB_CUR_B=${RGB_CUR_GB##*;}
HEX_CUR_COLOR=$(\printf "%.2x%.2x%.2x" "$RGB_CUR_R" "$RGB_CUR_G" "$RGB_CUR_B")
[ -z "$HEX_CUR_COLOR" ]&&HEX_CUR_COLOR="$_PROMPT_FGCOLOR"
[[ ${#_PROMPT_LUT[@]} == 0 ]]&&HEX_CUR_COLOR=$_PROMPT_FGCOLOR
if _MONORAIL_SUPPORTED_TERMINAL;then
\printf "\e]11;#%s\a\e]10;#%s\a\e]12;#%s\a" "$_PROMPT_BGCOLOR" "$_PROMPT_FGCOLOR" "$HEX_CUR_COLOR"
fi
if _MONORAIL_MLTERM_TERMINAL;then
# SC2025: no need to enclose in \[ \] as cursor position is calculated from after newline
# shellcheck disable=SC2025
PS1=$'\e'"]0;$TITLE"$'\a''${_MONORAIL_LINE}'"
$_MONORAIL_TEXT_FORMATTED$PREHIDE"$'\e'"[0m"$'\e'"[?25h$POSTHIDE "
elif _MONORAIL_SUPPORTED_TERMINAL;then
# shellcheck disable=SC2025
PS1=$'\e'"]0;$TITLE"$'\a'$'\r'$'\e'"[0m"'${_MONORAIL_LINE}'"
$PREHIDE$_MONORAIL_ATTRIBUTE$POSTHIDE$_MONORAIL_TEXT_FORMATTED$PREHIDE"$'\e'"[0m"$'\e'"[?25h$POSTHIDE "
elif _MONORAIL_VTXXX_TERMINAL; then
# shellcheck disable=SC2025
PS1=$'\r'$'\e'"[0m"'${_MONORAIL_LINE}'"
$PREHIDE$_MONORAIL_ATTRIBUTE$POSTHIDE$_MONORAIL_TEXT_FORMATTED$PREHIDE"$'\e'"[0m"$'\e'"[?25h$POSTHIDE "
else
local REVERSE NORMAL
REVERSE=$(LC_MESSAGES=C LC_ALL=C tput rev 2>&-)
if [[ "$REVERSE" ]];then
NORMAL="$PREHIDE$(LC_MESSAGES=C LC_ALL=C tput sgr0 2>&-)$POSTHIDE"
REVERSE="$PREHIDE$REVERSE$POSTHIDE"
elif [[ $TERM == "dumb" ]];then
REVERSE=""
NORMAL="!"
else
REVERSE=""
NORMAL="|"
fi
PS1='${_MONORAIL_LINE}'"
$REVERSE$_MONORAIL_TEXT$NORMAL "
fi
unset _MONORAIL_NOSTYLING
}
precmd(){
_MONORAIL
# add functions to be run before commands after first prompt has shown
# Shellcheck mistakenly thinks precmd() is not called again. It is called every refresh of prompt.
# shellcheck disable=SC2329
precmd(){
_MONORAIL_STOP_TIMER
_MONORAIL_COMMAND
_MONORAIL
}
}
_TITLE_RAW(){
if [[ $_MONORAIL_NOSTYLING ]];then
return 0
fi
if [[ $TERM =~ "xterm"* ]]||[ "$TERM" = "alacritty" ];then
\printf "\e]0;%s\a" "$*" >/dev/tty 2>&-
fi
}
if [[ $XDG_CONFIG_HOME ]];then
_MONORAIL_CONFIG="$XDG_CONFIG_HOME/monorail"
else
_MONORAIL_CONFIG="$HOME/.config/monorail"
fi
if [[ ! -f "$_MONORAIL_CONFIG"/colors.sh ]];then
LC_MESSAGES=C mkdir -p "$_MONORAIL_CONFIG"
LC_MESSAGES=C \cp "$_MONORAIL_DIR"/colors/Default.sh "$_MONORAIL_CONFIG"/colors.sh
fi
_MONORAIL_INVALIDATE_CACHE
name(){
NAME="$*"
}
alias monorail_color="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR $_MONORAIL_DIR/scripts/color.sh"
alias monorail_fgcolor="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR $_MONORAIL_DIR/scripts/fgcolor.sh"
alias monorail_gradient="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR $_MONORAIL_DIR/scripts/gradient.sh"
alias monorail_image="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR $_MONORAIL_DIR/scripts/image.sh"
alias monorail_gradienttext="_MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR $_MONORAIL_DIR/scripts/gradient.sh --text"
alias for='_MONORAIL_NOSTYLING=1;for'
alias while='_MONORAIL_NOSTYLING=1;while'
alias until='_MONORAIL_NOSTYLING=1;until'
} >&- 2>&-
