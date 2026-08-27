#!/bin/sh
export LC_ALL=C
. scripts/sandbox.inc.sh
rm -f monorail.bash
TEMP_BASH=$(mktemp)
SRC=src-zsh-bash.sh
shfmt -w "$SRC" || exit 42
cat "$SRC" |
	grep -v "#discard_for_all" |
	grep -v "#keep_for_zsh" |
	grep -v "^$" |
	grep -v "^#" |
	sed -e 's/#keep_for_bash//g' \
		-e 's/@PROMPT_PREHIDE@/\\[/g' \
		-e 's/@PROMPT_POSTHIDE@/\\]/g' \
		-e 's/const_home/0/g' \
		-e 's/const_ssh/1/g' \
		-e 's/const_docker/2/g' \
		-e 's/const_podman/3/g' \
		-e 's/const_git/4/g' \
		-e 's/const_repo/5/g' \
		-e 's/const_trash/6/g' \
		-e 's/const_documents/7/g' \
		-e 's/const_media/8/g' \
		-e 's/const_music/9/g' \
		-e 's/const_videos/10/g' \
		-e 's/const_downloads/11/g' \
		-e 's/const_settings/12/g' \
		-e 's/const_folder/13/g' \
		-e 's/const_completed/14/g' \
		-e 's/const_command/15/g' \
		-e 's/const_computer/16/g' \
		-e 's/const_system/17/g' \
		-e 's/const_snapcraft/18/g' \
		-e 's/const_pictures/19/g' \
		-e 's/const_color_foreground/16/g' \
		-e 's/const_color_background/17/g' \
		-e 's/const_color_cursor/21/g' \
		-e 's/glob__title_ovveride/_mr_a/g' \
		-e 's/glob__has_suffix/_mr_b/g' \
		-e 's/glob__suffix/_mr_c/g' \
		-e 's/glob__colors/_mr_e/g' \
		-e 's/glob__icons/_mr_f/g' \
		-e 's/glob__cr_first/_mr_g/g' \
		-e 's/glob__cr_level/_mr_h/g' \
		-e 's/glob__timer_cmd/_mr_i/g' \
		-e 's/glob__histcmd_penultimate/_mr_j/g' \
		-e 's/glob__histcmd_prev/_mr_k/g' \
		-e 's/glob__cmd_ignored/_mr_l/g' \
		-e 's/glob__longrunning/_mr_m/g' \
		-e 's/glob__ctrlc/_mr_n/g' \
		-e 's/glob__cache/_mr_o/g' \
		-e 's/glob__git_ps1/_mr_p/g' \
		-e 's/glob__magic_shellball/_mr_q/g' \
		-e 's/glob__measure/_mr_r/g' \
		-e 's/glob__start_seconds/_mr_s/g' \
		-e 's/glob__prev_cmd/_mr_t/g' \
		-e 's/glob__launched/_mr_u/g' \
		-e 's/glob__git_loaded/_mr_v/g' \
		-e 's/glob__preexec_interactive_mode/_mr_w/g' \
		-e 's/glob__preexec_invoke_exec/_mr_x/g' \
		-e 's/glob__last_ret_value/_mr_y/g' \
		-e 's/glob__inside_precmd/_mr_z/g' \
		-e 's/glob__inside_preexec/_mr_A/g' \
		-e 's/glob__original_debug_trap/_mr_B/g' \
		-e 's/glob__install/_mr_C/g' \
		-e 's/glob__preexec_enabled/_mr_D/g' \
		-e 's/glob__trap_string/_mr_D/g' \
		-e 's/glob__title/_mr_E/g' \
		-e 's/glob__icon_override/_mr_F/g' \
		-e 's/glob__nostyling/_mr_G/g' \
		-e 's/glob__sanitized/_mr_H/g' \
		-e 's/var__this_command/a/g' \
		-e 's/var__monorail_text_formatted/c/g' \
		-e 's/var__monorail_text_array_len/e/g' \
		-e 's/var__monorail_text_array/d/g' \
		-e 's/var__monorail_text/b/g' \
		-e 's/var__existing_prompt_command/f/g' \
		-e 's/var__trimmed_command/g/g' \
		-e 's/var__trimmed_arg/h/g' \
		-e 's/var__histcontrol/k/g' \
		-e 's/var__command/l/g' \
		-e 's/var__diff/m/g' \
		-e 's/var__text_lut/n/g' \
		-e 's/var__prompt_lut/o/g' \
		-e 's/var__monorail_title_formatted/p/g' \
		-e 's/var__monorail_title/q/g' \
		-e 's/var__hex_cursor_color/r/g' \
		-e 's/var__answer/s/g' \
		-e 's/var__prompt_text_lut/t/g' \
		-e 's/var__dir/u/g' \
		-e 's/var__monorail_line/v/g' \
		-e 's/var__rgb_cur_color/w/g' \
		-e 's/var__prompt_pwd/x/g' \
		-e 's/var__monorail_repo/y/g' \
		-e 's/var__pwd_basename/z/g' \
		-e 's/var__spaces/A/g' \
		-e 's/var__icon/B/g' \
		-e 's/var__escaped_command/C/g' \
		-e 's/var__rgb_cur_r/D/g' \
		-e 's/var__rgb_cur_gb/E/g' \
		-e 's/var__rgb_cur_g/F/g' \
		-e 's/var__rgb_cur_b/G/g' \
		-e 's/var__prompt_command_array/H/g' \
		-e 's/var__preexec_function/L/g' \
		-e 's/var__cmd_status/M/g' \
		-e 's/var__cmd/N/g' \
		-e 's/var__prior_trap/O/g' \
		-e 's/var__trap_argv/P/g' \
		-e 's/var__xcmd/Q/g' \
		-e 's/var__ignored_title/R/g' \
		-e 's/var__title_base/S/g' \
		-e 's/var__seconds_m/T/g' \
		-e 's/var__duration_h/U/g' \
		-e 's/var__duration_m/V/g' \
		-e 's/var__duration_s/W/g' \
		-e 's/var__duration/X/g' \
		>"${TEMP_BASH}"
shfmt -mn "${TEMP_BASH}" >monorail.bash || exit 42

rm -f monorail.zsh
TEMP_ZSH=$(mktemp)
cat "$SRC" |
	grep -v "#discard_for_all" |
	grep -v "#keep_for_bash" |
	grep -v "^$" |
	grep -v "^#" |
	sed -e 's/#keep_for_zsh//g' \
		-e 's/@PROMPT_PREHIDE@/%{/g' \
		-e 's/@PROMPT_POSTHIDE@/%}/g' \
		-e 's/const_home/0/g' \
		-e 's/const_ssh/1/g' \
		-e 's/const_docker/2/g' \
		-e 's/const_podman/3/g' \
		-e 's/const_git/4/g' \
		-e 's/const_repo/5/g' \
		-e 's/const_trash/6/g' \
		-e 's/const_documents/7/g' \
		-e 's/const_media/8/g' \
		-e 's/const_music/9/g' \
		-e 's/const_videos/10/g' \
		-e 's/const_downloads/11/g' \
		-e 's/const_settings/12/g' \
		-e 's/const_folder/13/g' \
		-e 's/const_completed/14/g' \
		-e 's/const_command/15/g' \
		-e 's/const_computer/16/g' \
		-e 's/const_system/17/g' \
		-e 's/const_color_foreground/16/g' \
		-e 's/const_color_background/17/g' \
		-e 's/const_color_cursor/21/g' \
		-e 's/var__this_command/a/g' \
		-e 's/var__monorail_text_formatted/c/g' \
		-e 's/var__monorail_text_array_len/e/g' \
		-e 's/var__monorail_text_array/d/g' \
		-e 's/var__monorail_text/b/g' \
		-e 's/var__existing_prompt_command/f/g' \
		-e 's/var__trimmed_command/g/g' \
		-e 's/var__trimmed_arg/h/g' \
		-e 's/var__sanitized/k/g' \
		-e 's/var__histcontrol/k/g' \
		-e 's/var__command/l/g' \
		-e 's/var__diff/m/g' \
		-e 's/var__text_lut/n/g' \
		-e 's/var__prompt_lut/o/g' \
		-e 's/var__monorail_title_formatted/p/g' \
		-e 's/var__monorail_title/q/g' \
		-e 's/var__hex_cursor_color/r/g' \
		-e 's/var__answer/s/g' \
		-e 's/var__prompt_text_lut/t/g' \
		-e 's/var__dir/u/g' \
		-e 's/var__monorail_line/v/g' \
		-e 's/var__rgb_cur_color/w/g' \
		-e 's/var__prompt_pwd/x/g' \
		-e 's/var__monorail_repo/y/g' \
		-e 's/var__pwd_basename/z/g' \
		-e 's/var__spaces/A/g' \
		-e 's/var__icon/B/g' \
		-e 's/var__escaped_command/C/g' \
		-e 's/var__rgb_cur_r/D/g' \
		-e 's/var__rgb_cur_gb/E/g' \
		-e 's/var__rgb_cur_g/F/g' \
		-e 's/var__rgb_cur_b/G/g' \
		-e 's/var__prompt_command_array/H/g' \
		-e 's/var__preexec_function/L/g' \
		-e 's/var__cmd_status/M/g' \
		-e 's/var__cmd/N/g' \
		-e 's/var__prior_trap/O/g' \
		-e 's/var__trap_argv/P/g' \
		-e 's/var__xcmd/Q/g' \
		-e 's/var__ignored_title/R/g' \
		-e 's/var__title_base/S/g' \
		>"${TEMP_ZSH}"
shfmt -mn "${TEMP_ZSH}" >monorail.zsh || exit 42

# do not format monorail.bash
_SANDBOX shellcheck -x "$SRC"
_SANDBOX shellcheck -x monorail.sh
_SANDBOX_RWCWD shfmt -w monorail.sh
for file in scripts/*.sh; do
	_SANDBOX_RWCWD shfmt -w "$file"
	_SANDBOX shellcheck -x "$file"
done
_SANDBOX shellcheck -x scripts/gradient.sh
_SANDBOX_RWCWD fish_indent -w monorail.fish
