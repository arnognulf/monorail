#!/bin/sh
# do not format monorail.sh
shellcheck -x monorail.sh
shfmt -w -ln=mksh monorail.compat.sh
shellcheck -x monorail.compat.sh
for file in scripts/*.sh
do
shfmt -w -ln=mksh $file
done
