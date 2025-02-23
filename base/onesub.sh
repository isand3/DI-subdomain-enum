#!/bin/bash

echo "enter main domain"
read domain
echo "enter http header to use, type nothing if none"
read header
dname="${domain%.*}"
echo "cat file when done? y/n"
read -n 1 ans

while [ "$ans" != "y" ] && [ "$ans" != "n" ]; do
	echo "enter y or n:"
	read -n 1 ans
done

echo -e "\nwait..."

subfinder -all -d $domain -recursive -silent -o subs1.txt
echo "$domain" >> subs1.txt
sort -u subs1.txt > subs.txt
httpx -l subs.txt -o "./subs-$dname.txt" -sc -silent -fhr -pa -H "$header"
rm subs.txt
rm subs1.txt
echo done

if [ "$ans" = "y" ]; then
	cat ./subs-$dname.txt
fi
