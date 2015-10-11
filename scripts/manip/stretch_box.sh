#!/bin/bash

# Usage: ./stretch_box.sh <LAMMPS input file> <strain> [<current strain>]

#	Program to biaxially strain a simulation box and the atoms contained within.


# Setup.
script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*/scripts\).*@\1@')      

source $script_dir/func/input_parsing.src
source $script_dir/func/utility.src


input_file=$1

current_strain=".0000"
if [[ -z $2 ]]; then
	;
fi




# Gather information.
simulation_box_lengths $input_file > tmp.boxlengths
read Lx Ly Lz < tmp.boxlengths
rm tmp.boxlengths

found_atoms="false"
while read line; do
	if [[ $found_atoms == "false" && $(echo $line|cut -d' ' -f1) == Atoms ]];
		then read toss; found_atoms="true"; continue; fi
	if [[ found_atoms == "true"]]; then
		echo $line > $input_buf
		read atom_id atom_type pos_x pos_y pos_z < $input_buf
		pos_x[$atom_id]=$pos_x
		pos_y[$atom_id]=$pos_y
		pos_z[$atom_id]=$pos_z 
	fi
done < $input_file

# Organize arguments.
strain=$2
NewLx=$(bc <<< "scale=10; Lx * (1 + $strain) / (1 + $current_strain)")
NewLx=$(bc <<< "scale=10; Lx * (1 + $strain) / (1 + $current_strain)")
NewLx=$(bc <<< "scale=10; Lx * (1 + $strain) / (1 + $current_strain)")
#x
#y
#z


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
