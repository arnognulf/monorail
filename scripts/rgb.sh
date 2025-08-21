#!/bin/bash
# Usage:
# rgb 253,33,42
case "$1" in 
	--help|-h)
echo "
CSS like rgb to hex helper
Usage:
rgb 253,33,42
"
;;
*)
            IFS=", "
            for i in $1$2$3$4$5
            do
                printf "%.2x" "$i"
            done
esac

