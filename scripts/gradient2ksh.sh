#!/bin/bash
# shellcheck disable=SC1090 # source will be available
. "$1"
{
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
} >"$1"
