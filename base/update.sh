#!/bin/bash

x=0

for file in *; do
	if [ -f $file ] && [[ "$file" == *.sh ]]; then
		cp  $file $home/bin
		if [ $? -eq 0 ]; then
			echo "copied $file to bin"
		else
			echo "failed to copy $file"
			((x++))
		fi
	fi
done

if [ "$x" -gt 0 ]; then
	echo "run with sudo"
fi
