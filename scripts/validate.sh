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
		-e 's/$const_home/0/g' \
		-e 's/$const_ssh/1/g' \
		-e 's/$const_docker/2/g' \
		-e 's/$const_podman/3/g' \
		-e 's/$const_git/4/g' \
		-e 's/$const_repo/5/g' \
		-e 's/$const_trash/6/g' \
		-e 's/$const_documents/7/g' \
		-e 's/$const_media/8/g' \
		-e 's/$const_music/9/g' \
		-e 's/$const_videos/10/g' \
		-e 's/$const_downloads/11/g' \
		-e 's/$const_settings/12/g' \
		-e 's/$const_folder/13/g' \
		-e 's/$const_completed/14/g' \
		-e 's/$const_command/15/g' \
		-e 's/$const_computer/16/g' \
		-e 's/$const_system/17/g' \
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
		-e 's/var__colors/m/g' \
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
		-e 's/$const_home/0/g' \
		-e 's/$const_ssh/1/g' \
		-e 's/$const_docker/2/g' \
		-e 's/$const_podman/3/g' \
		-e 's/$const_git/4/g' \
		-e 's/$const_repo/5/g' \
		-e 's/$const_trash/6/g' \
		-e 's/$const_documents/7/g' \
		-e 's/$const_media/8/g' \
		-e 's/$const_music/9/g' \
		-e 's/$const_videos/10/g' \
		-e 's/$const_downloads/11/g' \
		-e 's/$const_settings/12/g' \
		-e 's/$const_folder/13/g' \
		-e 's/$const_completed/14/g' \
		-e 's/$const_command/15/g' \
		-e 's/$const_computer/16/g' \
		-e 's/$const_system/17/g' \
		-e 's/var__this_command/a/g' \
		-e 's/var__monorail_text/b/g' \
		-e 's/var__monorail_text_formatted/c/g' \
		-e 's/var__monorail_text_array/d/g' \
		-e 's/var__monorail_text_array_len/e/g' \
		-e 's/var__existing_prompt_command/f/g' \
		-e 's/var__trimmed_command/g/g' \
		-e 's/var__monorail_line/h/g' \
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
