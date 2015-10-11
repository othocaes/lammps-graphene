#!/bin/bash


#	A script to create an xyz file from an atomic data dump
# by LAMMPS.
#
# Usage: ./create_xyz.sh <input file> <output file> <step number>

# 	Currently, this program assumes all atoms are carbon ("C").
# It also assumes the LAMMPS output file correctly reported the
# number of atoms. Step number can be used if the output file is
# intended as part of a jmol animation.



# Test validity of input and output files and step number.

input_file=$1

if [ -z $input_file ]; then
	echo No input file given. Exiting.
	exit 2
fi

if [ -r $input_file ]
then
	echo Using input file $input_file.
else
	echo Cannot read $input_file. Exiting.
	exit 3
fi


default_output_file="script_output.xyz"
output_file=$2
if [ -z $output_file ]; then
	echo No output file given. Using $default_output_file.
	output_file=$default_output_file
else
	echo Output to $output_file.
fi

if touch $output_file; then
	echo Output file looks good.
else
	Cannot write to output file. Exiting.
	exit 4
fi

step_line=""

if [ -z $3 ]; then
	echo No step number specified. Creating singular output.
else
	if [ $3 -ge 0 ]; then
		step_line="STEP $3"
		echo Output intended for animation step $3.
	else
		echo Invalid step number. Exiting.
		exit 5
	fi
fi



# Read atom list from the input file.
#
# 	Assuming LAMMPS output atom table format:
#		id element x y z f[x] f[y] f[z].

num_atoms=0
line_num=0

while read -r line; do

	if [ -z "$line" ]; then continue; fi

	if [ $(( ++line_num )) -eq 1 ]; then
		if [ "$line" != "ITEM: TIMESTEP"  ]; then
			echo Are you sure $input_file is a LAMMPS xyz output file?
		fi
	fi

	if [ "$line" == "ITEM: NUMBER OF ATOMS" ]; then
		read -r num_atoms
		if [ $num_atoms -gt 0 ]; then
			echo Number of atoms found: $num_atoms
			continue
		else
			echo Number of atoms not found.
		fi
	fi

	if [[ $(echo $line|cut -f1,2 -d' ') == "ITEM: ATOMS" ]]; then
		echo Compiling atomic data.
		i=3; words=$(echo $line|wc -w);
		while [[ "$i" -le "$words" ]]; do
			case $(echo $line|cut -d' ' -f$i) in
				"x") x_pos=$((i-2)) ;; 
				"y") y_pos=$((i-2)) ;;
				"z") z_pos=$((i-2)) ;;
				"c_atomic_energy") atomic_energy_pos=$((i-2)) ;;
				"v_atomic_pressure") atomic_pressure_pos=$((i-2)) ;;
			esac
			(( ++i ))
		done
		#echo $words : $x_pos : $y_pos : $z_pos : $atomic_energy_pos : $atomic_pressure_pos
		for index in $(seq 1 $num_atoms); do
			read -r atomic_data_line
			atomic_data[$index]=$(echo "$atomic_data_line"|cut --fields=$x_pos,$y_pos,$z_pos,$atomic_energy_pos,$atomic_pressure_pos -d' ')
		done
	fi
done < $input_file

if [ $num_atoms -eq 0 ]; then
	echo No atoms found. Exiting.
	exit 6
fi




# Write atom list to output file.

echo Writing xyz format to $output_file.

echo $num_atoms > $output_file
echo $step_line >> $output_file

for index in $(seq 1 $num_atoms); do
	echo C ${atomic_data[$index]} >> $output_file
done


echo Done.
exit 0