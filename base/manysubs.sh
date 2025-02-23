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

# Enumerate subdomains and write the results to files

mkdir manysubs-tmpfiles

for assetkey in $(jq -r '.[] | @base64' "$jsonfile"); do

        assetname=$(echo "$assetkey" | base64 -d | jq -r '.Asset')

        if [[ "$assetname" =~ \  ]]; then
                continue
        fi

        adomain="${assetname#*\.}"

        if [[ "$assetname" != *'*'* ]]; then
                bdomain="$assetname"
        fi

        if [[ "$assetname" = *'*'* ]]; then
                asubdomain="${assetname##*\*.}"
                bsubdomain="${assetname%%\**}"
        fi

        echo "$adomain" >> manysubs-tmpfiles/subs1.txt
        echo "$bdomain" >> manysubs-tmpfiles/subs1.txt

        echo "$asubdomain" >> manysubs-tmpfiles/subs2.txt
        echo "$bsubdomain" >> manysubs-tmpfiles/subs3.txt

done

echo "task [1/4] done"

subfinder -all -dL manysubs-tmpfiles/subs1.txt -recursive -o manysubs-tmpfiles/subs1-done.txt > /dev/null 2>&1

echo "task [2/4] done"

subfinder -all -dL manysubs-tmpfiles/subs2.txt -recursive -o manysubs-tmpfiles/subs2-done.txt > /dev/null 2>&1

echo "task [3/4] done"

grep -Ff manysubs-tmpfiles/subs3.txt manysubs-tmpfiles/subs2-done.txt > manysubs-tmpfiles/subs3-done.txt
cat manysubs-tmpfiles/subs1-done.txt manysubs-tmpfiles/subs3-done.txt | sort -u > manysubs-tmpfiles/tmpsubdomains.txt

httpx -l manysubs-tmpfiles/tmpsubdomains.txt -o subdomains.txt -sc -fhr -pa -H "$header" > /dev/null 2>&1

sort subdomains.txt -o subdomains.txt

rm -rf manysubs-tmpfiles/

echo "task [4/4] done"
echo "complete"
