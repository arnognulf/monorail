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
local var__escaped_command var__icon CMD
var__escaped_command=${1/\\\a/\\\\\a}
var__escaped_command=${var__escaped_command/\\\b/\\\\\b}
var__escaped_command=${var__escaped_command/\\\c/\\\\\c}
var__escaped_command=${var__escaped_command/\\\d/\\\\\d}
var__escaped_command=${var__escaped_command/\\\e/\\\\\e}
var__escaped_command=${var__escaped_command/\\\f/\\\\\f}
var__escaped_command=${var__escaped_command/\\\g/\\\\\g}
var__escaped_command=${var__escaped_command/\\\h/\\\\\h}
var__escaped_command=${var__escaped_command/\\\i/\\\\\i}
var__escaped_command=${var__escaped_command/\\\j/\\\\\j}
var__escaped_command=${var__escaped_command/\\\k/\\\\\k}
var__escaped_command=${var__escaped_command/\\\l/\\\\\l}
var__escaped_command=${var__escaped_command/\\\m/\\\\\m}
var__escaped_command=${var__escaped_command/\\\n/\\\\\n}
var__escaped_command=${var__escaped_command/\\\o/\\\\\o}
var__escaped_command=${var__escaped_command/\\\p/\\\\\p}
var__escaped_command=${var__escaped_command/\\\q/\\\\\q}
var__escaped_command=${var__escaped_command/\\\r/\\\\\r}
var__escaped_command=${var__escaped_command/\\\s/\\\\\s}
var__escaped_command=${var__escaped_command/\\\t/\\\\\t}
var__escaped_command=${var__escaped_command/\\\u/\\\\\u}
var__escaped_command=${var__escaped_command/\\\v/\\\\\v}
var__escaped_command=${var__escaped_command/\\\w/\\\\\w}
var__escaped_command=${var__escaped_command/\\\x/\\\\\x}
var__escaped_command=${var__escaped_command/\\\y/\\\\\y}
var__escaped_command=${var__escaped_command/\\\z/\\\\\z}
var__escaped_command=${var__escaped_command/\\\033/<ESC>}
_TIMER_CMD=${var__escaped_command/\\\007/<BEL>}
local XCMD COMMAND IGNORED_TITLE=
for XCMD in "${_MONORAIL_CMD_IGNORED[@]}";do
[[ $XCMD == "${_TIMER_CMD%% *}" ]]&&IGNORED_TITLE=1
done
var__icon=${_MONORAIL_ICON[15]}
_MONORAIL_TITLE="$var__icon  $_TIMER_CMD"
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
local var__monorail_title_formatted=
[[ $IGNORED_TITLE ]]||var__monorail_title_formatted=$'\e'"]0;"$_MONORAIL_TITLE$'\a\r\e[K'
[[ $_MONORAIL_HAS_SUFFIX ]]&&_MONORAIL_SUFFIX
printf "$var__monorail_title_formatted\e]11;#${_COLORS[17]}\a\e]10;#${_COLORS[16]}\a\e]12;#${_COLORS[21]}\a\r\e[K" >/dev/tty 2>&-
unset _MONORAIL_CUSTOM_TITLE
} &>/dev/null
}
_monorail_gradient(){
local i=0
local j
while [[ $i -le $COLUMNS ]];do
j=$((1+$#*i/$((COLUMNS+1))))
h+=$'\e'"[38;2;${!j}m"$'\xe2\x96\x81'
i=$((i+1))
done
i=0
if [[ -z $1 ]];then
b_formatted=%{$'\e'"[0;7m%}"
while [[ $i -lt $b_array_len ]];do
b_formatted+=${b_array[i]}
i=$((i+1))
done
b_formatted+=%{$'\e[0;8m'"%}|"
else
b_formatted=
[[ -z ${var__prompt_text_lut[*]} ]]&&var__prompt_text_lut[0]="255;255;255"
while [[ $i -lt $b_array_len ]];do
j=$((1+$#*i/$((COLUMNS+1))))
b_formatted+="%{"$'\e['"$((b_array_len+1))C"$'\e'["$((b_array_len+1))"D$'\e'"[48;2;${!j}m"$'\e'"[38;2;${var__prompt_text_lut[$((${#var__prompt_text_lut[*]}*i/$((COLUMNS+1))))]}m%}${b_array[i]}"
i=$((i+1))
done
b_formatted+="%{"$'\e'"[0;8m"$'\e'"[38;2;$((0x${_COLORS[17]:0:2}));$((0x${_COLORS[17]:2:2}));$((0x${_COLORS[17]:4:2}))m%}|"
fi
j=$(($#*$((b_array_len+1))/$((COLUMNS+1))))
var__rgb_cur_color=${!j}
var__rgb_cur_r=${var__rgb_cur_color%%;*}
var__rgb_cur_gb=${var__rgb_cur_color#*;}
var__rgb_cur_g=${var__rgb_cur_gb%%;*}
var__rgb_cur_b=${var__rgb_cur_gb##*;}
var__hex_cursor_color=$(printf "%.2x%.2x%.2x" "$var__rgb_cur_r" "$var__rgb_cur_g" "$var__rgb_cur_b" 2>&-)
[[ $1 ]]||var__hex_cursor_color=${_COLORS[21]}
}
_monorail_textgradient(){
var__prompt_text_lut=("$@")
}
_monorail_colors(){
_COLORS=("$@")
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
[[ $_MONORAIL_CONFIG ]]||_MONORAIL_CONFIG=$HOME/.config/monorail
_MONORAIL_NAME(){
unset NAME
[[ $1 ]]&&NAME="$*"
}
alias name=_MONORAIL_NAME
precmd(){
if [[ $_MONORAIL_LAUNCHED ]];then
[[ $BLE_ATTACHED ]]||LC_MESSAGES=C LC_ALL=C stty echo 2>&-
{
local SECONDS_M DURATION_H DURATION_M DURATION_S DURATION var__diff
var__diff=$((SECONDS-_START_SECONDS))
if [[ $_MEASURE ]]&&[[ $var__diff -gt ${_MONORAIL_TIMEOUT-29} ]];then
SECONDS_M=$((var__diff%3600))
DURATION_H=$((var__diff/3600))
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
else
alias for='_MONORAIL_NOSTYLING=1;for'
alias while='_MONORAIL_NOSTYLING=1;while'
alias until='_MONORAIL_NOSTYLING=1;until'
_MONORAIL_LAUNCHED=1
fi
if [[ $_MONORAIL_LONGRUNNING ]];then
_MONORAIL_TITLE="✅ Completed $_TIMER_CMD"
[[ $_MONORAIL_HAS_SUFFIX ]]&&_MONORAIL_SUFFIX
unset _MONORAIL_LONGRUNNING
return 0
fi
case $PWD in
/run/user/*/gvfs/*)_MONORAIL_GIT_PS1=;;
*)local var__prompt_pwd var__monorail_repo
var__prompt_pwd=$PWD
var__monorail_repo=
while [[ "$var__prompt_pwd" ]];do
if [[ -d "$var__prompt_pwd/.repo" ]];then
var__monorail_repo=1
break
fi
var__prompt_pwd="${var__prompt_pwd%/*}"
done
if [[ -z $_MONORAIL_GIT_LOADED ]];then
local var__dir
var__dir=$PWD
while [[ $var__dir ]];do
if [[ -e "$var__dir/.git" ]]&&[[ -e /usr/lib/git-core/git-sh-prompt ]];then
. /usr/lib/git-core/git-sh-prompt
_MONORAIL_GIT_LOADED=1
fi
var__dir=${var__dir%/*}
done
fi
_MONORAIL_GIT_PS1=$(_TITLE(){
shift
"$@"
}
TERM=dumb GIT_CONFIG_GLOBAL="" LC_MESSAGES=C LC_ALL=C __git_ps1 "")
esac
local var__icon TITLE_BASE
TITLE_BASE=${PWD##*/}
if [[ $var__monorail_repo ]];then
var__icon=${_MONORAIL_ICON[5]}
elif [[ $_MONORAIL_GIT_PS1 ]];then
var__icon=${_MONORAIL_ICON[4]}
else
case $PWD in
"$HOME/Trash"*|"$HOME/.local/share/Trash/files"*)var__icon=${_MONORAIL_ICON[6]};;
/)var__icon=${_MONORAIL_ICON[16]}
TITLE_BASE=/
;;
/media/*)var__icon=${_MONORAIL_ICON[8]};;
/proc/*|/sys/*|/dev/*|/proc|/sys|/dev)var__icon=${_MONORAIL_ICON[17]};;
*/Documents|*/Documents/*|*/doc|*/docs|*/doc/*|*/docs/*|"$XDG_DOCUMENTS_DIR"|"$XDG_DOCUMENTS_DIR"/*)var__icon=${_MONORAIL_ICON[7]};;
"$XDG_MUSIC_DIR"|"$XDG_MUSIC_DIR"/*)var__icon=${_MONORAIL_ICON[9]};;
"$XDG_PICTURES_DIR"|"$XDG_PICTURES_DIR"/*)var__icon=${_MONORAIL_ICON[const_pictures]};;
"$XDG_VIDEOS_DIR"|"$XDG_VIDEOS_DIR"/*)var__icon=${_MONORAIL_ICON[10]};;
*/Downloads|*/Downloads/*|"$XDG_DOWNLOAD_DIR"|"$XDG_DOWNLOAD_DIR"/*)var__icon=${_MONORAIL_ICON[11]};;
*)var__icon=${_MONORAIL_ICON[13]}
esac
case $PWD in
"$HOME")TITLE_BASE=$_MONORAIL_SHORT_HOSTNAME
if [[ $CRAFT_STATE_DIR ]];then
var__icon=${_MONORAIL_ICON[const_snapcraft]}
elif [[ $SSH_CLIENT ]];then
var__icon=${_MONORAIL_ICON[1]}
elif [[ -e /.dockerenv ]];then
var__icon=${_MONORAIL_ICON[2]}
elif [[ -e /run/containerenv ]];then
var__icon=${_MONORAIL_ICON[3]}
else
var__icon=${_MONORAIL_ICON[0]}
fi
;;
*)
esac
fi
_MONORAIL_TITLE="${_MONORAIL_ICON_OVERRIDE-$var__icon}  ${_MONORAIL_TITLE_OVERRIDE-$TITLE_BASE}"
[[ $PWD != "$HOME" ]]&&[[ $_MONORAIL_HAS_SUFFIX ]]&&_MONORAIL_SUFFIX
local var__pwd_basename="${PWD##*/}"
[[ $var__pwd_basename ]]||var__pwd_basename=/
case $PWD in
"$HOME")var__pwd_basename="~";;
*)var__pwd_basename="${NAME-$var__pwd_basename}"
esac
local b=" $var__pwd_basename$_MONORAIL_GIT_PS1 "
b=${b//\.\.\./$'\xe2\x80\xa6'}
[[ ${#b} -gt $((COLUMNS/3)) ]]&&b=$' \xe2\x80\xa6'"${b:$((${#b}-$((COLUMNS/3))))}"
local b_array=()
for ((I=0; I<${#b}; I++));do
b_array[I]=${b[I]}
done
b_array_len=${#b_array[@]}
local var__rgb_cur_color var__rgb_cur_r var__rgb_cur_gb var__rgb_cur_g var__rgb_cur_b
if [[ $_MONORAIL_CACHE != "$COLUMNS$b" ]];then
unset _MONORAIL_CACHE _MEASURE
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
_COLORS=()
local I=0
local h=
. "$_MONORAIL_CONFIG/colors-$_MONORAIL_SHORT_HOSTNAME".conf
_MONORAIL_CACHE="$COLUMNS$b"
PS1=$'\e[?7l\e]0;'$_MONORAIL_TITLE$'\a\e[0m\r'"$h
$b_formatted%{"$'\r\e['$((${#b}+1))C$'\e[?7h\e[?25h\e]12;#$var__hex_cursor_color\a\e[0m'"%}"
fi
unset _MONORAIL_NOSTYLING
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
local var__icon="$1"
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
[[ $var__icon ]]&&if [[ -z $FIRST_NON_OPTION ]];then
_TITLE "${_MONORAIL_ICON_OVERRIDE-$var__icon}  ${FIRST_ARG##*/}"
else
_TITLE "${_MONORAIL_ICON_OVERRIDE-$var__icon}  ${FIRST_NON_OPTION##*/}"
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
home)_MONORAIL_ICON[0]=$1;;
ssh)_MONORAIL_ICON[1]=$1;;
docker)_MONORAIL_ICON[2]=$1;;
podman)_MONORAIL_ICON[3]=$1;;
git)_MONORAIL_ICON[4]=$1;;
repo)_MONORAIL_ICON[5]=$1;;
trash)_MONORAIL_ICON[6]=$1;;
documents)_MONORAIL_ICON[7]=$1;;
media)_MONORAIL_ICON[8]=$1;;
music)_MONORAIL_ICON[9]=$1;;
videos)_MONORAIL_ICON[10]=$1;;
downloads)_MONORAIL_ICON[11]=$1;;
settings)_MONORAIL_ICON[12]=$1;;
folder)_MONORAIL_ICON[13]=$1;;
completed)_MONORAIL_ICON[14]=$1;;
command)_MONORAIL_ICON[15]=$1;;
computer)_MONORAIL_ICON[16]=$1;;
system)_MONORAIL_ICON[17]=$1;;
*)echo "not supported value: $2"
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
[[ -e $_MONORAIL_CONFIG/settings-$_MONORAIL_SHORT_HOSTNAME.conf ]]||cat "$_MONORAIL_DIR/default_settings.conf" >"$_MONORAIL_CONFIG/settings-$_MONORAIL_SHORT_HOSTNAME.conf"
. "$_MONORAIL_CONFIG/settings-$_MONORAIL_SHORT_HOSTNAME.conf"
__git_ps1(){ :;}
_MONORAIL_MAGIC_SHELLBALL(){
local var__answer var__spaces i
var__spaces=
i=0
case "$RANDOM" in
*[0-4])case "$RANDOM" in
*0)var__answer="IT IS CERTAIN.";;
*1)var__answer="IT IS DECIDEDLY SO.";;
*2)var__answer="WITHOUT A DOUBT.";;
*3)var__answer="YES – DEFINITELY.";;
*4)var__answer="YOU MAY RELY ON IT.";;
*5)var__answer="AS I SEE IT, YES.";;
*6)var__answer="MOST LIKELY.";;
*7)var__answer="OUTLOOK GOOD.";;
*8)var__answer="YES.";;
*)var__answer="SIGNS POINT TO YES."
esac
;;
*)case "$RANDOM" in
*0)var__answer="REPLY HAZY, TRY AGAIN.";;
*1)var__answer="ASK AGAIN LATER.";;
*2)var__answer="BETTER NOT TELL YOU NOW.";;
*3)var__answer="CANNOT PREDICT NOW.";;
*4)var__answer="CONCENTRATE AND ASK AGAIN.";;
*5)var__answer="DON'T COUNT ON IT.";;
*6)var__answer="MY REPLY IS NO.";;
*7)var__answer="MY SOURCES SAY NO.";;
*8)var__answer="OUTLOOK NOT SO GOOD.";;
*)var__answer="VERY DOUBTFUL."
esac
esac
while [[ $i -lt $((COLUMNS/2-${#var__answer}/2)) ]];do
var__spaces+=" "
i=$((i+1))
done
echo -e "\e[?25l\e[3A\r\e[K$var__spaces$var__answer"
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
