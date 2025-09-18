#!/bin/bash
# Usage:
# rgb 253,33,42
if [[ $ZSH_NAME ]]; then
	setopt KSH_ARRAYS
	setopt prompt_subst
fi

case "$1" in
--help | -h)
	echo "
CSS like rgb to hex helper
Usage:
rgb 253,33,42
"
	;;
*)
	for i in $(echo "$*" | sed 's/,/ /g'); do
		printf "%.2x" "$i"
	done
	;;
esac
