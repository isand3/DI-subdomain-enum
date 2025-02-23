#!/bin/bash

echo "enter http header to use, type nothing if none"
read header

# Uses first .json file ls finds

jsonfile=$(ls *.json | head -n 1)

jq 'if type == "array" then empty else error("json file must contain a valid array") end' $jsonfile

echo "you can filter for the max severity bounty the program offers"
echo "only domains that are eligible for your chosen severity will be selected"

# Functionality for interactive selection
# Each option will include domains in its category and above

PS3=" : "
options=("All" "Low" "Medium" "High" "Critical")
select opt in "${options[@]}"; do
	case $opt in
		"All")
			echo "All severity levels chosen"
			break
			;;
		"Low")
			jq -r '[.[] | select(.Severity != "Informational")]' $jsonfile > "$jsonfile"
			break
			;;
		"Medium")
			jq -r '[.[] | select(.Severity != "Informational" and .Severity != "Low")]' $jsonfile > "$jsonfile"
			break
			;;
		"High")
			jq -r '[.[] | select(.Severity == "High" or .Severity == "Critical")]' $jsonfile > "$jsonfile"
			break
			;;
		"Critical")
			jq -r '[.[] | select(.Severity == "Critical")]' $jsonfile > "$jsonfile"
			break
			;;
		*)
			echo "???"
			;;
	esac
done

# Checks if file exists

if [ -f $jsonfile ]; then
	echo "using $jsonfile"
else
	echo "no json file found"
	exit 1
fi

echo -e "\nthis could take a while...."

x=0
y=1

# Run through the number of assets for progress tracking

for assetkey in $(jq -r '.[] | @base64' "$jsonfile"); do

        assetname=$(echo "$assetkey" | base64 -d | jq -r '.Asset')

        if [[ "$assetname" =~ \  ]]; then
                continue
        fi

	((x++))

done

# Enumerate subdomains and write the results to files

for assetkey in $(jq -r '.[] | @base64' "$jsonfile"); do

	assetname=$(echo "$assetkey" | base64 -d | jq -r '.Asset')

	if [[ "$assetname" =~ \  ]]; then
		continue
	fi

	domain="${assetname#*.}"
	dname="${assetname#*.}"
	dnamef="${dname%.*}"

	subfinder -d $domain -recursive -o subs1.txt > /dev/null 2>&1
	assetfinder -subs-only $domain >> subs1.txt
	echo "$domain" >> subs1.txt
	cat subs1.txt | sort -u > subs.txt
	httpx -l subs.txt -o "./subs-$dnamef.txt" -sc -fhr -pa -H "$header" > /dev/null 2>&1
	rm subs.txt
	rm subs1.txt
	echo "[$y/$x] done"
	((y++))

done

find ./subs* -type f -exec cat {} + | sort -u \; > ./all.txt
