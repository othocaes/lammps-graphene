#!/bin/bash

#	Stage 2 of the bicrystal unit population program will run
# relax_sample_and_box.sh for any LAMMPS input files found under <root dir>,
# thus creating a unit cell for PBC from each sample. 

# Usage: ./stage2.sh <root dir>

script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*/scripts\).*@\1@')
bin_dir=$script_dir/../bin
root_dir=$1

# find all input files
input_files=$(find $root_dir -name '*.input')
num_files=$(echo $input_files|wc -w)
echo Found $num_files input files.

count=0
echo -n "0% complete."
# relax sample/box
for input_file in $(echo $input_files); do
	$script_dir/run/relax_sample_and_box.sh $input_file

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

echo -en "\n"