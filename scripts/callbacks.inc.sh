#!/bin/sh
RESET_CALLBACKS() {
	# shellcheck disable=SC2329 # callback function
	_monorail_gradient() { :; }
	# shellcheck disable=SC2329 # callback function
	_monorail_textgradient() { :; }
	# shellcheck disable=SC2329 # callback function
	_monorail_colors() { :; }
}
RESET_CALLBACKS
ADD_CURRENT_COLORS() {
	# shellcheck disable=SC2329 # callback function
	_monorail_gradient() { :; }
	# shellcheck disable=SC2329 # callback function
	_monorail_textgradient() { :; }
	# shellcheck disable=SC2329 # callback function
	_monorail_colors() {
		printf "_monorail_colors"
		for COLOR in "$@"; do
			echo " \\"
			printf "%s" "$COLOR"
		done
		echo ""
		echo ""
		_monorail_colors() { :; }
	}
	# shellcheck disable=SC1091 # file will be created
	. "${TEMPDIR}/current.conf" >>"${DEST}"
}
ADD_CURRENT_PROMPT_LUT() {
	# shellcheck disable=SC2329 # callback function
	_monorail_textgradient() { :; }
	# shellcheck disable=SC2329 # callback function
	_monorail_colors() { :; }

	# shellcheck disable=SC2329 # callback function
	_monorail_gradient() {
		printf "_monorail_gradient"
		for PROMPT_LUT in "$@"; do
			echo " \\"
			printf "\"%s\"" "$PROMPT_LUT"
		done
		echo ""
		echo ""
		_monorail_gradient() { :; }
	}

	# shellcheck disable=SC1091 # file will be created
	. "${TEMPDIR}/current.conf" >>"${DEST}"
}
ADD_CURRENT_PROMPT_TEXT_LUT() {
	# shellcheck disable=SC2329 # callback function
	_monorail_gradient() { :; }
	# shellcheck disable=SC2329 # callback function
	_monorail_colors() { :; }

	# shellcheck disable=SC2329 # callback function
	_monorail_textgradient() {
		printf "_monorail_textgradient"
		for PROMPT_TEXT_LUT in "$@"; do
			echo " \\"
			printf "\"%s\"" "$PROMPT_TEXT_LUT"
		done
		echo ""
		echo ""
		_monorail_textgradient() { :; }
	}
	# shellcheck disable=SC1091 # file will be created
	. "${TEMPDIR}/current.conf" >>"${DEST}"
}
ADD_WHITE_PROMPT_TEXT_LUT() {
	{
		echo "_monorail_textgradient \\"
		echo "\"255;255;255\""
		echo ""
		echo ""
	} >>"${DEST}"
}
