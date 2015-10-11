#!/bin/bash

# Usage: ./graph_energy_afo_x_displacement.sh <LAMMPS dump file> <output file>

#	This program creates xmgrace-readable output from a LAMMPS dump file.
# Independent variable: x displacement of each atom
# Dependent variable: 	energy of correlated atom

script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*/scripts\).*@\1@')      
source $script_dir/func/dump_parsing.src
source $script_dir/func/utility.src

# Test validity of input and output files, and create list of input files.

dump_file=$1
xmgrace_file=$2
default_output_file=script_output.xm

if [ -z $dump_file ]; then
	echo No input file specified. Exiting.
	exit 1
fi

echo Using input file $dump_file.

if [ -w $dump_file -a -r $dump_file ]; then
	echo $dump_file looks good.
else
	echo Cannot access $dump_file. Exiting.
	exit 1
fi

if [ -z $xmgrace_file ]; then
	xmgrace_file=${default_output_file}
	echo No output file specified. Using $xmgrace_file.
fi

if `! touch $xmgrace_file`; then
	echo Cannot access $xmgrace_file. Exiting.
	exit 2
fi

echo Output to $xmgrace_file.

> $xmgrace_file
> equilibrium_energy.tmp


num_atoms=$(parse_num_atoms_from_dump $dump_file)
echo Found $num_atoms atoms.

# Index entries by atom ID
for atom_id in $(seq 1 $num_atoms); do
	Z[$atom_id]=$(parse_coord x $dump_file $atom_id)
	U[$atom_id]=$(parse_atomic_pressure $dump_file $atom_id)
done

# Bubble sort by x value. -- Not finished and not necessary
# size=$num_atoms
# count=0
# until [[ $made_swap == "false" ]]; do
# 	made_swap="false"
# 	for index in $(seq 2 $size); do
# 		diff1=$(sed -n 5p ${info_array[$((index-1))]})
# 		diff2=$(sed -n 5p ${info_array[$index]})
# 		if [[ $(echo "$diff1 > $diff2"|bc) == "1" ]]; then
# 			temp_info=${info_array[$((index-1))]}
# 			info_array[$((index-1))]=${info_array[$index]}
# 			info_array[$index]=$temp_info
# 			made_swap="true"
# 		fi
# 	done
# 
# done


# Write array to xmgrace-readable file.
echo Writing $num_atoms entries to table.

for index in $(seq 1 $num_atoms ); do
	echo ${Z[$index]} ${U[$index]} >> $xmgrace_file
done

clean

echo Done.
exit 0
