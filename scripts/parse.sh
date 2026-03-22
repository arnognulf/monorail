IFS="
"
for license in $(cat licenses.csv | sed 's/.itermcolors//g'); do
	mkdir -p new
	FILE=$(echo $license | cut -d, -f1 | sed -e 's/ /_/g' -e 's/(//g' -e 's/)//g')
	LICENSE=$(echo $license | cut -d, -f2)
	if [[ $LICENSE = "" ]] || [[ $LICENSE = "Unknown"* ]] || [[ $LICENSE = Nonfree ]]; then
		rm -f "colors/$FILE".conf
	else
		echo $LICENSE
		echo "# License: $LICENSE" >new/${FILE}.conf
		OTHER=$(echo $license | cut -d, -f3-1024 | sed 's/,//g' | sed 's/"//g')
		echo "# $OTHER" >>new/${FILE}.conf
		cat colors/${FILE}.conf >>new/${FILE}.conf
	fi
done
