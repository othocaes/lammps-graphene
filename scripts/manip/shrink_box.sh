#!/bin/bash

# Usage: ./shrink_wrap_box.sh <LAMMPS input file>

# 	Program to output new LAMMPS file with cuboid box
# shrink-wrapped to atomic coordinates. Outputs new 
# LAMMPS input file to stdout.

script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*/scripts\).*@\1@')
input_file=$1

source $script_dir/func/lammps_functions.src

# Gather info.
bounds=$(print_extremes $input_file)
xmin=$(echo $bounds|cut -d' ' -f1)
xmax=$(echo $bounds|cut -d' ' -f2)
ymin=$(echo $bounds|cut -d' ' -f3)
ymax=$(echo $bounds|cut -d' ' -f4)
zmin=$(echo $bounds|cut -d' ' -f5)
zmax=$(echo $bounds|cut -d' ' -f6)

# Set box bounds.
xlo=$(bc <<< "$xmin - .5")
xhi=$(bc <<< "$xmax + .5")
ylo=$(bc <<< "$ymin - .5")
yhi=$(bc <<< "$ymax + .5")
zlo=$(bc <<< "$zmin - 1.675")
zhi=$(bc <<< "$zmax + 1.675")

# Print new LAMMPS input to stdout.
while read -r line; do
	dimension=$(echo $line|sed 's/^\s*[0-9.-]\+\s\+[0-9.-]\+\s\+\([xyz]\)lo.*$/\1/')
	if [[ $dimension == "x"	]]; then 
		echo "$xlo $xhi xlo xhi"
		continue;
	fi
	if [[ $dimension == "y"	]]; then 
		echo "$ylo $yhi ylo yhi"
		continue;
	fi
	if [[ $dimension == "z"	]]; then 
		echo "$zlo $zhi zlo zhi"
		continue;
	fi
	echo $line
done < $input_file

