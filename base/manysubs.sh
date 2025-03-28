#!/bin/bash

jsonfile=$(find . -name "*.json" | head -n 1)

# Checks if file exists

if [ -f "$jsonfile" ]; then
        echo "using $jsonfile"
else
        echo "no json file found"
        exit 1
fi

#

jq 'if type == "array" then empty else error("json file must contain a valid array") end' $jsonfile

echo "you can filter for the severity that the program offers"
echo "only domains that are eligible for your chosen severity will be selected (>=selected)"

# Functionality for interactive selection
# Each option will include domains in its category and above

PS3=" : "
options=("All" "Low" "Medium" "High" "Critical")
select opt in "${options[@]}"; do
	case $opt in
		"All")
			echo "All severity levels chosen"
			jq -r '[.[] | select(.Coverage == "In Scope")]' $jsonfile > "modified-$jsonfile"
			break
			;;
		"Low")
			jq -r '[.[] | select(.Severity != "Informational" and .Coverage == "In Scope")]' $jsonfile > "modified-$jsonfile"
			break
			;;
		"Medium")
			jq -r '[.[] | select(.Severity != "Informational" and .Severity != "Low" and .Coverage == "In Scope")]' $jsonfile > "modified-$jsonfile"
			break
			;;
		"High")
			jq -r '[.[] | select(.Severity == "High" or .Severity == "Critical") and .Coverage == "In Scope"]' $jsonfile > "modified-$jsonfile"
			break
			;;
		"Critical")
			jq -r '[.[] | select(.Severity == "Critical" and .Coverage == "In Scope")]' $jsonfile > "modified-$jsonfile"
			break
			;;
		*)
			echo "???"
			;;
	esac
done

echo -e "\nthis could take a while...."

# Enumerate subdomains and write the results to files

ipv4_regexp='^([0-9]{1,3}\.){3}[0-9]{1,3}(/([0-9]|[12][0-9]|3[0-2]))?$'
touch ./tmp2-manysubs.txt
touch ./tmp1-manysubs.txt

for assetkey in $(jq -r '.[] | @base64' "modified-$jsonfile"); do

        assetname=$(echo "$assetkey" | base64 -d | jq -r '.Asset')
#

# Skip anything with spaces

        if [[ "$assetname" =~ \  ]]; then
                continue
        fi
#

# Checks if ipv4 address, adds to list for no enumeration

	if [[ "$assetname" =~ $ipv4_regexp  ]]; then
		echo "$assetname" >> ./tmp2-manysubs.txt
		continue
	fi
#

# Checks if isolated asset (subdomains not in scope), add to list for no enumeration

	if [[ ! "$assetname" =~ "*." ]]; then
		echo "$assetname" >> ./tmp2-manysubs.txt
		continue
	fi
#

echo "$assetname" | sed 's/\*\.\(.*\)/\1/' >> ./tmp1-manysubs.txt

done


# Enumerate subdomains

echo "[1/2] enumerating with subfinder..."

subfinder -dL ./tmp1-manysubs.txt -recursive -o ./subs-tmp.txt > /dev/null 2>&1

echo "[1/2] done"
echo "[2/2] enumerating with assetfinder..."

for line in $(cat ./tmp1-manysubs.txt); do
	assetfinder -subs-only "$line" >> ./subs-tmp.txt

done

echo "[2/2] done"

cat subs-tmp.txt tmp2-manysubs.txt > subs.txt
rm ./subs-tmp.txt ./tmp2-manysubs.txt ./tmp1-manysubs.txt
sort -u subs.txt -o subs.txt
echo "enumeration complete"

#
