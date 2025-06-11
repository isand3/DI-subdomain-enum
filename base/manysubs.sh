#!/bin/bash

jsonfile=$(find . -name "*.json" | head -n 1 | sed 's|^./||')

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
			jq -r '[.[] | select(.Severity != "None")]' $jsonfile > "modified-$jsonfile"
			break
			;;
		"Low")
			jq -r '[.[] | select(.Severity != "Informational" and .Severity != "None")]' $jsonfile > "modified-$jsonfile"
			break
			;;
		"Medium")
			jq -r '[.[] | select(.Severity != "Informational" and .Severity != "Low" and .Severity != "None")]' $jsonfile > "modified-$jsonfile"
			break
			;;
		"High")
			jq -r '[.[] | select(.Severity == "High" or .Severity == "Critical")]' $jsonfile > "modified-$jsonfile"
			break
			;;
		"Critical")
			jq -r '[.[] | select(.Severity == "Critical")]' $jsonfile > "modified-$jsonfile"
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
		echo "$assetname" >> ./ip-list.txt
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

cat subs-tmp.txt tmp2-manysubs.txt | sed 's/\*\.\(.*\)/\1/' > subs.txt
rm ./subs-tmp.txt ./tmp2-manysubs.txt ./tmp1-manysubs.txt
sort -u subs.txt -o subs.txt
echo "enumeration complete"

#

nmap -sn -iL subs.txt -v 0 -oN online-subs.txt >/dev/null

# Extract ip addresses

awk '{
  while (match($0, /\b([0-9]{1,3}\.){3}[0-9]{1,3}\b/)) {
    ip = substr($0, RSTART, RLENGTH);
    split(ip, o, ".");
    if (o[1] <= 255 && o[2] <= 255 && o[3] <= 255 && o[4] <= 255)
      print ip;
    $0 = substr($0, RSTART + RLENGTH);
  }
}' online-subs.txt | sort -u > online-ips.txt

#

# Nmap scan function

function nmap_scan () {

echo "1 for standard scan, 2 for 65535"
while true; do
	read -n 1 -s key2
	if [ $key2 -eq 1 ]; then
		nmap -iL online-ips.txt -oN nmap-standard.txt
		break
	elif [ $key2 -eq 2 ]; then
		nmap -iL -p- online-ips.txt -oN nmap-65535.txt
		break
	else
		echo "press 1 or 2"
		echo
	fi
done
}

echo -n "scan all hosts up for ports? (y/n): "
echo

while true; do
    read -n 1 -s key
    if [ "$key" == "y" ]; then
        nmap_scan
        break
    elif [ "$key" == "n" ]; then
        break
    else
        echo "press y or n"
	echo
    fi
done

#
