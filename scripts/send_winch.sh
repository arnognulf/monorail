#!/bin/sh
case $(uname -s) in
SunOS) SIGWINCH=20 ;;
*) SIGWINCH=28 ;;
esac
for process_name in bash zsh ksh sh ash dash; do
	pkill -"$SIGWINCH" "$process_name" >/dev/null 2>/dev/null
done
