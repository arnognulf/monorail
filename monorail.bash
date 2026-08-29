{
[[ $MONORAIL_DIR ]]||MONORAIL_DIR=$HOME/.local/share/monorail
[[ $HOSTNAME ]]||HOSTNAME=$(hostname)
if [[ $CRAFT_STATE_DIR ]];then
_mr_hostname=snapcraft
_mr_b=1
_mr_c(){
_mr_E="$_mr_E on $_mr_hostname"
}
elif [[ $SSH_CLIENT ]]||[[ $TMUX ]];then
_mr_b=1
_mr_c(){
_mr_E="$_mr_E on $_mr_hostname"
}
_mr_hostname=${HOSTNAME%%.*}
elif [[ -e /.dockerenv ]];then
_mr_hostname=docker
_mr_b=1
_mr_c(){
_mr_E="$_mr_E on $_mr_hostname"
}
elif [[ -e /run/containerenv ]];then
_mr_b=1
_mr_hostname=podman
_mr_c(){
_mr_E="$_mr_E on $_mr_hostname"
}
else
_mr_hostname=${HOSTNAME%%.*}
fi
[[ $BRUSH_VERSION ]]&&MONORAIL_COMPAT=1
_mr_hostname=${_mr_hostname,,}
unset _mr_A
_mr_w=
declare -a preexec_functions
_mr_w=1
_mr_x(){
[[ $_mr_A ]]&&return
local _mr_A=1
[[ ! -t 1 ]]&&return
[[ ${COMP_POINT:-} || ${READLINE_POINT:-} ]]&&return
if [[ -z ${_mr_w:-} ]];then
return
else
[[ 0 -eq ${BASH_SUBSHELL:-} ]]&&_mr_w=""
fi
local H IFS=$'\n;'
read -rd '' -a H <<<"${PROMPT_COMMAND[*]:-}"
local h="${BASH_COMMAND:-}"
h="${h#"${h%%[![:space:]]*}"}"
h="${h%"${h##*[![:space:]]}"}"
local l g
for l in "${H[@]:-}";do
g=$l
g="${g#"${g%%[![:space:]]*}"}"
g="${g%"${g##*[![:space:]]}"}"
[[ $g == "$h" ]]&&return
done
local a
a=$(LC_ALL=C HISTTIMEFORMAT='' builtin history 1)
a="${a#*[[:digit:]][* ] }"
[[ $a ]]||return
local L
for L in "${preexec_functions[@]:-}";do
if type -t "$L" >/dev/null;then
[[ ${_mr_y-0} == 0 ]]||(exit "${_mr_y-0}")
"$L" "$a"
fi
done
return "${_mr_y-0}"
}
_mr_C(){
[[ ${PROMPT_COMMAND[*]:-} == *"precmd"* ]]&&return 1
trap '_mr_x "$_"' DEBUG
eval "local P=(${_mr_D:-})"
local O=${P[2]:-}
unset _mr_D
if [[ $O ]];then
eval '_mr_B(){ '"$O"';}'
preexec_functions+=(_mr_B)
fi
local k
k="${HISTCONTROL:-}"
k="${k//ignorespace/}"
[[ $k == *"ignoreboth"* ]]&&k="ignoredups:${k//ignoreboth/}"
export HISTCONTROL="$k"
local f
f="${PROMPT_COMMAND:-}"
f="${f//$'_mr_D="$(trap -p DEBUG)"\ntrap - DEBUG\n_mr_C'/:}"
f="${f//$'\n':$'\n'/$'\n'}"
f="${f//$'\n':;/$'\n'}"
f="${f#"${f%%[![:space:]]*}"}"
f="${f%"${f##*[![:space:]]}"}"
f=${f%;}
f=${f#;}
[[ ${f:-:} == ":" ]]&&f=
PROMPT_COMMAND='precmd'
PROMPT_COMMAND+=${f:+$'\n'$f}
PROMPT_COMMAND+=('_mr_w=1')
preexec_functions+=(preexec)
_mr_z=1 precmd
_mr_w=1
}
_mr_H="${PROMPT_COMMAND:-}"
_mr_H="${_mr_H#"${_mr_H%%[![:space:]]*}"}"
_mr_H="${_mr_H%"${_mr_H##*[![:space:]]}"}"
_mr_H=${_mr_H%;}
_mr_H=${_mr_H#;}
_mr_t=
[[ $_mr_H ]]&&PROMPT_COMMAND=("$_mr_H")
PROMPT_COMMAND+=($'_mr_D="$(trap -p DEBUG)"\ntrap - DEBUG\n_mr_C')
preexec(){
{
[[ $(fc -l -1) == "$_mr_t" ]]&&return
_mr_t=$(fc -l -1)
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
_mr_i=${C/\\\007/<BEL>}
local Q l R=
for Q in "${_mr_l[@]}";do
[[ $Q == "${_mr_i%% *}" ]]&&R=1
done
B=${_mr_f[15]}
_mr_E="$B  $_mr_i"
[[ $_mr_b ]]&&_mr_c
N=${_mr_i%% *}
N=${N%%;*}
_mr_r=1
_mr_s=$SECONDS
_mr_E+=" in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M)"
[[ $R ]]||p=$'\e]0;'$_mr_E$'\a'
[[ $_mr_b ]]&&_mr_c
{
printf "$p"
[[ ${_mr_e[17]} ]]&&printf "\e]11;#${_mr_e[17]}\a\e]10;#${_mr_e[16]}\a\e]12;#${_mr_e[21]}\a\r\e[K"
} >/dev/tty
} >&- 2>&-
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
c+="\["$'\e['$((e+1))C$'\e'["$((e+1))"D$'\e[48;2;'${!j}m$'\e'"[38;2;${t[$((${#t[*]}*i/$((COLUMNS+1))))]}m\]${d[i]}"
i=$((i+1))
done
c+="\["$'\e'"[0;8m"$'\e'"[38;2;$((0x${_mr_e[17]:0:2}));$((0x${_mr_e[17]:2:2}));$((0x${_mr_e[17]:4:2}))m\]|"
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
_mr_e=("$@")
}
monorail_title(){
unset _mr_E_override
[[ $1 ]]&&_mr_E_override="$*"
}
monorail_icon(){
unset _mr_F
[[ $1 ]]&&_mr_F="$*"
}
_TITLE_RAW(){
[[ $_mr_G ]]&&return 0
printf "\e]0;%s\a\r\e[K" "$*" >/dev/tty 2>&-
}
[[ $MONORAIL_CONFIG ]]||MONORAIL_CONFIG=$HOME/.config/monorail
monorail_name(){
unset NAME
[[ $1 ]]&&NAME="$*"
}
precmd(){
{
if [[ $_mr_u ]];then
[[ $BLE_ATTACHED ]]||LC_MESSAGES=C LC_ALL=C stty echo
local T U V W X m
m=$((SECONDS-_mr_s))
if [[ $_mr_r ]]&&[[ $m -gt ${MONORAIL_TIMEOUT-30} ]];then
T=$((m%3600))
U=$((m/3600))
V=$((T/60))
W=$((T%60))
printf "\n\aCommand took "
X=
[[ $U -gt 0 ]]&&X="${U}h "
[[ $V -gt 0 ]]&&X+="${V}m "
X+="${W}s, finished at "$(LC_MESSAGES=C LC_ALL=C date +%H:%M).
echo "$X"
(exec notify-send -a "Completed $_mr_i" -i terminal "$_mr_i" "Command took $X"&)
(exec mplayer -quiet /usr/share/sounds/gnome/default/alerts/glass.ogg >&-&)
_mr_m=1
fi
unset _mr_r
local M
M=$?
printf "%$((COLUMNS-1))s\\r"
HISTCONTROL=
_mr_k=$(fc -l -1)
_mr_k=${_mr_k%%$'[\t ]'*}
if [[ -z $_mr_j ]];then
_mr_g=1
_mr_h=0
unset _mr_n
elif [[ $_mr_j == "$_mr_k" ]];then
if [[ -z $_mr_g ]]&&[[ $M == 0 ]]&&[[ -z $_mr_n ]];then
case "$_mr_h" in
0)ls
_mr_h=3
if \git status >&-;then
_mr_h=1
else
printf "\e[J\n\n"
fi
;;
2)_mr_h=3
\git -c color.status=always status|\head -n$((LINES-2))|\head -n$((LINES-4))
echo -e "        ...\n\n"
;;
*)_mr_q
esac
_mr_h=$((_mr_h+1))
fi
unset _mr_g
else
unset _mr_g
_mr_h=0
fi
unset _mr_n
_mr_j=$_mr_k
trap "_mr_n=1;echo -n" INT
trap "_mr_n=1;echo -n" ERR
[[ $BASH_VERSION ]]&&history -a >&-
else
alias for='_mr_G=1;for'
alias while='_mr_G=1;while'
alias until='_mr_G=1;until'
_mr_u=1
fi
if [[ $_mr_m ]];then
_mr_E="${_mr_f[14]} Completed $_mr_i"
[[ $_mr_b ]]&&_mr_c
unset _mr_m
else
case $PWD in
/run/user/*/gvfs/*)_mr_p=;;
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
if [[ -z $_mr_v ]];then
local u
u=$PWD
while [[ $u ]];do
if [[ -e "$u/.git" ]]&&[[ -e /usr/lib/git-core/git-sh-prompt ]];then
. /usr/lib/git-core/git-sh-prompt
_mr_v=1
fi
u=${u%/*}
done
fi
_mr_p=$(_TITLE(){
shift
"$@"
}
TERM=dumb GIT_CONFIG_GLOBAL="" LC_MESSAGES=C LC_ALL=C __git_ps1 "")
esac
local B S
S=${PWD##*/}
if [[ $y ]];then
B=${_mr_f[5]}
elif [[ $_mr_p ]];then
B=${_mr_f[4]}
else
case $PWD in
"$HOME/Trash"*|"$HOME/.local/share/Trash/files"*)B=${_mr_f[6]};;
/)B=${_mr_f[16]}
S=/
;;
/media/*)B=${_mr_f[8]};;
/proc/*|/sys/*|/dev/*|/proc|/sys|/dev)B=${_mr_f[17]};;
*/Documents|*/Documents/*|*/doc|*/docs|*/doc/*|*/docs/*|"$XDG_DOCUMENTS_DIR"|"$XDG_DOCUMENTS_DIR"/*)B=${_mr_f[7]};;
"$XDG_MUSIC_DIR"|"$XDG_MUSIC_DIR"/*)B=${_mr_f[9]};;
"$XDG_PICTURES_DIR"|"$XDG_PICTURES_DIR"/*)B=${_mr_f[19]};;
"$XDG_VIDEOS_DIR"|"$XDG_VIDEOS_DIR"/*)B=${_mr_f[10]};;
*/Downloads|*/Downloads/*|"$XDG_DOWNLOAD_DIR"|"$XDG_DOWNLOAD_DIR"/*)B=${_mr_f[11]};;
*)B=${_mr_f[13]}
esac
case $PWD in
"$HOME")S=$_mr_hostname
if [[ $CRAFT_STATE_DIR ]];then
B=${_mr_f[18]}
elif [[ $SSH_CLIENT ]];then
B=${_mr_f[1]}
elif [[ -e /.dockerenv ]];then
B=${_mr_f[2]}
elif [[ -e /run/containerenv ]];then
B=${_mr_f[3]}
else
B=${_mr_f[0]}
fi
;;
*)
esac
fi
_mr_E="${_mr_F-$B}  ${_mr_E_override-$S}"
[[ $PWD != "$HOME" ]]&&[[ $_mr_b ]]&&_mr_c
fi
local z="${PWD##*/}"
[[ $z ]]||z=/
case $PWD in
"$HOME")z="~";;
*)z="${NAME-$z}"
esac
local b=" $z$_mr_p "
b=${b//\.\.\./$'\xe2\x80\xa6'}
[[ ${#b} -gt $((COLUMNS/3)) ]]&&b=$' \xe2\x80\xa6'"${b:$((${#b}-$((COLUMNS/3))))}"
local d=()
for ((I=0; I<${#b}; I++));do
d[I]=${b:I:1}
done
local e=${#d[@]}
local w D E F G
if [[ $_mr_o != "$COLUMNS$b" ]];then
unset _mr_o _mr_r
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
_mr_e=()
local i=0
local v=
local p=
local r
local c=
. "$MONORAIL_CONFIG/colors-$_mr_hostname".conf
if [[ -z $c ]];then
v=$'\e[4m'
while [[ $i -lt $COLUMNS ]];do
v+=' '
i=$((i+1))
done
c=$'\e[0;7m'$b$'\e[0m'
fi
_mr_o="$COLUMNS$b"
PS1=$'\e[?7l\e]0;''$_mr_E''\a\e[0m\r'"$v
$c\["$'\r\e['$((${#b}+1))C$'\e[?7h\e[?25h\e]12;'"#$r"$'\a\e[0m'"\]"
fi
unset _mr_G
[[ ${_mr_e[17]} ]]&&printf "\e[?25l\e[${COLUMNS}C\e]11;#${_mr_e[17]}\a\e]10;#${_mr_e[16]}\a\e]4;0;#${_mr_e[0]}\a\e]4;1;#${_mr_e[1]}\a\e]4;2;#${_mr_e[2]}\a\e]4;3;#${_mr_e[3]}\a\e]4;4;#${_mr_e[4]}\a\e]4;5;#${_mr_e[5]}\a\e]4;6;#${_mr_e[6]}\a\e]4;7;#${_mr_e[7]}\a\e]4;8;#${_mr_e[8]}\a\e]4;9;#${_mr_e[9]}\a\e]4;12;#${_mr_e[12]}\a\e]4;13;#${_mr_e[13]}\a\e]4;14;#${_mr_e[14]}\a\e]4;15;#${_mr_e[15]}\a"
} 2>&-
}
_TITLE(){
local _mr_E="$*"
if [[ $_mr_r ]];then
_mr_E+=" in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M 2>&-)"
elif [[ $PWD == "$HOME" ]];then
:
else
_mr_E+=" in ${PWD##*/}"
fi
[[ $_mr_b ]]&&_mr_c
_TITLE_RAW "$_mr_E"
}
_NO_MEASURE(){
unset _mr_r
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
_TITLE "${_mr_F-$B}  ${FIRST_ARG##*/}"
else
_TITLE "${_mr_F-$B}  ${FIRST_NON_OPTION##*/}"
fi) >& \
- 2>&-
fi
"$@"
}
trap "unset _mr_o" WINCH
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
home)_mr_f[0]=$1;;
ssh)_mr_f[1]=$1;;
docker)_mr_f[2]=$1;;
podman)_mr_f[3]=$1;;
git)_mr_f[4]=$1;;
repo)_mr_f[5]=$1;;
trash)_mr_f[6]=$1;;
documents)_mr_f[7]=$1;;
media)_mr_f[8]=$1;;
music)_mr_f[9]=$1;;
videos)_mr_f[10]=$1;;
downloads)_mr_f[11]=$1;;
settings)_mr_f[12]=$1;;
folder)_mr_f[13]=$1;;
completed)_mr_f[14]=$1;;
command)_mr_f[15]=$1;;
computer)_mr_f[16]=$1;;
system)_mr_f[17]=$1;;
snapcraft)_mr_f[18]=$1;;
pictures)_mr_f[19]=$1;;
*)echo "ERROR: not supported value: $2" >/dev/tty
esac
}
_monorail_cmd_interactive(){
command -v "$2"&&alias "$2=_NO_MEASURE _ICON $1 $2"
}
_monorail_cmd_batch(){
command -v "$2"&&alias "$2=_ICON $1 _LOW_PRIO $2"
}
_mr_l=()
_monorail_cmd_ignored(){
_mr_l[${#_mr_l[@]}]=$1
}
[[ -e $MONORAIL_CONFIG/settings-$_mr_hostname.conf ]]||cat "$MONORAIL_DIR/default_settings.conf" >"$MONORAIL_CONFIG/settings-$_mr_hostname.conf"
. "$MONORAIL_CONFIG/settings-$_mr_hostname.conf"||{
. "$MONORAIL_DIR"/monorail.sh
_MONORAIL_UPDATE
return
}
__git_ps1(){ :;}
_mr_q(){
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
