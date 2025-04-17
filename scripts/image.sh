#!/bin/bash

_MAIN ()
{
	if [[ -z "$DEST" ]]; then
		DEST="${_MONORAIL_CONFIG}/colors.sh"
	fi
    if [[ -z "$1" ]]; then
    THEME=$(cd "${XDG_PICTURES_DIR}" && fzf --preview "${_MONORAIL_DIR}/scripts/preview.sh ${OVERRIDE_FGCOLOR} ${OVERRIDE_BGCOLOR} {}")
    else
    THEME="$1"
    fi
    case "${THEME}" in
    *.jpg|*.jpeg|*.png|*.svg|*.webp)
WIDTH=$(identify "$3" | awk '{ print $3 }'|cut -dx -f1)
for RGB in $(convert -crop ${WIDTH}x1+0+$((${WIDTH}/2)) +repage -scale 200x "${3}" RGB:- | xxd -ps -c3)
do
    _PROMPT_LUT[$I]="$((0x${RGB:0:2}));$((0x${RGB:2:2}));$((0x${RGB:4:2}))"
    I=$((I + 1))
done

		rm "${_MONORAIL_CONFIG}/colors.sh"
		{

			[[ $OVERRIDE_BGCOLOR ]] && printf "\n_PROMPT_FGCOLOR=${OVERRIDE_FGCOLOR}\n"
			[[ $OVERRIDE_FGCOLOR ]] && printf "\n_PROMPT_BGCOLOR=${OVERRIDE_BGCOLOR}\n"
			cat "${_MONORAIL_DIR}/colors/${THEME}"
		} >"${_MONORAIL_CONFIG}/colors.sh"
        ""
    ;;
    "")
        # TODO HELP
        :
    esac

	{
		declare -p _PROMPT_LUT | cut -d" " -f3-1024
		declare -p _PROMPT_TEXT_LUT | cut -d" " -f3-1024 | grep -v '()'
		if [[ ! $RESET_COLORS ]]; then
			declare -p _PROMPT_FGCOLOR | cut -d" " -f3-1024
			declare -p _PROMPT_BGCOLOR | cut -d" " -f3-1024
		fi
	} >"${DEST}" 2>/dev/null
	killall -s WINCH bash zsh &>/dev/null    
}
_MAIN "$@"

