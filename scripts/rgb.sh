#!/bin/bash
# Usage:
# rgb 253,33,42
if [[ $ZSH_NAME ]];then
setopt KSH_ARRAYS
setopt prompt_subst
_MONORAIL_SHORT_HOSTNAME=$_MONORAIL_SHORT_HOSTNAME:l
else
_MONORAIL_SHORT_HOSTNAME=${_MONORAIL_SHORT_HOSTNAME,,}
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
	IFS=", "
	for i in $1$2$3$4$5; do
		printf "%.2x" "$i"
	done
	;;
esac
