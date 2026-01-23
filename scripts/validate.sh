#!/bin/sh
# do not format monorail.sh
shellcheck -x monorail.sh
shfmt -w monorail.compat.sh
shellcheck -x monorail.compat.sh
for file in scripts/*.sh; do
	shfmt -w "$file"
	shellcheck -x "$file"
done

shellcheck -x scripts/gradient.sh
