#!/bin/bash

#	This program will statically apply biaxial strain on a sample or samples
# by some delta-strain.

# Usage: ./conduct_biaxial_stress_test_on_unit_bicrystals.sh <root dir> [source dir]

#	For any samples found under [source dir] (or current directory if 
# [source dir] is not supplied), this program will search for LAMMPS input
# called "minimized.input." This program assumes the structure to be a cell
# intended for periodic boundary conditions.

# 	For each of these inputs, the program will call "stretch.x," a c++
# program that will created a new LAMMPS input file with a box size larger
# by delta-strain in the x and y dimensions, and transform the atomic 
# coordinates so that each atom's position relative to the simulation box
# remains unchanged.

#	The program will then run a minimization and repeat this process until
# a maximum strain is reached.

script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*\)/scripts.*@\1/scripts@')
bin_dir="$script_dir/../bin"
root_dir=$1
if [[ -z $2 ]]; then source_dir=$(pwd);	else source_dir=$2; fi

source $script_dir/func/utility.src
source $script_dir/func/input_parsing.src

input_files=$(find $source_dir -name 'minimized.input')
num_files=$(echo $input_files|wc -l)

echo Found $num_files input files. Creating initial states.

origin_dir=$(pwd)

count="0"
for input_file in $input_files; do
	# create new directory and set initial.input.
	file_name=$(basename $input_file)
	sample_dir=$(dirname $input_file)
	new_dir=$(echo $sample_dir|sed "s@^$source_dir@$root_dir/@"|sed 's@/*$@@')
	mkdir -p $new_dir
	cp $input_file $new_dir/initial.input

	cd $new_dir

	simulation_box_lengths initial.input > box_lengths.tmp
	read Lx Ly Lz < box_lengths.tmp

	#	Setup strain lengths because cluster doesn't have bc.
	strain_sequence=$(seq 5 5 500|
					sed 's/^\([0-9]\)$/00\1/'|
					sed 's/^\([0-9]\)\([0-9]\)$/0\1\2/')

	> strain_lengths.tmp

	pwd
 
	for strain in $strain_sequence; do
		new_Lx=$(bc <<< "scale=10; $Lx * (1.$strain)")
		new_Ly=$(bc <<< "scale=10; $Ly * (1.$strain)")
		echo "STRAIN=$strain $new_Lx $new_Ly" >> strain_lengths.tmp
	done


	#sbatch $script_dir/cluster/strain_loop.sub .
	$script_dir/run/apply_strain.sh .
	(( count++ ))

	cd $origin_dir
done


echo $count threads submitted.