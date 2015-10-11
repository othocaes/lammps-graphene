#!/bin/bash

# Usage: ./relax_sample_and_box.sh <data file>

# 	This program will minimize the energy state of a graphene sample while
# simultaneously relaxing the simulation box around the sample such that
# the cuboid is a near approximation of the mechanical structure of the
# sample. The simulation relaxes the box only in the x and y dimensions.

#	The program will populate a LAMMPS script in <data file>'s directory
# based on scripts/lammps/relax_sample_and_box.lmp, then run it, creating
# output in the same directory. log.lmp is created, along with #.dump for
# the initial and final states.

script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*\)/scripts.*@\1/scripts@')
bin_dir="$script_dir/../bin"
potential_dir="$script_dir/../potentials/"

if [[ -z $1 ]]; then
	echo No data file given. Exiting.
	exit 1
fi

data_file=$1
sample_name=$(echo $data_file|sed 's@.*/\(a-zA-Z0-9_-\).input@\1@')
sample_dir=$(dirname $data_file)

if [[ ! -r $data_file ]]; then
	echo "Data file not found or cannot be read for ${data_file}." >> /dev/stderr
	exit 1
fi

cat $script_dir/lammps/relax_sample_and_box.lmp|
	sed "s@_DATA_FILE@${data_file}@"|
	sed "s@_OUTPUT_DIR@${sample_dir}@"|
	sed "s@_BOND_LENGTH_HISTOGRAM_FILE@${sample_dir}/bond_length_histogram@"|
	sed "s@_POTENTIAL_FILE@${potential_dir}/ch.sedrebo@" > $sample_dir/relax_sample_and_box.lmp

# To run on single machine
$bin_dir/lmp_serial < $sample_dir/relax_sample_and_box.lmp > $sample_dir/log.lmp

# To run on circe
# $script_dir/circe/lammps_exec.sh $sample_dir/relax_sample_and_box.lmp $sample_dir/log.lmp

# To run on msl cluster
# sbatch $script_dir/cluster/LAMMPS_1core.sub $sample_dir/relax_sample_and_box.lmp $sample_dir/log.lmp >> /dev/null
