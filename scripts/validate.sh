#!/bin/sh
. scripts/sandbox.inc.sh

# do not format monorail.sh
_SANDBOX shellcheck -x monorail.sh
_SANDBOX_RWCWD shfmt -w monorail.compat.sh
_SANDBOX shellcheck -x monorail.compat.sh
for file in scripts/*.sh; do
	_SANDBOX_RWCWD shfmt -w "$file"
	_SANDBOX shellcheck -x "$file"
done
_SANDBOX shellcheck -x scripts/gradient.sh
