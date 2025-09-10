#!/bin/bash
#
# The iTerm2 Color Schemes project provides color schemes in various formats
# https://github.com/mbadolato/iTerm2-Color-Schemes
#
# For this project, we can easliy extract hex colors to arrays from the iterm-dynamic-colors files
#
# Parse iTerm "not recommended" control sequencies
# from: https://iterm2.com/documentation-escape-codes.html
#
# OSC P [n] [rr] [gg] [bb] ST
# Replace [n] with:
#
# array
# index   n              attribute
# --------------------------------------------
# 0-15   `0`-`f` (hex) = ansi color
# 16     `g`           = foreground
# 17     `h`           = background
# 18     `i`           = bold color
# 19     `j`           = selection color
# 20     `k`           = selected text color
# 21     `l`           = cursor
# 22     `m`           = cursor text (not present in any iTerm2-Color-Schemes)
#
# [rr], [gg], [bb] are 2-digit hex value (for example, "ff"). Example in bash that changes the foreground color blue:
#
# echo -e "\033]Pg4040ff\033\\"
#
if [[ $ZSH_NAME ]]; then
	setopt KSH_ARRAYS
	setopt prompt_subst
fi
_MONORAIL_SHORT_HOSTNAME=$(hostname | cut -d. -f1 | awk '{print tolower($0)}')
if which identify &>/dev/null && which convert &>/dev/null && which bc &>/dev/null && which fzf &>/dev/null; then
	:
else
	"error: please install bc, fzf, imagemagick"
	exit 42
fi

_MONORAIL_CONFIG=$HOME/.config/monorail
mkdir -p colors
for file in "iTerm2-Color-Schemes/iterm-dynamic-colors/"*; do
	. "${_MONORAIL_CONFIG}/colors-${_MONORAIL_SHORT_HOSTNAME}.sh"
	eval $(
		printf "_COLORS=( "
		for color in $(cat "${file}" | sort | grep printf | cut -c16-21); do printf "$color "; done
		printf ")"
	)
	THEME=${file##*/}
	THEME=${THEME// /_}
	rm -f "colors/${THEME}"
	{
		echo "#!/bin/bash"
		for ((I = 0; I < ${#_COLORS[*]}; I++)); do
			echo "_COLORS[$I]=\"${_COLORS[$I]}\""
		done
	} >"colors/${THEME}"
done
