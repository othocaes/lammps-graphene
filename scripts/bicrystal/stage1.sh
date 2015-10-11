#!/bin/bash

#	Stage 1 of the bicrystal unit population program.
#
#	This program will find all files ending in .POSCAR in any subdirectories   
# of [source dir] (or pwd if [source dir] is not specified), convert them 
# to jmol cartesian snapshots, then populate a new directory tree under 
# <root dir> with these snapshots.

#	The program will then convert each jmol snapshot to a LAMMPS input file 
# and shrink the simulation box around the sample. The program will also
# populate an info file for each sample, and store at this time the grain
# boundary mismatch angle in that file.

# Usage: ./stage1.sh <root dir> [source dir]


script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*\)/scripts.*@\1/scripts@')
bin_dir="$script_dir/../bin"
root_dir=$1
if [[ -z $2 ]]; then source_dir=$(pwd);	else source_dir=$2; fi

source_dir=$(echo "$source_dir"|sed 's@\([a-zA-Z0-9_-.]\)/*$@\1@')
root_dir=$(echo "$root_dir"|sed 's@\([a-zA-Z0-9_-.]\)/*$@\1@')

source $script_dir/func/utility.src


# Locate all *.POSCAR under $1
POSCAR_files=$(find $source_dir -name '*.POSCAR')

#echo $POSCAR_files
num_files=$(echo $POSCAR_files|wc -w)
echo $num_files POSCAR files found.

echo Processing files. Output to $root_dir.

count=0
echo -n "0% complete."
for POSCAR_file in $POSCAR_files; do

	# gather info
	file_name=$(basename $POSCAR_file)
	sample_name=$(echo $file_name|sed 's/.POSCAR//')
	sample_dir=$(dirname $POSCAR_file)
	
	# create new directory
	new_dir=$(echo $sample_dir|sed "s@^$source_dir@$root_dir/@"|sed 's/.POSCAR//'|sed 's@/$@@')	
	mkdir -p $new_dir

	# ylconv VASP:xyz, move to new dir
	xyz_initial="${new_dir}/${sample_name}_initial.xyz"
	$bin_dir/ylconv -svasp:xyz $POSCAR_file > $xyz_initial 2> /dev/null

#	echo $file_name
#	echo $sample_name
#	echo $sample_dir
#	echo $new_dir
#	echo $xyz_initial

	# convert to LAMMPS input
	#echo $new_dir
	#echo $sample_name
	LAMMPS_input="${new_dir}/${sample_name}.input"
	#echo $LAMMPS_input
	#echo "$script_dir/conv/xyz_to_lammps_input.sh $xyz_initial > $LAMMPS_input.tmp"
	$script_dir/conv/xyz_to_lammps_input.sh $xyz_initial > $LAMMPS_input.tmp
	
	# shrink box
	$script_dir/manip/shrink_box.sh $LAMMPS_input.tmp > $LAMMPS_input

	# create info file, write basic information
	info_file=${new_dir}/info
	echo "$sample_dir/$sample_name" > $info_file
	for iteration in $(seq $(echo "$sample_dir/$sample_name"|wc -c)); do echo -n "="; done >> $info_file
	echo -ne "\n" >> $info_file

	# parse grain mismatch angle and save to info file
	#mismatch_angle=$(head -n1 $POSCAR_file|sed 's/^.*angle\=\s*\([0-9.]\)\s*$//')
	mismatch_angle=$(head -n1 $POSCAR_file|sed 's/^.*\=\s*\([0-9]\)[^0-9]*/\1/')
	echo "$mismatch_angle" >> $info_file

	clean $new_dir > /dev/null

	(( count++ ))

	ratio=$(echo "
		scale=2
		count = $count
		num = $num_files
		ratio = count / num
		ratio
	" | bc)
	percent=$(echo $ratio|sed 's/\.//')
	echo -ne "\r${percent}% complete."

done