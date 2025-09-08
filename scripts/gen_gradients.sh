#!/bin/bash
#cat uiGradients/gradients.json |jq ".[4]"|jq '.colors'
if [[ $ZSH_NAME ]];then
setopt KSH_ARRAYS
setopt prompt_subst
_MONORAIL_SHORT_HOSTNAME=$_MONORAIL_SHORT_HOSTNAME:l
else
_MONORAIL_SHORT_HOSTNAME=${_MONORAIL_SHORT_HOSTNAME,,}
fi
if type -P identify &>/dev/null && type -P convert &>/dev/null && type -P bc &>/dev/null &&type -P fzf &>/dev/null
then
:
else
"error: please install bc, fzf, imagemagick"
exit 42
fi



_MONORAIL_INVALIDATE_CACHE() { :; }
_MONORAIL_CONFIG=$HOME/.config/monorail
. gradient/gradient.sh
FIELDS=$(grep \"name\": uiGradients/gradients.json | wc -l)

I=0
while [[ $I -lt $FIELDS ]]; do
	J=0
	unset COLORS[*]
	NAME=$(<uiGradients/gradients.json jq ".[$I]" | jq '.name' | sed -e 's/"//g' -e 's/ /_/g' -e "s/\'//g")
	COUNT=$(<uiGradients/gradients.json jq ".[$I]" | jq '.colors' | grep "#" | wc -l)
	for COLOR in $(<uiGradients/gradients.json jq ".[$I]" | jq '.colors' | grep "#"); do
		COLORS[$J]=$(printf "${COLOR,,}" | sed -e 's/\"//g' -e 's/\#//g' -e 's/\,//g')
		J=$((J + 1))
	done
	COLOR_STRING=""
	J=0
	if [[ $COUNT = 1 ]]; then
		COUNT=2
	fi
	for COLOR in ${COLORS[@]}; do
		COLOR_STRING="$COLOR_STRING $(($((100 * J)) / $((COUNT - 1)))) ${COLOR}"
		J=$((J + 1))
	done
	echo "$NAME"
	echo "$COLOR_STRING"
	DEST="gradients/$NAME".sh
	_GRADIENT --reset-colors ${COLOR_STRING}
	I=$((I + 1))
done
