{
[[ $MONORAIL_DIR ]]||MONORAIL_DIR=$HOME/.local/share/monorail
[[ $HOSTNAME ]]||HOSTNAME=$(hostname)
if [[ $CRAFT_STATE_DIR ]];then
_mr_hostname=snapcraft
glob__has_suffix=1
glob__suffix(){
glob__title="$glob__title on $_mr_hostname"
}
elif [[ $SSH_CLIENT ]]||[[ $TMUX ]];then
glob__has_suffix=1
glob__suffix(){
glob__title="$glob__title on $_mr_hostname"
}
_mr_hostname=${HOSTNAME%%.*}
elif [[ -e /.dockerenv ]];then
_mr_hostname=docker
glob__has_suffix=1
glob__suffix(){
glob__title="$glob__title on $_mr_hostname"
}
elif [[ -e /run/containerenv ]];then
glob__has_suffix=1
_mr_hostname=podman
glob__suffix(){
glob__title="$glob__title on $_mr_hostname"
}
else
_mr_hostname=${HOSTNAME%%.*}
fi
setopt KSH_ARRAYS
setopt prompt_subst
_mr_hostname=${_mr_hostname:l}
glob__prev_cmd=
preexec(){
{
[[ $(fc -l -1) == "$glob__prev_cmd" ]]&&return
glob__prev_cmd=$(fc -l -1)
local C B N
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
glob__timer_cmd=${C/\\\007/<BEL>}
local Q l R=
for Q in "${glob__cmd_ignored[@]}";do
[[ $Q == "${glob__timer_cmd%% *}" ]]&&R=1
done
B=${glob__icons[15]}
glob__title="$B  $glob__timer_cmd"
[[ $glob__has_suffix ]]&&glob__suffix
N=${glob__timer_cmd%% *}
N=${N%%;*}
glob__measure=1
glob__start_seconds=$SECONDS
glob__title+=" in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M)"
[[ $R ]]||p=$'\e]0;'$glob__title$'\a'
[[ $glob__has_suffix ]]&&glob__suffix
{
printf "$p"
[[ ${glob__colors[17]} ]]&&printf "\e]11;#${glob__colors[17]}\a\e]10;#${glob__colors[16]}\a\e]12;#${glob__colors[21]}\a\r\e[K"
} >/dev/tty
} &>/dev/null
}
_monorail_gradient(){
local i=0
local j
while [[ $i -le $COLUMNS ]];do
j=$((1+$#*i/$((COLUMNS+1))))
v+=$'\e'"[38;2;${!j}m"$'\xe2\x96\x81'
i=$((i+1))
done
i=0
[[ ${t[*]} ]]||t[0]="255;255;255"
while [[ $i -lt $e ]];do
j=$((1+$#*i/$((COLUMNS+1))))
c+="%{"$'\e['$((e+1))C$'\e'["$((e+1))"D$'\e[48;2;'${!j}m$'\e'"[38;2;${t[$((${#t[*]}*i/$((COLUMNS+1))))]}m%}${d[i]}"
i=$((i+1))
done
c+="%{"$'\e'"[0;8m"$'\e'"[38;2;$((0x${glob__colors[17]:0:2}));$((0x${glob__colors[17]:2:2}));$((0x${glob__colors[17]:4:2}))m%}|"
j=$(($#*$((e+1))/$((COLUMNS+1))))
w=${!j}
D=${w%%;*}
E=${w#*;}
F=${E%%;*}
G=${E##*;}
r=$(printf "%.2x%.2x%.2x" "$D" "$F" "$G")
}
_monorail_textgradient(){
t=("$@")
}
_monorail_colors(){
glob__colors=("$@")
}
monorail_title(){
unset glob__title_override
[[ $1 ]]&&glob__title_override="$*"
}
monorail_icon(){
unset glob__icon_override
[[ $1 ]]&&glob__icon_override="$*"
}
_TITLE_RAW(){
[[ $glob__nostyling ]]&&return 0
printf "\e]0;%s\a\r\e[K" "$*" >/dev/tty 2>&-
}
[[ $MONORAIL_CONFIG ]]||MONORAIL_CONFIG=$HOME/.config/monorail
monorail_name(){
unset NAME
[[ $1 ]]&&NAME="$*"
}
precmd(){
{
if [[ $glob__launched ]];then
[[ $BLE_ATTACHED ]]||LC_MESSAGES=C LC_ALL=C stty echo
local var__seconds_m var__duration_h var__duration_m var__duration_s var__duration m
m=$((SECONDS-glob__start_seconds))
if [[ $glob__measure ]]&&[[ $m -gt ${MONORAIL_TIMEOUT-30} ]];then
var__seconds_m=$((m%3600))
var__duration_h=$((m/3600))
var__duration_m=$((var__seconds_m/60))
var__duration_s=$((var__seconds_m%60))
printf "\n\aCommand took "
var__duration=
[[ $var__duration_h -gt 0 ]]&&var__duration="${var__duration_h}h "
[[ $var__duration_m -gt 0 ]]&&var__duration+="${var__duration_m}m "
var__duration+="${var__duration_s}s, finished at "$(LC_MESSAGES=C LC_ALL=C date +%H:%M).
echo "$var__duration"
(exec notify-send -a "Completed $glob__timer_cmd" -i terminal "$glob__timer_cmd" "Command took $var__duration"&)
(exec mplayer -quiet /usr/share/sounds/gnome/default/alerts/glass.ogg >&-&)
glob__longrunning=1
fi
unset glob__measure
local M
M=$?
printf "%$((COLUMNS-1))s\\r"
HISTCONTROL=
glob__histcmd_prev=$(fc -l -1)
glob__histcmd_prev=${glob__histcmd_prev%%$'[\t ]'*}
if [[ -z $glob__histcmd_penultimate ]];then
glob__cr_first=1
glob__cr_level=0
unset glob__ctrlc
elif [[ $glob__histcmd_penultimate == "$glob__histcmd_prev" ]];then
if [[ -z $glob__cr_first ]]&&[[ $M == 0 ]]&&[[ -z $glob__ctrlc ]];then
case "$glob__cr_level" in
0)ls
glob__cr_level=3
if \git status >&-;then
glob__cr_level=1
else
printf "\e[J\n\n"
fi
;;
2)glob__cr_level=3
\git -c color.status=always status|\head -n$((LINES-2))|\head -n$((LINES-4))
echo -e "        ...\n\n"
;;
*)glob__magic_shellball
esac
glob__cr_level=$((glob__cr_level+1))
fi
unset glob__cr_first
else
unset glob__cr_first
glob__cr_level=0
fi
unset glob__ctrlc
glob__histcmd_penultimate=$glob__histcmd_prev
trap "glob__ctrlc=1;echo -n" INT
trap "glob__ctrlc=1;echo -n" ERR
else
alias for='glob__nostyling=1;for'
alias while='glob__nostyling=1;while'
alias until='glob__nostyling=1;until'
glob__launched=1
fi
if [[ $glob__longrunning ]];then
glob__title="${glob__icons[14]} Completed $glob__timer_cmd"
[[ $glob__has_suffix ]]&&glob__suffix
unset glob__longrunning
else
case $PWD in
/run/user/*/gvfs/*)glob__git_ps1=;;
*)local x y
x=$PWD
y=
while [[ "$x" ]];do
if [[ -d "$x/.repo" ]];then
y=1
break
fi
x="${x%/*}"
done
if [[ -z $glob__git_loaded ]];then
local u
u=$PWD
while [[ $u ]];do
if [[ -e "$u/.git" ]]&&[[ -e /usr/lib/git-core/git-sh-prompt ]];then
. /usr/lib/git-core/git-sh-prompt
glob__git_loaded=1
fi
u=${u%/*}
done
fi
glob__git_ps1=$(_TITLE(){
shift
"$@"
}
TERM=dumb GIT_CONFIG_GLOBAL="" LC_MESSAGES=C LC_ALL=C __git_ps1 "")
esac
local B S
S=${PWD##*/}
if [[ $y ]];then
B=${glob__icons[5]}
elif [[ $glob__git_ps1 ]];then
B=${glob__icons[4]}
else
case $PWD in
"$HOME/Trash"*|"$HOME/.local/share/Trash/files"*)B=${glob__icons[6]};;
/)B=${glob__icons[16]}
S=/
;;
/media/*)B=${glob__icons[8]};;
/proc/*|/sys/*|/dev/*|/proc|/sys|/dev)B=${glob__icons[17]};;
*/Documents|*/Documents/*|*/doc|*/docs|*/doc/*|*/docs/*|"$XDG_DOCUMENTS_DIR"|"$XDG_DOCUMENTS_DIR"/*)B=${glob__icons[7]};;
"$XDG_MUSIC_DIR"|"$XDG_MUSIC_DIR"/*)B=${glob__icons[9]};;
"$XDG_PICTURES_DIR"|"$XDG_PICTURES_DIR"/*)B=${glob__icons[const_pictures]};;
"$XDG_VIDEOS_DIR"|"$XDG_VIDEOS_DIR"/*)B=${glob__icons[10]};;
*/Downloads|*/Downloads/*|"$XDG_DOWNLOAD_DIR"|"$XDG_DOWNLOAD_DIR"/*)B=${glob__icons[11]};;
*)B=${glob__icons[13]}
esac
case $PWD in
"$HOME")S=$_mr_hostname
if [[ $CRAFT_STATE_DIR ]];then
B=${glob__icons[const_snapcraft]}
elif [[ $SSH_CLIENT ]];then
B=${glob__icons[1]}
elif [[ -e /.dockerenv ]];then
B=${glob__icons[2]}
elif [[ -e /run/containerenv ]];then
B=${glob__icons[3]}
else
B=${glob__icons[0]}
fi
;;
*)
esac
fi
glob__title="${glob__icon_override-$B}  ${glob__title_override-$S}"
[[ $PWD != "$HOME" ]]&&[[ $glob__has_suffix ]]&&glob__suffix
fi
local z="${PWD##*/}"
[[ $z ]]||z=/
case $PWD in
"$HOME")z="~";;
*)z="${NAME-$z}"
esac
local b=" $z$glob__git_ps1 "
b=${b//\.\.\./$'\xe2\x80\xa6'}
[[ ${#b} -gt $((COLUMNS/3)) ]]&&b=$' \xe2\x80\xa6'"${b:$((${#b}-$((COLUMNS/3))))}"
local d=()
for ((I=0; I<${#b}; I++));do
d[I]=${b[I]}
done
local e=${#d[@]}
local w D E F G
if [[ $glob__cache != "$COLUMNS$b" ]];then
unset glob__cache glob__measure
if [[ ! -f "$MONORAIL_CONFIG/colors-$_mr_hostname".conf ]];then
mkdir -p "$MONORAIL_CONFIG"
if [[ -f "$MONORAIL_DIR/gradients/Default.conf" ]];then
if [[ $(gsettings get org.gnome.desktop.interface color-scheme) == prefer-dark ]];then
LC_ALL=C LC_MESSAGES=C \cat "$MONORAIL_DIR"/colors/DefaultDark.conf "$MONORAIL_DIR"/gradients/Default.conf >"$MONORAIL_CONFIG/colors-$_mr_hostname".conf
else
LC_ALL=C LC_MESSAGES=C \cat "$MONORAIL_DIR"/colors/Default.conf "$MONORAIL_DIR"/gradients/Default.conf >"$MONORAIL_CONFIG/colors-$_mr_hostname".conf
fi
else
printf "\
monorail: warning: Monorail was not found in $MONORAIL_DIR.
                   Do this to make colors and gradients work:
                     1. Move monorail directory to $MONORAIL_DIR
                     2. rm -rf $MONORAIL_CONFIG
                     3. Restart terminal." >/dev/tty
fi
fi
glob__colors=()
local i=0
local v=
local p=
local r
local c=
. "$MONORAIL_CONFIG/colors-$_mr_hostname".conf
if [[ -z $c ]];then
v=
while [[ $i -lt $COLUMNS ]];do
v+=$'\xe2\x96\x81'
i=$((i+1))
done
c="%{"$'\e[0;7m'"%}"$b"%{"$'\e[0m'"%}"
fi
glob__cache="$COLUMNS$b"
PS1=$'\e[?7l\e]0;''$glob__title''\a\e[0m\r'"$v
$c%{"$'\r\e['$((${#b}+1))C$'\e[?7h\e[?25h\e[0m'"%}"
fi
unset glob__nostyling
[[ ${glob__colors[17]} ]]&&printf "\e[?25l\e[${COLUMNS}C\e]12;#$r\a\e]11;#${glob__colors[17]}\a\e]10;#${glob__colors[16]}\a\e]4;0;#${glob__colors[0]}\a\e]4;1;#${glob__colors[1]}\a\e]4;2;#${glob__colors[2]}\a\e]4;3;#${glob__colors[3]}\a\e]4;4;#${glob__colors[4]}\a\e]4;5;#${glob__colors[5]}\a\e]4;6;#${glob__colors[6]}\a\e]4;7;#${glob__colors[7]}\a\e]4;8;#${glob__colors[8]}\a\e]4;9;#${glob__colors[9]}\a\e]4;12;#${glob__colors[12]}\a\e]4;13;#${glob__colors[13]}\a\e]4;14;#${glob__colors[14]}\a\e]4;15;#${glob__colors[15]}\a"
} 2>/dev/null
}
_TITLE(){
local glob__title="$*"
if [[ $glob__measure ]];then
glob__title+=" in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M 2>&-)"
elif [[ $PWD == "$HOME" ]];then
:
else
glob__title+=" in ${PWD##*/}"
fi
[[ $glob__has_suffix ]]&&glob__suffix
_TITLE_RAW "$glob__title"
}
_NO_MEASURE(){
unset glob__measure
"$@"
}
_ICON(){
local B="$1"
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
[[ $B ]]&&if [[ -z $FIRST_NON_OPTION ]];then
_TITLE "${glob__icon_override-$B}  ${FIRST_ARG##*/}"
else
_TITLE "${glob__icon_override-$B}  ${FIRST_NON_OPTION##*/}"
fi) >& \
- 2>&-
fi
"$@"
}
trap "unset glob__cache" WINCH
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
home)glob__icons[0]=$1;;
ssh)glob__icons[1]=$1;;
docker)glob__icons[2]=$1;;
podman)glob__icons[3]=$1;;
git)glob__icons[4]=$1;;
repo)glob__icons[5]=$1;;
trash)glob__icons[6]=$1;;
documents)glob__icons[7]=$1;;
media)glob__icons[8]=$1;;
music)glob__icons[9]=$1;;
videos)glob__icons[10]=$1;;
downloads)glob__icons[11]=$1;;
settings)glob__icons[12]=$1;;
folder)glob__icons[13]=$1;;
completed)glob__icons[14]=$1;;
command)glob__icons[15]=$1;;
computer)glob__icons[16]=$1;;
system)glob__icons[17]=$1;;
snapcraft)glob__icons[const_snapcraft]=$1;;
pictures)glob__icons[const_pictures]=$1;;
*)echo "ERROR: not supported value: $2" >/dev/tty
esac
}
_monorail_cmd_interactive(){
command -v "$2"&&alias "$2=_NO_MEASURE _ICON $1 $2"
}
_monorail_cmd_batch(){
command -v "$2"&&alias "$2=_ICON $1 _LOW_PRIO $2"
}
glob__cmd_ignored=()
_monorail_cmd_ignored(){
glob__cmd_ignored[${#glob__cmd_ignored[@]}]=$1
}
[[ -e $MONORAIL_CONFIG/settings-$_mr_hostname.conf ]]||cat "$MONORAIL_DIR/default_settings.conf" >"$MONORAIL_CONFIG/settings-$_mr_hostname.conf"
. "$MONORAIL_CONFIG/settings-$_mr_hostname.conf"||{
. "$MONORAIL_DIR"/monorail.sh
_MONORAIL_UPDATE
return
}
__git_ps1(){ :;}
glob__magic_shellball(){
local s A i
A=
i=0
case "$RANDOM" in
*[0-4])case "$RANDOM" in
*0)s="IT IS CERTAIN.";;
*1)s="IT IS DECIDEDLY SO.";;
*2)s="WITHOUT A DOUBT.";;
*3)s="YES – DEFINITELY.";;
*4)s="YOU MAY RELY ON IT.";;
*5)s="AS I SEE IT, YES.";;
*6)s="MOST LIKELY.";;
*7)s="OUTLOOK GOOD.";;
*8)s="YES.";;
*)s="SIGNS POINT TO YES."
esac
;;
*)case "$RANDOM" in
*0)s="REPLY HAZY, TRY AGAIN.";;
*1)s="ASK AGAIN LATER.";;
*2)s="BETTER NOT TELL YOU NOW.";;
*3)s="CANNOT PREDICT NOW.";;
*4)s="CONCENTRATE AND ASK AGAIN.";;
*5)s="DON'T COUNT ON IT.";;
*6)s="MY REPLY IS NO.";;
*7)s="MY SOURCES SAY NO.";;
*8)s="OUTLOOK NOT SO GOOD.";;
*)s="VERY DOUBTFUL."
esac
esac
while [[ $i -lt $((COLUMNS/2-${#s}/2)) ]];do
A+=" "
i=$((i+1))
done
echo -e "\e[?25l\e[3A\r\e[K$A$s"
}
if [[ $TERM == xterm-256color ]];then
[[ $ZUTTY_VERSION ]]&&MONORAIL_COMPAT=1
[[ $TERM_PROGRAM == vscode ]]&&MONORAIL_COMPAT=1
elif [[ $MC_TMPDIR ]];then
MONORAIL_COMPAT=1
else
case $TERM in
xterm-color|xterm-16color|rio|rxvt-unicode-256color|mlterm|st-256color|foot|alacritty)MONORAIL_COMPAT=1
;;
xterm*)printf "\e[?25l\e[?7l\e[%sC\e]0; \a\r\e[K" "$COLUMNS" >/dev/tty 2>&-
[[ $TERM == xterm-ghostty ]]&&unalias ssh 2>/dev/null
[[ $(tty) =~ "/dev/ttyv"* ]]&&MONORAIL_COMPAT=1
[[ $WINDOWID == 0 ]]&&MONORAIL_COMPAT=1
case $XTERM_LOCALE in
""|*.UTF-8):;;
*)MONORAIL_COMPAT=1
esac
;;
*)MONORAIL_COMPAT=1
esac
fi
[[ $MONORAIL_COMPAT ]]&&if [[ ! $MONORAIL_DISABLE_COMPAT ]];then
unalias git >/dev/null 2>/dev/null
. "$MONORAIL_DIR/monorail.sh"
fi
alias monorail_color="_mr_hostname=$_mr_hostname MONORAIL_CONFIG=$MONORAIL_CONFIG MONORAIL_DIR=$MONORAIL_DIR sh $MONORAIL_DIR/scripts/color.sh"
alias monorail_gradient="_mr_hostname=$_mr_hostname MONORAIL_CONFIG=$MONORAIL_CONFIG MONORAIL_DIR=$MONORAIL_DIR sh $MONORAIL_DIR/scripts/gradient.sh"
alias monorail_image="_mr_hostname=$_mr_hostname MONORAIL_CONFIG=$MONORAIL_CONFIG MONORAIL_DIR=$MONORAIL_DIR sh $MONORAIL_DIR/scripts/image.sh"
alias monorail_textgradient="_mr_hostname=$_mr_hostname MONORAIL_CONFIG=$MONORAIL_CONFIG MONORAIL_DIR=$MONORAIL_DIR sh $MONORAIL_DIR/scripts/gradient.sh --text"
alias rgb="sh $MONORAIL_DIR/scripts/rgb.sh"
} >&- 2>&-
