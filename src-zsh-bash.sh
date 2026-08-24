#!/bin/bash
# Copyright (c) 2025 Thomas Eriksson
#
# Contains code from bash-preexec
# Copyright (c) 2017 Ryan Caloras and contributors (see https://github.com/rcaloras/bash-preexec)
# SPDX-License-Identifier: BSD-3-Clause
# see FAST_SHELL_GUIDELINES.md on coding guidelines for this file.
const_home=0              #discard_for_all
const_ssh=1               #discard_for_all
const_docker=2            #discard_for_all
const_podman=3            #discard_for_all
const_git=4               #discard_for_all
const_repo=5              #discard_for_all
const_trash=6             #discard_for_all
const_documents=7         #discard_for_all
const_media=8             #discard_for_all
const_music=9             #discard_for_all
const_videos=10           #discard_for_all
const_downloads=11        #discard_for_all
const_settings=12         #discard_for_all
const_folder=13           #discard_for_all
const_completed=14        #discard_for_all
const_command=15          #discard_for_all
const_computer=16         #discard_for_all
const_system=17           #discard_for_all
const_color_foreground=16 #discard_for_all
const_color_background=17 #discard_for_all
const_color_cursor=21     #discard_for_all
{
	# the monorail dir is hardcoded to simplify installation instructions
	# for XDG compliance, the user may set MONORAIL_DIR=$XDG_LOCAL_SHARE/monorail and MONORAIL_CONFIG=$XDG_CONFIG_HOME/monorail
	[[ $MONORAIL_DIR ]] || MONORAIL_DIR=$HOME/.local/share/monorail
	[[ $HOSTNAME ]] || HOSTNAME=$(hostname)
	if [[ $CRAFT_STATE_DIR ]]; then
		_mr_hostname=snapcraft
		glob__has_suffix=1
		glob__suffix() {
			glob__title="$glob__title on $_mr_hostname"
		}
	elif [[ $SSH_CLIENT ]] || [[ $TMUX ]]; then
		glob__has_suffix=1
		glob__suffix() {
			glob__title="$glob__title on $_mr_hostname"
		}
		_mr_hostname=${HOSTNAME%%.*}
	elif [[ -e /.dockerenv ]]; then
		_mr_hostname=docker
		glob__has_suffix=1
		glob__suffix() {
			glob__title="$glob__title on $_mr_hostname"
		}
	elif [[ -e /run/containerenv ]]; then
		glob__has_suffix=1
		_mr_hostname=podman
		glob__suffix() {
			glob__title="$glob__title on $_mr_hostname"
		}
	else
		_mr_hostname=${HOSTNAME%%.*}
	fi
	setopt KSH_ARRAYS              #keep_for_zsh
	setopt prompt_subst            #keep_for_zsh
	_mr_hostname=${_mr_hostname:l} #keep_for_zsh
	# brush 0.4.0 needs to run posix version
	[[ $BRUSH_VERSION ]] && MONORAIL_COMPAT=1 #keep_for_bash
	_mr_hostname=${_mr_hostname,,}            #keep_for_bash
	# this is a rather hackish method of enabling `preexec()` on first command
	unset glob__inside_preexec                              #keep_for_bash
	glob__preexec_interactive_mode=                         #keep_for_bash
	declare -a preexec_functions                            #keep_for_bash
	glob__preexec_interactive_mode=1                        #keep_for_bash
	glob__preexec_invoke_exec() {                           #keep_for_bash
		[[ $glob__inside_preexec ]] && return                  #keep_for_bash
		local glob__inside_preexec=1                           #keep_for_bash
		[[ ! -t 1 ]] && return                                 #keep_for_bash
		[[ ${COMP_POINT:-} || ${READLINE_POINT:-} ]] && return #keep_for_bash
		# this -z cannot be removed since it would break bash-preexec (wat?)
		if [[ -z ${glob__preexec_interactive_mode:-} ]]; then                #keep_for_bash
			return                                                              #keep_for_bash
		else                                                                 #keep_for_bash
			[[ 0 -eq ${BASH_SUBSHELL:-} ]] && glob__preexec_interactive_mode="" #keep_for_bash
		fi                                                                   #keep_for_bash

		local var__prompt_command_array IFS=$'\n;'                                  #keep_for_bash
		read -rd '' -a var__prompt_command_array <<<"${PROMPT_COMMAND[*]:-}"        #keep_for_bash
		local var__trimmed_arg="${BASH_COMMAND:-}"                                  #keep_for_bash
		var__trimmed_arg="${var__trimmed_arg#"${var__trimmed_arg%%[![:space:]]*}"}" #keep_for_bash
		var__trimmed_arg="${var__trimmed_arg%"${var__trimmed_arg##*[![:space:]]}"}" #keep_for_bash

		local var__command var__trimmed_command                                                  #keep_for_bash
		for var__command in "${var__prompt_command_array[@]:-}"; do                              #keep_for_bash
			var__trimmed_command=${var__command}                                                    #keep_for_bash
			var__trimmed_command="${var__trimmed_command#"${var__trimmed_command%%[![:space:]]*}"}" #keep_for_bash
			var__trimmed_command="${var__trimmed_command%"${var__trimmed_command##*[![:space:]]}"}" #keep_for_bash
			[[ $var__trimmed_command = "$var__trimmed_arg" ]] && return                             #keep_for_bash
		done                                                                                     #keep_for_bash

		local var__this_command                                           #keep_for_bash
		var__this_command=$(LC_ALL=C HISTTIMEFORMAT='' builtin history 1) #keep_for_bash
		var__this_command="${var__this_command#*[[:digit:]][* ] }"        #keep_for_bash
		[[ $var__this_command ]] || return                                #keep_for_bash
		local var__preexec_function                                       #keep_for_bash
		for var__preexec_function in "${preexec_functions[@]:-}"; do      #keep_for_bash
			if type -t "$var__preexec_function" >/dev/null; then             #keep_for_bash
				# TODO: glob__last_ret_value is never set! accidently removed?
				[[ ${glob__last_ret_value-0} = 0 ]] || (exit "${glob__last_ret_value-0}")                                                            #keep_for_bash
				"$var__preexec_function" "$var__this_command"                                                                                        #keep_for_bash
			fi                                                                                                                                    #keep_for_bash
		done                                                                                                                                   #keep_for_bash
		return "${glob__last_ret_value-0}"                                                                                                     #keep_for_bash
	}                                                                                                                                       #keep_for_bash
	glob__install() {                                                                                                                       #keep_for_bash
		[[ ${PROMPT_COMMAND[*]:-} = *"precmd"* ]] && return 1                                                                                  #keep_for_bash
		trap 'glob__preexec_invoke_exec "$_"' DEBUG                                                                                            #keep_for_bash
		eval "local var__trap_argv=(${glob__trap_string:-})"                                                                                   #keep_for_bash
		local var__prior_trap=${var__trap_argv[2]:-}                                                                                           #keep_for_bash
		unset glob__trap_string                                                                                                                #keep_for_bash
		if [[ $var__prior_trap ]]; then                                                                                                        #keep_for_bash
			eval 'glob__original_debug_trap(){ '"$var__prior_trap"';}'                                                                            #keep_for_bash
			preexec_functions+=(glob__original_debug_trap)                                                                                        #keep_for_bash
		fi                                                                                                                                     #keep_for_bash
		local var__histcontrol                                                                                                                 #keep_for_bash
		var__histcontrol="${HISTCONTROL:-}"                                                                                                    #keep_for_bash
		var__histcontrol="${var__histcontrol//ignorespace/}"                                                                                   #keep_for_bash
		[[ $var__histcontrol = *"ignoreboth"* ]] && var__histcontrol="ignoredups:${var__histcontrol//ignoreboth/}"                             #keep_for_bash
		export HISTCONTROL="$var__histcontrol"                                                                                                 #keep_for_bash
		local var__existing_prompt_command                                                                                                     #keep_for_bash
		var__existing_prompt_command="${PROMPT_COMMAND:-}"                                                                                     #keep_for_bash
		var__existing_prompt_command="${var__existing_prompt_command//$'glob__trap_string="$(trap -p DEBUG)"\ntrap - DEBUG\nglob__install'/:}" #keep_for_bash
		var__existing_prompt_command="${var__existing_prompt_command//$'\n':$'\n'/$'\n'}"                                                      #keep_for_bash
		var__existing_prompt_command="${var__existing_prompt_command//$'\n':;/$'\n'}"                                                          #keep_for_bash

		var__existing_prompt_command="${var__existing_prompt_command#"${var__existing_prompt_command%%[![:space:]]*}"}" #keep_for_bash
		var__existing_prompt_command="${var__existing_prompt_command%"${var__existing_prompt_command##*[![:space:]]}"}" #keep_for_bash
		var__existing_prompt_command=${var__existing_prompt_command%;}                                                  #keep_for_bash
		var__existing_prompt_command=${var__existing_prompt_command#;}                                                  #keep_for_bash
		[[ ${var__existing_prompt_command:-:} = ":" ]] && var__existing_prompt_command=                                 #keep_for_bash
		PROMPT_COMMAND='precmd'                                                                                         #keep_for_bash
		PROMPT_COMMAND+=${var__existing_prompt_command:+$'\n'$var__existing_prompt_command}                             #keep_for_bash
		PROMPT_COMMAND+=('glob__preexec_interactive_mode=1')                                                            #keep_for_bash
		preexec_functions+=(preexec)                                                                                    #keep_for_bash
		glob__inside_precmd=1 precmd                                                                                    #keep_for_bash
		glob__preexec_interactive_mode=1                                                                                #keep_for_bash
	}                                                                                                                #keep_for_bash
	var__sanitized="${PROMPT_COMMAND:-}"                                                                             #keep_for_bash
	var__sanitized="${var__sanitized#"${var__sanitized%%[![:space:]]*}"}"                                            #keep_for_bash
	var__sanitized="${var__sanitized%"${var__sanitized##*[![:space:]]}"}"                                            #keep_for_bash
	var__sanitized=${var__sanitized%;}                                                                               #keep_for_bash
	var__sanitized=${var__sanitized#;}                                                                               #keep_for_bash

	[[ $var__sanitized ]] && PROMPT_COMMAND=("$var__sanitized")                            #keep_for_bash
	PROMPT_COMMAND+=($'glob__trap_string="$(trap -p DEBUG)"\ntrap - DEBUG\nglob__install') #keep_for_bash
	preexec() {
		{
			# TODO: report and move to bash-preexec: SIGWINCH causes preexec to run again
			[[ $(fc -l -1) = "$glob__prev_cmd" ]] && return
			glob__prev_cmd=$(fc -l -1)
			local var__escaped_command var__icon var__cmd
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
			glob__timer_cmd=${var__escaped_command/\\\007/<BEL>}
			local var__xcmd var__command var__ignored_title=
			for var__xcmd in "${glob__cmd_ignored[@]}"; do
				[[ $var__xcmd = "${glob__timer_cmd%% *}" ]] && var__ignored_title=1
			done
			var__icon=${glob__icons[const_command]}
			glob__title="$var__icon  $glob__timer_cmd"
			[[ $glob__has_suffix ]] && glob__suffix
			var__cmd=${glob__timer_cmd%% *}
			var__cmd=${var__cmd%%;*}
			glob__measure=1
			glob__start_seconds=$SECONDS
			glob__title+=" in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M)"
			local var__monorail_title_formatted=
			#[[ $var__ignored_title ]] || var__monorail_title_formatted=$'\n\e[A\e]0;'$glob__title$'\a\r\e[K'
			[[ $var__ignored_title ]] || var__monorail_title_formatted=$'\e]0;'$glob__title$'\a'
			[[ $glob__has_suffix ]] && glob__suffix
			# shellcheck disable=SC2059 # keep printf compact
			printf "$var__monorail_title_formatted\e]11;#${glob__colors[const_color_background]}\a\e]10;#${glob__colors[const_color_foreground]}\a\e]12;#${glob__colors[const_color_cursor]}\a\r\e[K" >/dev/tty 2>&-
			# dummy syntax so curly brackets match up for preprocessed brackets below
			{  #discard_for_all
				: #discard_for_all
				# zsh cannot have closed fd's here
			} &>/dev/null #keep_for_zsh
		} >&- 2>&-     #keep_for_bash
	}
	_monorail_gradient() {
		local i=0
		local j
		while [[ $i -le $COLUMNS ]]; do
			j=$((1 + $# * i / $((COLUMNS + 1))))
			var__monorail_line+=$'\e'"[38;2;${!j}m"$'\xe2\x96\x81'
			i=$((i + 1))
		done
		i=0
		if [[ $1 ]]; then
			var__monorail_text_formatted=
			[[ ${var__prompt_text_lut[*]} ]] || var__prompt_text_lut[0]="255;255;255"
			while [[ $i -lt ${var__monorail_text_array_len} ]]; do
				j=$((1 + $# * i / $((COLUMNS + 1))))
				var__monorail_text_formatted+="@PROMPT_PREHIDE@"$'\e['"$((var__monorail_text_array_len + 1))C"$'\e'["$((var__monorail_text_array_len + 1))"D$'\e'"[48;2;${!j}m"$'\e'"[38;2;${var__prompt_text_lut[$((${#var__prompt_text_lut[*]} * i / $((COLUMNS + 1))))]}m@PROMPT_POSTHIDE@${var__monorail_text_array[i]}"
				i=$((i + 1))
			done
			# The invisible vertical bar is added to make the prompt more readable when copied to a chat or text doc.
			# This is not normally visible if your terminal supports "invisible SGR8" `^[8m`
			# Notably PuTTY, Kitty, rxvt-unicode, zutty, and cool-retro-term does not support these.
			# In this case the horizontal bar is colored with background color.
			var__monorail_text_formatted+="@PROMPT_PREHIDE@"$'\e'"[0;8m"$'\e'"[38;2;$((0x${glob__colors[const_color_background]:0:2}));$((0x${glob__colors[const_color_background]:2:2}));$((0x${glob__colors[const_color_background]:4:2}))m@PROMPT_POSTHIDE@|"
		else
			var__monorail_text_formatted=@PROMPT_PREHIDE@$'\e'"[0;7m@PROMPT_POSTHIDE@"
			while [[ $i -lt ${var__monorail_text_array_len} ]]; do
				var__monorail_text_formatted+=${var__monorail_text_array[i]}
				i=$((i + 1))
			done
			var__monorail_text_formatted+=@PROMPT_PREHIDE@$'\e[0;8m'"@PROMPT_POSTHIDE@|"
		fi
		j=$(($# * $((var__monorail_text_array_len + 1)) / $((COLUMNS + 1))))
		var__rgb_cur_color=${!j}
		var__rgb_cur_r=${var__rgb_cur_color%%;*}
		var__rgb_cur_gb=${var__rgb_cur_color#*;}
		var__rgb_cur_g=${var__rgb_cur_gb%%;*}
		var__rgb_cur_b=${var__rgb_cur_gb##*;}
		var__hex_cursor_color=$(printf "%.2x%.2x%.2x" "$var__rgb_cur_r" "$var__rgb_cur_g" "$var__rgb_cur_b" 2>&-)
		[[ $1 ]] || var__hex_cursor_color=${glob__colors[const_color_cursor]}
	}
	_monorail_textgradient() {
		var__prompt_text_lut=("$@")
	}
	_monorail_colors() {
		glob__colors=("$@")
	}
	monorail_title() {
		unset glob__title_override
		[[ $1 ]] && glob__title_override="$*"
	}
	monorail_icon() {
		unset glob__icon_override
		[[ $1 ]] && glob__icon_override="$*"
	}
	_TITLE_RAW() {
		[[ $glob__nostyling ]] && return 0
		printf "\e]0;%s\a\r\e[K" "$*" >/dev/tty 2>&-
	}
	[[ $MONORAIL_CONFIG ]] || MONORAIL_CONFIG=$HOME/.config/monorail
	monorail_name() {
		unset NAME
		[[ $1 ]] && NAME="$*"
	}
	precmd() {
		if [[ $glob__launched ]]; then
			# bash line editor (ble.sh) do not like others messing with the tty
			# enable stty echo in case some command has disabled it up
			[[ $BLE_ATTACHED ]] || LC_MESSAGES=C LC_ALL=C stty echo 2>&-
			{
				local var__seconds_m var__duration_h var__duration_m var__duration_s var__duration var__diff
				var__diff=$((SECONDS - glob__start_seconds))
				if [[ $glob__measure ]] && [[ $var__diff -gt ${MONORAIL_TIMEOUT-30} ]]; then
					var__seconds_m=$((var__diff % 3600))
					var__duration_h=$((var__diff / 3600))
					var__duration_m=$((var__seconds_m / 60))
					var__duration_s=$((var__seconds_m % 60))
					printf "\n\aCommand took "
					var__duration=
					[[ $var__duration_h -gt 0 ]] && var__duration="${var__duration_h}h "
					[[ $var__duration_m -gt 0 ]] && var__duration+="${var__duration_m}m "
					var__duration+="${var__duration_s}s, finished at "$(LC_MESSAGES=C LC_ALL=C date +%H:%M).
					echo "$var__duration"
					(exec notify-send -a "Completed $glob__timer_cmd" -i terminal "$glob__timer_cmd" "Command took $var__duration" &)
					(exec mplayer -quiet /usr/share/sounds/gnome/default/alerts/glass.ogg >&- 2>&- &)
					glob__longrunning=1
				fi
				unset glob__measure
			} 2>&-
			local var__cmd_status
			var__cmd_status=$?
			printf "%$((COLUMNS - 1))s\\r"
			HISTCONTROL=
			glob__histcmd_prev=$(fc -l -1)
			glob__histcmd_prev=${glob__histcmd_prev%%$'[\t ]'*}
			if [[ -z $glob__histcmd_penultimate ]]; then
				glob__cr_first=1
				glob__cr_level=0
				unset glob__ctrlc
			elif [[ $glob__histcmd_penultimate = "$glob__histcmd_prev" ]]; then
				if [[ -z $glob__cr_first ]] && [[ $var__cmd_status = 0 ]] && [[ -z $glob__ctrlc ]]; then
					case "$glob__cr_level" in
					0)
						ls
						glob__cr_level=3
						if \git status >&- 2>&-; then
							glob__cr_level=1
						else
							printf "\e[J\n\n"
						fi
						;;
					2)
						glob__cr_level=3
						\git -c color.status=always status | \head -n$((LINES - 2)) | \head -n$((LINES - 4))
						echo -e "        ...\n\n"
						;;
					*) glob__magic_shellball ;;
					esac
					glob__cr_level=$((glob__cr_level + 1))
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
			[[ $BASH_VERSION ]] && history -a >&- 2>&- #keep_for_bash

		else
			alias for='glob__nostyling=1;for'
			alias while='glob__nostyling=1;while'
			alias until='glob__nostyling=1;until'
			glob__launched=1
		fi
		if [[ $glob__longrunning ]]; then
			glob__title="${glob__icons[const_completed]} Completed $glob__timer_cmd"
			[[ $glob__has_suffix ]] && glob__suffix
			unset glob__longrunning
		else
			case $PWD in
			/run/user/*/gvfs/*) glob__git_ps1= ;;
			*)
				local var__prompt_pwd var__monorail_repo
				var__prompt_pwd=$PWD
				var__monorail_repo=
				while [[ "$var__prompt_pwd" ]]; do
					if [[ -d "$var__prompt_pwd/.repo" ]]; then
						var__monorail_repo=1
						break
					fi
					var__prompt_pwd="${var__prompt_pwd%/*}"
				done
				if [[ -z $glob__git_loaded ]]; then
					local var__dir
					var__dir=$PWD
					while [[ $var__dir ]]; do
						if [[ -e "$var__dir/.git" ]] && [[ -e /usr/lib/git-core/git-sh-prompt ]]; then
							. /usr/lib/git-core/git-sh-prompt
							glob__git_loaded=1
						fi
						var__dir=${var__dir%/*}
					done
				fi
				# shellcheck disable=SC2329 # _TITLE function is invoked by __git_ps1 which is assigned later
				glob__git_ps1=$(
					_TITLE() {
						shift
						"$@"
					}
					TERM=dumb GIT_CONFIG_GLOBAL="" LC_MESSAGES=C LC_ALL=C __git_ps1 ""
				)
				;;
			esac
			local var__icon var__title_base
			var__title_base=${PWD##*/}
			if [[ $var__monorail_repo ]]; then
				var__icon=${glob__icons[const_repo]}
			elif [[ $glob__git_ps1 ]]; then
				var__icon=${glob__icons[const_git]}
			else
				case $PWD in
				"$HOME/Trash"* | "$HOME/.local/share/Trash/files"*) var__icon=${glob__icons[const_trash]} ;;
				/)
					var__icon=${glob__icons[const_computer]}
					var__title_base=/
					;;
				/media/*) var__icon=${glob__icons[const_media]} ;;
				/proc/* | /sys/* | /dev/* | /proc | /sys | /dev) var__icon=${glob__icons[const_system]} ;;
				*/Documents | */Documents/* | */doc | */docs | */doc/* | */docs/* | "$XDG_DOCUMENTS_DIR" | "$XDG_DOCUMENTS_DIR"/*) var__icon=${glob__icons[const_documents]} ;;
				"$XDG_MUSIC_DIR" | "$XDG_MUSIC_DIR"/*) var__icon=${glob__icons[const_music]} ;;
				"$XDG_PICTURES_DIR" | "$XDG_PICTURES_DIR"/*) var__icon=${glob__icons[const_pictures]} ;;
				"$XDG_VIDEOS_DIR" | "$XDG_VIDEOS_DIR"/*) var__icon=${glob__icons[const_videos]} ;;
				*/Downloads | */Downloads/* | "$XDG_DOWNLOAD_DIR" | "$XDG_DOWNLOAD_DIR"/*) var__icon=${glob__icons[const_downloads]} ;;
				*) var__icon=${glob__icons[const_folder]} ;;
				esac
				case $PWD in
				"$HOME")
					var__title_base=$_mr_hostname
					if [[ $CRAFT_STATE_DIR ]]; then
						var__icon=${glob__icons[const_snapcraft]}
					elif [[ $SSH_CLIENT ]]; then
						var__icon=${glob__icons[const_ssh]}
					elif [[ -e /.dockerenv ]]; then
						var__icon=${glob__icons[const_docker]}
					elif [[ -e /run/containerenv ]]; then
						var__icon=${glob__icons[const_podman]}
					else
						var__icon=${glob__icons[const_home]}
					fi
					;;
				*) ;;
				esac
			fi
			glob__title="${glob__icon_override-${var__icon}}  ${glob__title_override-${var__title_base}}"
			[[ $PWD != "$HOME" ]] && [[ $glob__has_suffix ]] && glob__suffix
		fi
		local var__pwd_basename="${PWD##*/}"
		[[ $var__pwd_basename ]] || var__pwd_basename=/
		case $PWD in
		"$HOME") var__pwd_basename="~" ;;
		*) var__pwd_basename="${NAME-$var__pwd_basename}" ;;
		esac
		local var__monorail_text=" $var__pwd_basename$glob__git_ps1 "
		var__monorail_text=${var__monorail_text//\.\.\./$'\xe2\x80\xa6'}
		# frequently, the last of the text is the most relevant, cut beginning if too long path
		[[ ${#var__monorail_text} -gt $((COLUMNS / 3)) ]] && var__monorail_text=$' \xe2\x80\xa6'"${var__monorail_text:$((${#var__monorail_text} - $((COLUMNS / 3))))}"
		local var__monorail_text_array=()
		for ((I = 0; I < ${#var__monorail_text}; I++)); do #keep_for_zsh
			#keep_for_zsh
			var__monorail_text_array[I]=${var__monorail_text[I]} #keep_for_zsh
		done                                                  #keep_for_zsh
		for ((I = 0; I < ${#var__monorail_text}; I++)); do    #keep_for_bash
			#keep_for_bash
			var__monorail_text_array[I]=${var__monorail_text:I:1} #keep_for_bash
		done                                                   #keep_for_bash
		var__monorail_text_array_len=${#var__monorail_text_array[@]}
		local var__rgb_cur_color var__rgb_cur_r var__rgb_cur_gb var__rgb_cur_g var__rgb_cur_b
		if [[ $glob__cache != "$COLUMNS$var__monorail_text" ]]; then
			unset glob__cache glob__measure
			if [[ ! -f "$MONORAIL_CONFIG/colors-$_mr_hostname".conf ]]; then
				mkdir -p "$MONORAIL_CONFIG"
				if [[ -f "$MONORAIL_DIR/gradients/Default.conf" ]]; then
					if [[ $(gsettings get org.gnome.desktop.interface color-scheme) = prefer-dark ]]; then
						LC_ALL=C LC_MESSAGES=C \cat "$MONORAIL_DIR"/colors/DefaultDark.conf "$MONORAIL_DIR"/gradients/Default.conf >"$MONORAIL_CONFIG/colors-$_mr_hostname".conf 2>&-
					else
						LC_ALL=C LC_MESSAGES=C \cat "$MONORAIL_DIR"/colors/Default.conf "$MONORAIL_DIR"/gradients/Default.conf >"$MONORAIL_CONFIG/colors-$_mr_hostname".conf 2>&-
					fi
				else
					# shellcheck disable=SC2059 # keep printf compact
					printf "\
monorail: warning: Monorail was not found in $MONORAIL_DIR.
                   Do this to make colors and gradients work:
                     1. Move monorail directory to $MONORAIL_DIR
                     2. rm -rf $MONORAIL_CONFIG
                     3. Restart terminal." >/dev/tty
				fi
			fi
			glob__colors=()
			local I=0
			local var__monorail_line=
			# here _monorail_gradient _monorail_textgradient _monorail_colors are called
			# shellcheck source=scripts/dummy.conf
			. "$MONORAIL_CONFIG/colors-$_mr_hostname".conf

			glob__cache="$COLUMNS$var__monorail_text"
			# shellcheck disable=SC2025,SC1078,SC1079 # no need to enclose in \[ \] as cursor position is calculated from after newline, quoting is supposed to span multiple lines
			PS1=$'\e[?7l\e]0;''$glob__title''\a\e[0m\r'"$var__monorail_line
$var__monorail_text_formatted@PROMPT_PREHIDE@"$'\r\e['$((${#var__monorail_text} + 1))C$'\e[?7h\e[?25h\e]12;#$var__hex_cursor_color\a\e[0m'"@PROMPT_POSTHIDE@"
		fi
		unset glob__nostyling
		# shellcheck disable=SC2059 # keep printf compact
		printf "\e[?25l\e[?7l\e[${COLUMNS}C\e]11;#${glob__colors[const_color_background]}\a\e]10;#${glob__colors[const_color_foreground]}\a\e]4;0;#${glob__colors[0]}\a\e]4;1;#${glob__colors[1]}\a\e]4;2;#${glob__colors[2]}\a\e]4;3;#${glob__colors[3]}\a\e]4;4;#${glob__colors[4]}\a\e]4;5;#${glob__colors[5]}\a\e]4;6;#${glob__colors[6]}\a\e]4;7;#${glob__colors[7]}\a\e]4;8;#${glob__colors[8]}\a\e]4;9;#${glob__colors[9]}\a\e]4;10;#${glob__colors[10]}\a\e]4;11;#${glob__colors[11]}\a\e]4;12;#${glob__colors[12]}\a\e]4;13;#${glob__colors[13]}\a\e]4;14;#${glob__colors[14]}\a\e]4;15;#${glob__colors[15]}\a\r"
	}
	_TITLE() {
		local glob__title="$*"
		if [[ $glob__measure ]]; then
			glob__title+=" in ${PWD##*/} at $(LC_MESSAGES=C LC_ALL=C date +%H:%M 2>&-)"
		elif [[ $PWD = "$HOME" ]]; then
			:
		else
			glob__title+=" in ${PWD##*/}"
		fi
		[[ $glob__has_suffix ]] && glob__suffix
		_TITLE_RAW "$glob__title"
	}
	_NO_MEASURE() {
		unset glob__measure
		"$@"
	}
	_ICON() {
		local var__icon="$1"
		shift
		if [[ -z ${FUNCNAME[1]} ]] || [[ ${FUNCNAME[1]} = "_NO_MEASURE" ]]; then
			local FIRST_ARG="$1"
			(
				case "$FIRST_ARG" in
				_*) shift ;;
				esac
				FIRST_ARG="$1"
				FIRST_NON_OPTION="$2"
				while [[ ${FIRST_NON_OPTION:0:1} = '-' ]] || [ "${FIRST_NON_OPTION:0:1}" = '_' ] || [ "$FIRST_NON_OPTION" = '.' ]; do
					if [ "$FIRST_NON_OPTION" = '-u' ]; then
						shift 2
					else
						shift
					fi
					FIRST_NON_OPTION="$2"
				done
				[[ $var__icon ]] && if [[ -z "$FIRST_NON_OPTION" ]]; then
					_TITLE "${glob__icon_override-${var__icon}}  ${FIRST_ARG##*/}"
				else
					_TITLE "${glob__icon_override-${var__icon}}  ${FIRST_NON_OPTION##*/}"
				fi
			) >&- 2>&-
		fi
		"$@"
	}
	trap "unset glob__cache" WINCH
	_LOW_PRIO() {
		if type -P chrt && type -P ionice && type -P ionice; then
			_LOW_PRIO() {
				# As an ordinary user, you cannot raise the priority and mark the importance
				# of a process.
				# However, you can mark which processes are less important than high-prio tasks
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
			_LOW_PRIO() {
				# `nice -n19` is the lowest priority on non-Linux systems
				nice -n19 "$@"
			}
		fi >/dev/null 2>&-
		_LOW_PRIO "$@"
	}
	# shellcheck disable=SC2329
	_monorail_icon() {
		# I'd prefer to use associative arrays here. but for unknown reasons, it does not work as of bash 5.3.9(1)-release
		case "$2" in
		home) glob__icons[const_home]=$1 ;;
		ssh) glob__icons[const_ssh]=$1 ;;
		docker) glob__icons[const_docker]=$1 ;;
		podman) glob__icons[const_podman]=$1 ;;
		git) glob__icons[const_git]=$1 ;;
		repo) glob__icons[const_repo]=$1 ;;
		trash) glob__icons[const_trash]=$1 ;;
		documents) glob__icons[const_documents]=$1 ;;
		media) glob__icons[const_media]=$1 ;;
		music) glob__icons[const_music]=$1 ;;
		videos) glob__icons[const_videos]=$1 ;;
		downloads) glob__icons[const_downloads]=$1 ;;
		settings) glob__icons[const_settings]=$1 ;;
		folder) glob__icons[const_folder]=$1 ;;
		completed) glob__icons[const_completed]=$1 ;;
		command) glob__icons[const_command]=$1 ;;
		computer) glob__icons[const_computer]=$1 ;;
		system) glob__icons[const_system]=$1 ;;
		*) echo "not supported value: $2" ;;
		esac
	}
	# shellcheck disable=SC2329
	_monorail_cmd_interactive() {
		# shellcheck disable=SC2139 # variable is intended to be set when defined
		command -v "$2" && alias "$2=_NO_MEASURE _ICON $1 $2"
	}
	# shellcheck disable=SC2329
	_monorail_cmd_batch() {
		# shellcheck disable=SC2139
		command -v "$2" && alias "$2=_ICON $1 _LOW_PRIO $2"
	}
	glob__cmd_ignored=()
	_monorail_cmd_ignored() {
		glob__cmd_ignored[${#glob__cmd_ignored[@]}]=$1
	}
	[[ -e $MONORAIL_CONFIG/settings-${_mr_hostname}.conf ]] || cat "$MONORAIL_DIR/default_settings.conf" >"$MONORAIL_CONFIG/settings-${_mr_hostname}.conf"
	# shellcheck source=scripts/dummy.conf
	. "$MONORAIL_CONFIG/settings-${_mr_hostname}.conf"
	__git_ps1() { :; }
	glob__magic_shellball() {
		local var__answer var__spaces i
		var__spaces=
		i=0
		case "$RANDOM" in
		*[0-4])
			case "$RANDOM" in
			*0) var__answer="IT IS CERTAIN." ;;
			*1) var__answer="IT IS DECIDEDLY SO." ;;
			*2) var__answer="WITHOUT A DOUBT." ;;
			*3) var__answer="YES – DEFINITELY." ;;
			*4) var__answer="YOU MAY RELY ON IT." ;;
			*5) var__answer="AS I SEE IT, YES." ;;
			*6) var__answer="MOST LIKELY." ;;
			*7) var__answer="OUTLOOK GOOD." ;;
			*8) var__answer="YES." ;;
			*) var__answer="SIGNS POINT TO YES." ;;
			esac
			;;
		*) case "$RANDOM" in
			*0) var__answer="REPLY HAZY, TRY AGAIN." ;;
			*1) var__answer="ASK AGAIN LATER." ;;
			*2) var__answer="BETTER NOT TELL YOU NOW." ;;
			*3) var__answer="CANNOT PREDICT NOW." ;;
			*4) var__answer="CONCENTRATE AND ASK AGAIN." ;;
			*5) var__answer="DON'T COUNT ON IT." ;;
			*6) var__answer="MY REPLY IS NO." ;;
			*7) var__answer="MY SOURCES SAY NO." ;;
			*8) var__answer="OUTLOOK NOT SO GOOD." ;;
			*) var__answer="VERY DOUBTFUL." ;;
			esac ;;
		esac
		while [[ $i -lt $((COLUMNS / 2 - ${#var__answer} / 2)) ]]; do
			var__spaces+=" "
			i=$((i + 1))
		done
		echo -e "\e[?25l\e[3A\r\e[K$var__spaces$var__answer"
	}
	if [[ $TERM = xterm-256color ]]; then
		# zutty (vterm) doesn't handle background color, nor hidden text.
		# thus the horizontal bar  "|" gets visible
		[[ $ZUTTY_VERSION ]] && MONORAIL_COMPAT=1
		# vscode does not support disabling line wrapping
		#
		[[ $TERM_PROGRAM = vscode ]] && MONORAIL_COMPAT=1
	elif [[ $MC_TMPDIR ]]; then
		MONORAIL_COMPAT=1
	else
		case $TERM in
		xterm-color | xterm-16color)
			MONORAIL_COMPAT=1
			;;
		xterm* | alacritty | rio | rxvt-unicode-256color | mlterm | st-256color | foot)
			printf "\e[?25l\e[?7l\e[%sC\e]0; \a\r\e[K" "${COLUMNS}" >/dev/tty 2>&-
			# ghostty adds a ssh function which causes parsing error since monorail adds an ssh alias
			[[ $TERM = xterm-ghostty ]] && unalias ssh 2>/dev/null
			# FreeBSD console lacks UTF-8 and truecolor
			[[ $(tty) =~ "/dev/ttyv"* ]] && MONORAIL_COMPAT=1
			# cool-retro-term does not support invisible SGR8
			[[ $WINDOWID = 0 ]] && MONORAIL_COMPAT=1
			# if not using UTF-8 locale in xterm or not using xterm use compat
			case $XTERM_LOCALE in
			"" | *.UTF-8) : ;;
			*) MONORAIL_COMPAT=1 ;;
			esac
			;;
		*)
			MONORAIL_COMPAT=1
			;;
		esac
	fi
	[[ $MONORAIL_COMPAT ]] && if [[ ! $MONORAIL_DISABLE_COMPAT ]]; then
		unalias git >/dev/null 2>/dev/null
		. "$MONORAIL_DIR/monorail.sh"
	fi
	# shellcheck disable=SC2139
	alias monorail_color="_mr_hostname=$_mr_hostname MONORAIL_CONFIG=$MONORAIL_CONFIG MONORAIL_DIR=$MONORAIL_DIR sh $MONORAIL_DIR/scripts/color.sh"
	# shellcheck disable=SC2139
	alias monorail_gradient="_mr_hostname=$_mr_hostname MONORAIL_CONFIG=$MONORAIL_CONFIG MONORAIL_DIR=$MONORAIL_DIR sh $MONORAIL_DIR/scripts/gradient.sh"
	# shellcheck disable=SC2139
	alias monorail_image="_mr_hostname=$_mr_hostname MONORAIL_CONFIG=$MONORAIL_CONFIG MONORAIL_DIR=$MONORAIL_DIR sh $MONORAIL_DIR/scripts/image.sh"
	# shellcheck disable=SC2139
	alias monorail_textgradient="_mr_hostname=$_mr_hostname MONORAIL_CONFIG=$MONORAIL_CONFIG MONORAIL_DIR=$MONORAIL_DIR sh $MONORAIL_DIR/scripts/gradient.sh --text"
	# shellcheck disable=SC2139
	alias rgb="sh $MONORAIL_DIR/scripts/rgb.sh"
} >&- 2>&-
