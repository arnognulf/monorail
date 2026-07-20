#!/bin/sh
export LC_ALL=C
. scripts/sandbox.inc.sh
set -x
rm -f monorail.bash
cat monorail.common.in.sh |
	grep -v "#discard_for_all" |
	grep -v "#keep_for_zsh" |
	grep -v "^$" |
	grep -v "^#" |
	sed 's/ #keep_for_bash//g' |
	sed 's/@PROMPT_PREHIDE@/\\[/g' |
	sed 's/@PROMPT_POSTHIDE@/\\]/g' \
		>monorail.bash

rm -f monorail.zsh
cat monorail.common.in.sh |
	grep -v "#discard_for_all" |
	grep -v "#keep_for_bash" |
	grep -v "^$" |
	grep -v "^#" |
	sed 's/ #keep_for_zsh//g' |
	sed 's/@PROMPT_PREHIDE@/%{/g' |
	sed 's/@PROMPT_POSTHIDE@/%}/g' \
		>monorail.zsh

# do not format monorail.bash
_SANDBOX shellcheck -x monorail.common.in.sh
_SANDBOX shellcheck -x monorail.sh
_SANDBOX_RWCWD shfmt -w monorail.sh
for file in scripts/*.sh; do
	_SANDBOX_RWCWD shfmt -w "$file"
	_SANDBOX shellcheck -x "$file"
done
_SANDBOX shellcheck -x scripts/gradient.sh
_SANDBOX_RWCWD fish_indent -w monorail.fish
