#!/bin/bash

#	A script to create a LAMMPS input data file from an atomic data dump
# by LAMMPS.
#
# Usage: ./lammps_dump_to_input.sh <input file> <output file>

# 	Currently, this program assumes all atoms are carbon ("1").
# It also assumes the LAMMPS dump file correctly reported the
# number of atoms.

input_file=$1
output_file=$2
default_output_file="fromdump.input"


# Test validity of input and output files and step number.
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


# Read info from the LAMMPS dump.
num_atoms=0
line_num=0

while read -r line; do

	if [[ -z "$line" ]]; then continue; fi

	if [[ $(( ++line_num )) -eq 1 ]]; then
		if [ "$line" != "ITEM: TIMESTEP"  ]; then
			echo Are you sure $input_file is a LAMMPS xyz output file?
		fi
	fi

	if [[ $(echo "$line"|cut -d' ' -f1,2,3) == "ITEM: BOX BOUNDS" ]]; then
		read -r xlo xhi other
		read -r ylo yhi other
		read -r zlo zhi other
	fi

	if [[ "$line" == "ITEM: NUMBER OF ATOMS" ]]; then
		read -r num_atoms
		if [ $num_atoms -gt 0 ]; then
			echo Number of atoms found: $num_atoms
			continue
		else
			echo Number of atoms not found.
			exit 5
		fi
	fi

	# Collect atomic data.
	if [[ $(echo $line|cut -f1,2 -d' ') == "ITEM: ATOMS" ]]; then
		echo Compiling coordinate list.
		i=3; words=$(echo $line|wc -w);
		while [[ "$i" -le "$words" ]]; do
			column=$(echo $line|cut -d' ' -f$i)
			case $column in 
			"id") id_pos=$((i-2)) ;;
			"x") x_pos=$((i-2)) ;;
			"y") y_pos=$((i-2)) ;;
			"z") z_pos=$((i-2)) ;;
			esac
			(( i++ ))
		done
		for index in $(seq 1 $num_atoms); do
			read -r atomic_data
			atom_id[$index]=$(echo "$atomic_data"|cut --fields=$id_pos -d' ')
			coords[$index]=$(echo "$atomic_data"|
								cut --fields=$x_pos,$y_pos,$z_pos -d' ')
		done
	fi
done < $input_file

if [ $num_atoms -eq 0 ]; then
	echo No atoms found. Exiting.
	exit 6
fi


# Bubble sort atoms by atom_id.
echo Sorting atoms.
size=$num_atoms
count=0
until [[ $made_swap == "false" ]]; do
	made_swap="false"
	for index in $(seq 2 $size); do
		if [[ ${atom_id[$index]} < ${atom_id[$index-1]}  ]]; then
			temp_id=${atom_id[$((index-1))]}
			temp_coords=${coords[$((index-1))]}
			atom_id[$((index-1))]=${atom_id[$index]}
			coords[$((index-1))]=${coords[$index]}
			atom_id[$index]=$temp_id
			coords[$index]=$temp_coords
			made_swap="true"
		fi
	done

done


# Write new LAMMPS input data.
echo Writing LAMMPS input data to $output_file.
echo -n "LAMMPS input data file created using " > $output_file
echo "OAU LAMMPS dump->LAMMPS input script." >> $output_file
echo "" >> $output_file
echo "$num_atoms atoms" >> $output_file
echo "" >> $output_file
echo "" >> $output_file
echo "1 atom types" >> $output_file
echo "" >> $output_file
echo "$xlo $xhi xlo xhi" >> $output_file
echo "$ylo $yhi ylo yhi" >> $output_file
echo "$zlo $zhi zlo zhi" >> $output_file
echo "" >> $output_file
echo "Masses" >> $output_file
echo "" >> $output_file
echo "1 12.01" >> $output_file
echo "" >> $output_file
echo "Atoms" >> $output_file
echo "" >> $output_file
for index in $(seq 1 $num_atoms); do
	echo "$index 1 ${coords[$index]}" >> $output_file
done

# Finished.
echo Done.
exit 0