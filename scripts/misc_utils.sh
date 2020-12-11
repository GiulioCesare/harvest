#!/bin/bash


function dump_array()
{
	ar_name=$1
	ar=$2

	# (IFS=$'\n'; echo "${ar[*]})

	# Dump array
	# ----------
	echo "Dump array "$ar_name
	for K in "${!ar[@]}";
	    do
	        echo $K"="${ar[$K]}
	    done
	echo "End dump array"
}


