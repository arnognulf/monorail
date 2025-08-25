#!/bin/bash
for arg in "${@}"; do
	case "$arg" in
	--help | -h)
		echo "Usage:
monorail_save <Theme name>
"
		exit 1
		;;
	esac
done

if [[ -z "$1" ]]; then
	echo "Usage:
monorail_save <Theme name>
"
	exit 1
fi

# sanitize file names
NAME=${*// /_}
NAME=${NAME//./_}
NAME=${NAME//\//_}
NAME=${NAME// /_}
NAME=${NAME//\"/}
NAME=${NAME//\'/}
_MONORAIL_SHORT_HOSTNAME=${HOSTNAME%%.*}
_MONORAIL_SHORT_HOSTNAME=${_MONORAIL_SHORT_HOSTNAME,,}

cp "$_MONORAIL_CONFIG/colors-${_MONORAIL_SHORT_HOSTNAME}.sh" "${_MONORAIL_DIR}/colors/$NAME.sh"
