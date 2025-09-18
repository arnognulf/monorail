#!/bin/bash
set -x
if which jq &>/dev/null && which identify &>/dev/null && which convert &>/dev/null && which bc &>/dev/null && which fzf &>/dev/null; then
	:
else
	"error: please install jq, bc, fzf, imagemagick"
	exit 42
fi

if [[ $ZSH_NAME ]]; then
	setopt KSH_ARRAYS
	setopt prompt_subst
fi
_MONORAIL_SHORT_HOSTNAME=$(hostname | cut -d. -f1 | awk '{print tolower($0)}')

_MONORAIL_INVALIDATE_CACHE() { :; }
export _MONORAIL_CONFIG=$HOME/.config/monorail
FIELDS=$(grep -c \"name\": uiGradients/gradients.json)
I=0
while [[ $I -lt $FIELDS ]]; do
	J=0
	unset "COLORS[*]"
	unset COLORS
	NAME=$(<uiGradients/gradients.json jq ".[$I]" | jq '.name' | sed -e 's/"//g' -e 's/ /_/g' -e "s/'//g" -e 's/&/and/g')
	COUNT=$(<uiGradients/gradients.json jq ".[$I]" | jq '.colors' | grep -c "#")
	for COLOR in $(<uiGradients/gradients.json jq ".[$I]" | jq '.colors' | grep "#"); do
		COLORS[J]=$(echo "${COLOR}" | awk '{print tolower($0)}' | sed -e 's/\"//g' -e 's/\#//g' -e 's/\,//g')
		J=$((J + 1))
	done
	COLOR_STRING=""
	J=0
	if [[ $COUNT = 1 ]]; then
		COUNT=2
	fi
	for COLOR in "${COLORS[@]}"; do
		COLOR_STRING="$COLOR_STRING $(($((100 * J)) / $((COUNT - 1)))) ${COLOR}"
		J=$((J + 1))
	done
	# shellcheck disable=SC2086 # intentional string splitting below
	bash scripts/gradient.sh ${COLOR_STRING}
	. "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
	{
		echo "#!/bin/ksh"
		J=0
		while [ $J -lt "${#_PROMPT_LUT[*]}" ]; do
			echo "_PROMPT_LUT[$J]=\"${_PROMPT_LUT[$J]}\""
			J=$((J + 1))
		done
		J=0
		while [ $J -lt "${#_PROMPT_TEXT_LUT[*]}" ]; do
			echo "_PROMPT_TEXT_LUT[$J]=\"${_PROMPT_TEXT_LUT[$J]}\""
			J=$((J + 1))
		done
	} >gradients/"${NAME}.sh"
	echo "Wrote gradient to: gradients/$NAME".sh
	I=$((I + 1))
done
