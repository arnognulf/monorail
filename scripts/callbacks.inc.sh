#!/bin/sh
RESET_CALLBACKS() {
	# shellcheck disable=SC2329 # callback function
	_PROMPT_LUT() { :; }
	# shellcheck disable=SC2329 # callback function
	_PROMPT_TEXT_LUT() { :; }
	# shellcheck disable=SC2329 # callback function
	_COLORS() { :; }
}
RESET_CALLBACKS
ADD_CURRENT_COLORS() {
	# shellcheck disable=SC2329 # callback function
	_PROMPT_LUT() { :; }
	# shellcheck disable=SC2329 # callback function
	_PROMPT_TEXT_LUT() { :; }
	# shellcheck disable=SC2329 # callback function
	_COLORS() {
		printf "_COLORS"
		for COLOR in "$@"; do
			echo " \\"
			printf "%s" "$COLOR"
		done
		echo ""
		echo ""
		_COLORS() { :; }
	}
	# shellcheck disable=SC1091 # file will be created
	. "${TEMPDIR}/current.sh" >>"${DEST}"
}
ADD_CURRENT_PROMPT_LUT() {
	# shellcheck disable=SC2329 # callback function
	_PROMPT_TEXT_LUT() { :; }
	# shellcheck disable=SC2329 # callback function
	_COLORS() { :; }

	# shellcheck disable=SC2329 # callback function
	_PROMPT_LUT() {
		printf "_PROMPT_LUT"
		for PROMPT_LUT in "$@"; do
			echo " \\"
			printf "\"%s\"" "$PROMPT_LUT"
		done
		echo ""
		echo ""
		_PROMPT_LUT() { :; }
	}

	# shellcheck disable=SC1091 # file will be created
	. "${TEMPDIR}/current.sh" >>"${DEST}"
}
ADD_CURRENT_PROMPT_TEXT_LUT() {
	# shellcheck disable=SC2329 # callback function
	_PROMPT_LUT() { :; }
	# shellcheck disable=SC2329 # callback function
	_COLORS() { :; }

	# shellcheck disable=SC2329 # callback function
	_PROMPT_TEXT_LUT() {
		printf "_PROMPT_TEXT_LUT"
		for PROMPT_TEXT_LUT in "$@"; do
			echo " \\"
			printf "\"%s\"" "$PROMPT_TEXT_LUT"
		done
		echo ""
		echo ""
		_PROMPT_TEXT_LUT() { :; }
	}
	# shellcheck disable=SC1091 # file will be created
	. "${TEMPDIR}/current.sh" >>"${DEST}"
}
ADD_WHITE_PROMPT_TEXT_LUT() {
	{
		echo "_PROMPT_TEXT_LUT \\"
		echo "\"255;255;255\""
		echo ""
		echo ""
	} >>"${DEST}"
}
