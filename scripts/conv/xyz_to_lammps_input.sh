#!/bin/bash

#	Creates a LAMMPS output file from a jmol snapshot, provided the jmol
# is in xyz format. Box size is arbitrary, as currently written. LAMMPS
# file is written to stdout.

# Only works with carbon.

# Usage: ./xyz_to_lammps_input.sh <jmol file>

script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*\)/scripts.*@\1/scripts@')

source $script_dir/func/utility.src

xyz_file=$1

cat $xyz_file|sed 's/C/1/' > $xyz_file.tmp

num_atoms=$(( $(cat $xyz_file.tmp|wc -l) - 2))
new_filename=`echo $xyz_file.tmp|sed 's/xyz/input/'`

echo "LAMMPS Input file created using OAU xyz->input script." # > $new_filename
echo "" # >> $new_filename
echo "${num_atoms} atoms" # >> $new_filename
echo "" # >> $new_filename
echo "1 atom types" # >> $new_filename
echo "" # >> $new_filename
echo "-30 30 xlo xhi" # >> $new_filename
echo "-30 30 ylo yhi" # >> $new_filename
echo "-30 30 zlo zhi" # >> $new_filename
echo "" # >> $new_filename
echo "Masses" # >> $new_filename
echo "" # >> $new_filename
echo "1 12.01" # >> $new_filename
echo "" # >> $new_filename
echo "Atoms" # >> $new_filename
echo "" # >> $new_filename

for atom_id in $(seq 1 $num_atoms); do
	line_num=$((atom_id + 2))
	echo -n "$atom_id "
	sed -n ${line_num}p $xyz_file.tmp|sed 's/C/1/'
done
	# cat $1.tmp.2 # >> $new_filename
