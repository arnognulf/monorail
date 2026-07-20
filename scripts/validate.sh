#!/bin/sh
. scripts/sandbox.inc.sh
set -x
rm -f monorail.bash
cat monorail.common.in.sh |
	grep -v "^#" |
	sed 's/@PROMPT_PREHIDE@/\\[/g' |
	sed 's/@PROMPT_POSTHIDE@/\\]/g' \
		>monorail.bash

rm -f monorail.zsh
cat monorail.common.in.sh |
	grep -v "^#" |
	sed 's/@PROMPT_PREHIDE@/%{/g' |
	sed 's/@PROMPT_POSTHIDE@/%}/g' \
		>monorail.zsh

# do not format monorail.bash
_SANDBOX shellcheck -x monorail.bash
_SANDBOX shellcheck -x monorail.sh
_SANDBOX_RWCWD shfmt -w monorail.sh
_SANDBOX shellcheck -x monorail.bash
for file in scripts/*.sh; do
	_SANDBOX_RWCWD shfmt -w "$file"
	_SANDBOX shellcheck -x "$file"
done
_SANDBOX shellcheck -x scripts/gradient.sh
_SANDBOX_RWCWD fish_indent -w monorail.fish
