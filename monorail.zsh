{
[[ $_MONORAIL_DIR ]]||_MONORAIL_DIR=$HOME/.local/share/monorail
[[ $HOSTNAME ]]||HOSTNAME=$(hostname)
if [[ $CRAFT_STATE_DIR ]];then
_MONORAIL_SHORT_HOSTNAME=snapcraft
_MONORAIL_HAS_SUFFIX=1
_MONORAIL_SUFFIX(){
_MONORAIL_TITLE="$_MONORAIL_TITLE on $_MONORAIL_SHORT_HOSTNAME"
}
elif [[ $SSH_CLIENT ]]||[[ $TMUX ]];then
_MONORAIL_HAS_SUFFIX=1
_MONORAIL_SUFFIX(){
_MONORAIL_TITLE="$_MONORAIL_TITLE on $_MONORAIL_SHORT_HOSTNAME"
}
_MONORAIL_SHORT_HOSTNAME=${HOSTNAME%%.*}
elif [[ -e /.dockerenv ]];then
_MONORAIL_SHORT_HOSTNAME=docker
_MONORAIL_HAS_SUFFIX=1
_MONORAIL_SUFFIX(){
_MONORAIL_TITLE="$_MONORAIL_TITLE on $_MONORAIL_SHORT_HOSTNAME"
}
elif [[ -e /run/containerenv ]];then
_MONORAIL_HAS_SUFFIX=1
_MONORAIL_SHORT_HOSTNAME=podman
_MONORAIL_SUFFIX(){
_MONORAIL_TITLE="$_MONORAIL_TITLE on $_MONORAIL_SHORT_HOSTNAME"
}
else
_MONORAIL_SHORT_HOSTNAME=${HOSTNAME%%.*}
fi
setopt KSH_ARRAYS
setopt prompt_subst
_MONORAIL_SHORT_HOSTNAME=${_MONORAIL_SHORT_HOSTNAME:l}
preexec(){
{
[[ $(fc -l -1) == "$_MONORAIL_PREV_CMD" ]]&&return
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
local XCMD IGNORED_TITLE=
for XCMD in "${_MONORAIL_CMD_IGNORED[@]}";do
[[ $XCMD == "${_TIMER_CMD%% *}" ]]&&IGNORED_TITLE=1
done
ICON="*️⃣"
_MONORAIL_TITLE="$ICON  $_TIMER_CMD"
[[ $_MONORAIL_HAS_SUFFIX ]]&&_MONORAIL_SUFFIX
CMD=${_TIMER_CMD%% *}
CMD=${CMD%%;*}
unset _MONORAIL_CUSTOM_TITLE
alias "$CMD" >&- 2>&-&&_MONORAIL_CUSTOM_TITLE=1
for COMMAND in "${CUSTOM_TITLE_COMMANDS[@]}";do
[[ $COMMAND == "${_TIMER_CMD:0:${#COMMAND}}" ]]&&_MONORAIL_CUSTOM_TITLE=1
done
_MEASURE=1
_START_SECONDS=$SECONDS
_MONORAIL_TITLE+=" in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M)"
local _MONORAIL_TITLE_FORMATTED=
[[ $IGNORED_TITLE ]]||_MONORAIL_TITLE_FORMATTED=$'\e'"]0;"$_MONORAIL_TITLE$'\a\r\e[K'
[[ $_MONORAIL_HAS_SUFFIX ]]&&_MONORAIL_SUFFIX
printf "$_MONORAIL_TITLE_FORMATTED\e]11;#${_COLORS[17]}\a\e]10;#${_COLORS[16]}\a\e]12;#${_COLORS[21]}\a\r\e[K" >/dev/tty 2>&-
unset _MONORAIL_CUSTOM_TITLE
} &>/dev/null
}
_monorail_gradient(){
unset "_PROMPT_LUT[*]"
_PROMPT_LUT=()
while [[ $1 ]];do
_PROMPT_LUT[${#_PROMPT_LUT[@]}]=$1
shift
done
}
_monorail_textgradient(){
unset "_PROMPT_TEXT_LUT[*]"
_PROMPT_TEXT_LUT=()
while [[ $1 ]];do
_PROMPT_TEXT_LUT[${#_PROMPT_TEXT_LUT[@]}]=$1
shift
done
}
_monorail_colors(){
unset "_COLORS[*]"
_COLORS=()
while [[ "$1" ]];do
_COLORS[${#_COLORS[@]}]=$1
shift
done
}
_MONORAIL_SET_TITLE(){
unset _MONORAIL_TITLE_OVERRIDE
[[ $1 ]]&&_MONORAIL_TITLE_OVERRIDE="$*"
}
alias title=_MONORAIL_SET_TITLE
_MONORAIL_SET_ICON(){
unset _MONORAIL_ICON_OVERRIDE
[[ $1 ]]&&_MONORAIL_ICON_OVERRIDE="$*"
}
alias icon=_MONORAIL_SET_ICON
_TITLE_RAW(){
[[ $_MONORAIL_NOSTYLING ]]&&return 0
printf "\e]0;%s\a\r\e[K" "$*" >/dev/tty 2>&-
}
if [[ $XDG_CONFIG_HOME ]];then
_MONORAIL_CONFIG=$XDG_CONFIG_HOME/monorail
else
_MONORAIL_CONFIG=$HOME/.config/monorail
fi
_MONORAIL_NAME(){
unset NAME
[[ $1 ]]&&NAME="$*"
}
alias name=_MONORAIL_NAME
precmd(){
if [[ $_MONORAIL_LAUNCHED ]];then
[[ $BLE_ATTACHED ]]||LC_MESSAGES=C LC_ALL=C stty echo 2>&-
{
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
} 2>&-
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
if [[ -z $_MONORAIL_CR_FIRST ]]&&[[ $CMD_STATUS == 0 ]]&&[[ -z $_MONORAIL_CTRLC ]];then
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
else
alias for='_MONORAIL_NOSTYLING=1;for'
alias while='_MONORAIL_NOSTYLING=1;while'
alias until='_MONORAIL_NOSTYLING=1;until'
_MONORAIL_LAUNCHED=1
fi
if [[ $_MONORAIL_LONGRUNNING ]];then
local ICON="${_MONORAIL_ICON[completed]}  "
_MONORAIL_TITLE="${ICON}Completed $_TIMER_CMD"
[[ $_MONORAIL_HAS_SUFFIX ]]&&_MONORAIL_SUFFIX
unset _MONORAIL_LONGRUNNING
return 0
fi
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
DIR=$PWD
while [[ $DIR ]];do
if [[ -e "$DIR/.git" ]]&&[[ -e /usr/lib/git-core/git-sh-prompt ]];then
. /usr/lib/git-core/git-sh-prompt
_MONORAIL_GIT_LOADED=1
fi
DIR=${DIR%/*}
done
fi
_MONORAIL_GIT_PS1=$(_TITLE(){
shift
"$@"
}
TERM=dumb GIT_CONFIG_GLOBAL="" LC_MESSAGES=C LC_ALL=C __git_ps1 "")
esac
local ICON TITLE_BASE
TITLE_BASE=${PWD##*/}
if [[ $MONORAIL_REPO ]];then
ICON=${_MONORAIL_ICON[repo]}
elif [[ $_MONORAIL_GIT_PS1 ]];then
ICON=${_MONORAIL_ICON[git]}
else
ICON=${_MONORAIL_ICON[${PWD//\//_}]}
fi
case $PWD in
"$HOME")TITLE_BASE=$_MONORAIL_SHORT_HOSTNAME
if [[ $CRAFT_STATE_DIR ]];then
ICON=${_MONORAIL_ICON[snapcraft]}
elif [[ $SSH_CLIENT ]];then
ICON=${_MONORAIL_ICON[ssh]}
elif [[ -e /.dockerenv ]];then
ICON=${_MONORAIL_ICON[docker]}
elif [[ -e /run/containerenv ]];then
ICON=${_MONORAIL_ICON[podman]}
else
ICON=${_MONORAIL_ICON[home]}
fi
;;
*)
esac
[[ $ICON ]]||ICON=${_MONORAIL_ICON[folder]}
[[ $ICON ]]&&ICON="$ICON  "
_MONORAIL_TITLE="${_MONORAIL_ICON_OVERRIDE-$ICON}  ${_MONORAIL_TITLE_OVERRIDE-$TITLE_BASE}"
[[ $PWD != "$HOME" ]]&&[[ $_MONORAIL_HAS_SUFFIX ]]&&_MONORAIL_SUFFIX
local PWD_BASENAME="${PWD##*/}"
[[ $PWD_BASENAME ]]||PWD_BASENAME=/
case $PWD in
"$HOME")_MONORAIL_PWD_BASENAME="~";;
*)_MONORAIL_PWD_BASENAME="${NAME-$PWD_BASENAME}"
esac
_MONORAIL_TEXT=" $_MONORAIL_PWD_BASENAME$_MONORAIL_GIT_PS1 "
_MONORAIL_ELIPSIS=$'\xe2\x80\xa6'
_MONORAIL_TEXT=${_MONORAIL_TEXT//\.\.\./$_MONORAIL_ELIPSIS}
if [[ ${#_MONORAIL_TEXT} -gt $((COLUMNS/3)) ]];then
_MONORAIL_TEXT=" $_MONORAIL_ELIPSIS${_MONORAIL_TEXT:$((${#_MONORAIL_TEXT}-$((COLUMNS/3))))}"
fi
_MONORAIL_TEXT_ARRAY=()
for ((I=0; I<${#_MONORAIL_TEXT}; I++));do
_MONORAIL_TEXT_ARRAY[I]=${_MONORAIL_TEXT[I]}
done
_MONORAIL_TEXT_ARRAY_LEN=${#_MONORAIL_TEXT_ARRAY[@]}
local RGB_CUR_COLOR RGB_CUR_R RGB_CUR_GB RGB_CUR_G RGB_CUR_B
if [[ $_MONORAIL_CACHE != "$COLUMNS$_MONORAIL_TEXT" ]];then
unset _MONORAIL_CACHE "_PROMPT_LUT[*]" "_PROMPT_TEXT_LUT[*]" _MEASURE
if [[ ! -f "$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".conf ]];then
mkdir -p "$_MONORAIL_CONFIG"
if [[ -f "$_MONORAIL_DIR/gradients/Default.conf" ]];then
if [[ $(gsettings get org.gnome.desktop.interface color-scheme) == prefer-dark ]];then
LC_ALL=C LC_MESSAGES=C \cat "$_MONORAIL_DIR"/colors/DefaultDark.conf "$_MONORAIL_DIR"/gradients/Default.conf >"$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".conf 2>&-
else
LC_ALL=C LC_MESSAGES=C \cat "$_MONORAIL_DIR"/colors/Default.conf "$_MONORAIL_DIR"/gradients/Default.conf >"$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".conf 2>&-
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
. "$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".conf
local I=0
_MONORAIL_LINE=
_MONORAIL_UNDERLINE=
while [[ $I -le $COLUMNS ]];do
_MONORAIL_LINE+=$'\e'"[38;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*I/$((COLUMNS+1))))]}m"$'\xe2\x96\x81'
I=$((I+1))
done
local I=0
if [[ -z ${_PROMPT_LUT[0]} ]];then
_MONORAIL_TEXT_FORMATTED=%{$'\e'"[0;7m%}"
while [[ $I -lt $_MONORAIL_TEXT_ARRAY_LEN ]];do
_MONORAIL_TEXT_FORMATTED+=${_MONORAIL_TEXT_ARRAY[I]}
I=$((I+1))
done
_MONORAIL_TEXT_FORMATTED+=%{$'\e[0;8m'"%}|"
else
_MONORAIL_TEXT_FORMATTED=
[[ -z ${_PROMPT_TEXT_LUT[*]} ]]&&_PROMPT_TEXT_LUT[0]="255;255;255"
while [[ $I -lt $_MONORAIL_TEXT_ARRAY_LEN ]];do
_MONORAIL_TEXT_FORMATTED+="%{"$'\e['"$((_MONORAIL_TEXT_ARRAY_LEN+1))C"$'\e'["$((_MONORAIL_TEXT_ARRAY_LEN+1))"D$'\e'"[48;2;${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*I/$((COLUMNS+1))))]}m"$'\e'"[38;2;${_PROMPT_TEXT_LUT[$((${#_PROMPT_TEXT_LUT[*]}*I/$((COLUMNS+1))))]}m%}${_MONORAIL_TEXT_ARRAY[I]}"
I=$((I+1))
done
_MONORAIL_TEXT_FORMATTED+="%{"$'\e'"[0;8m"$'\e'"[38;2;$((0x${_COLORS[17]:0:2}));$((0x${_COLORS[17]:2:2}));$((0x${_COLORS[17]:4:2}))m%}|"
fi
RGB_CUR_COLOR=${_PROMPT_LUT[$((${#_PROMPT_LUT[*]}*$((_MONORAIL_TEXT_ARRAY_LEN+1))/$((COLUMNS+1))))]}
RGB_CUR_R=${RGB_CUR_COLOR%%;*}
RGB_CUR_GB=${RGB_CUR_COLOR#*;}
RGB_CUR_G=${RGB_CUR_GB%%;*}
RGB_CUR_B=${RGB_CUR_GB##*;}
HEX_CURSOR_COLOR=$(printf "%.2x%.2x%.2x" "$RGB_CUR_R" "$RGB_CUR_G" "$RGB_CUR_B" 2>&-)
[[ ${_PROMPT_LUT[0]} ]]||HEX_CURSOR_COLOR=${_COLORS[21]}
_MONORAIL_CACHE="$COLUMNS$_MONORAIL_TEXT"
fi
unset _MONORAIL_NOSTYLING
PS1=$'\e[?7l\e]0;'$_MONORAIL_TITLE$'\a\e[0m\r'"$_MONORAIL_LINE
$_MONORAIL_TEXT_FORMATTED%{"$'\r\e['$((${#_MONORAIL_TEXT}+1))C$'\e[?7h\e[?25h\e]12;#$HEX_CURSOR_COLOR\a\e[0m'"%}"
printf "\e[?25l\e[?7l\e[${COLUMNS}C\e]11;#${_COLORS[17]}\a\e]10;#${_COLORS[16]}\a\e]4;0;#${_COLORS[0]}\a\e]4;1;#${_COLORS[1]}\a\e]4;2;#${_COLORS[2]}\a\e]4;3;#${_COLORS[3]}\a\e]4;4;#${_COLORS[4]}\a\e]4;5;#${_COLORS[5]}\a\e]4;6;#${_COLORS[6]}\a\e]4;7;#${_COLORS[7]}\a\e]4;8;#${_COLORS[8]}\a\e]4;9;#${_COLORS[9]}\a\e]4;10;#${_COLORS[10]}\a\e]4;11;#${_COLORS[11]}\a\e]4;12;#${_COLORS[12]}\a\e]4;13;#${_COLORS[13]}\a\e]4;14;#${_COLORS[14]}\a\e]4;15;#${_COLORS[15]}\a\r"
}
_TITLE(){
local _MONORAIL_TITLE="$*"
if [[ $_MEASURE ]];then
_MONORAIL_TITLE+=" in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M 2>&-)"
elif [[ $PWD == "$HOME" ]];then
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
[[ $ICON ]]&&if [[ -z $FIRST_NON_OPTION ]];then
_TITLE "${_MONORAIL_ICON_OVERRIDE-$ICON}  ${FIRST_ARG##*/}"
else
_TITLE "${_MONORAIL_ICON_OVERRIDE-$ICON}  ${FIRST_NON_OPTION##*/}"
fi) >& \
- 2>&-
fi
"$@"
}
trap "unset _MONORAIL_CACHE" WINCH
_LOW_PRIO(){
if type -P chrt&&type -P ionice&&type -P ionice;then
_LOW_PRIO(){
choom -n +1000 -- ionice -c idle -- chrt --idle 0 "$@"
}
else
_LOW_PRIO(){
nice -n19 "$@"
}
fi >/dev/null 2>&-
_LOW_PRIO "$@"
}
_monorail_icon(){
case "$2" in
/*)_MONORAIL_ICON[$2]=$1;;
*/*)_MONORAIL_ICON[${HOME//\//_}$2]=;;
*)_MONORAIL_ICON[$2]=$1
esac
}
_monorail_cmd_interactive(){
command -v "$2"&&alias "$2=_NO_MEASURE _ICON $1 $2"
}
_monorail_cmd_batch(){
command -v "$2"&&alias "$2=_ICON $1 _LOW_PRIO $2"
}
_MONORAIL_CMD_IGNORED=()
_monorail_cmd_ignored(){
_MONORAIL_CMD_IGNORED[${#_MONORAIL_CMD_IGNORED[@]}]=$1
}
[[ -e $_MONORAIL_CONFIG/settings-$_MONORAIL_SHORT_HOSTNAME.conf ]]||cat "$_MONORAIL_DIR/defaults.conf" >"$_MONORAIL_CONFIG/settings-$_MONORAIL_SHORT_HOSTNAME.conf"
. "$_MONORAIL_CONFIG/settings-$_MONORAIL_SHORT_HOSTNAME.conf"
__git_ps1(){ :;}
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
if [[ $TERM == xterm-256color ]];then
[[ $ZUTTY_VERSION ]]&&_MONORAIL_COMPAT=1
[[ $TERM_PROGRAM == vscode ]]&&_MONORAIL_COMPAT=1
elif [[ $MC_TMPDIR ]];then
_MONORAIL_COMPAT=1
else
case $TERM in
xterm-color|xterm-16color)_MONORAIL_COMPAT=1
;;
xterm*|alacritty|rio|rxvt-unicode-256color|mlterm|st-256color|foot)printf "\e[?25l\e[?7l\e[%sC\e]0; \a\r\e[K" "$COLUMNS" >/dev/tty 2>&-
[[ $TERM == xterm-ghostty ]]&&unalias ssh 2>/dev/null
[[ $(tty) =~ "/dev/ttyv"* ]]&&_MONORAIL_COMPAT=1
[[ $WINDOWID == 0 ]]&&_MONORAIL_COMPAT=1
case $XTERM_LOCALE in
""|*.UTF-8):;;
*)_MONORAIL_COMPAT=1
esac
;;
*)_MONORAIL_COMPAT=1
esac
fi
[[ $_MONORAIL_COMPAT ]]&&if [[ ! $_MONORAIL_DISABLE_COMPAT ]];then
unalias git >/dev/null 2>/dev/null
. "$_MONORAIL_DIR/monorail.sh"
fi
alias monorail_color="_MONORAIL_SHORT_HOSTNAME=$_MONORAIL_SHORT_HOSTNAME _MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR sh $_MONORAIL_DIR/scripts/color.sh"
alias monorail_gradient="_MONORAIL_SHORT_HOSTNAME=$_MONORAIL_SHORT_HOSTNAME _MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR sh $_MONORAIL_DIR/scripts/gradient.sh"
alias monorail_image="_MONORAIL_SHORT_HOSTNAME=$_MONORAIL_SHORT_HOSTNAME _MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR sh $_MONORAIL_DIR/scripts/image.sh"
alias monorail_textgradient="_MONORAIL_SHORT_HOSTNAME=$_MONORAIL_SHORT_HOSTNAME _MONORAIL_CONFIG=$_MONORAIL_CONFIG _MONORAIL_DIR=$_MONORAIL_DIR sh $_MONORAIL_DIR/scripts/gradient.sh --text"
alias rgb="sh $_MONORAIL_DIR/scripts/rgb.sh"
} >&- 2>&-
