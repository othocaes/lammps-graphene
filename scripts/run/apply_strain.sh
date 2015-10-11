#!/bin/bash

# Usage: ./apply_strain.sh <sample directory>

# Expects "initial.input" to be an equilibrium state at 0 strain.

script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*\)/scripts.*@\1/scripts@')
bin_dir="$script_dir/../bin"
potential_dir="$script_dir/../potentials/"

source $script_dir/func/input_parsing.src

#lammps_executable="srun $bin_dir/lmp_msl-mkl"
lammps_executable="$bin_dir/lmp_serial"

sample_dir=$1

#	Check initial input.
initial_input="$sample_dir/initial.input"

if [[ ! -r $initial_input ]]; then
	echo -n "Data file not found or " >> /dev/stderr
	echo "cannot be read for ${initial_input}." >> /dev/stderr
	exit 1
fi

#	Setup strain sequence.
strain_sequence=$(seq 5 5 500|
					sed 's/^\([0-9]\)$/00\1/'|
					sed 's/^\([0-9]\)\([0-9]\)$/0\1\2/')
strain[0]="000"
index=1;
for strain in $strain_sequence; do
	strain[$((index++))]=$strain
done
num_strains=$((index -1))

#	Move to sample directory for strain sequence.
origin_dir=$(pwd)
cd $sample_dir

#	Setup work space.
mkdir -p strain_runs
#mkdir -p strain_inputs

#	Use initial.input as 1.0000.input
#cp initial.input strain_inputs/1.000.input

#	Load parameters for biaxial strain program.
# echo "$equilibrium_Lx $equilibrium_Ly $equilibrium_Lz 0.005 0.005 0.0" > strain_runs/strain_params

#	Run strain sequence.
cd strain_runs
prev_strain_id="000"

# First minimize initial state.
mkdir -p min.000
cd min.000
cp ../../initial.input equilibrium.input

cat $script_dir/lammps/strain.lmp|
	sed "s@_DATA_FILE@equilibrium.input@"|
	sed "s@_OUTPUT_DIR@.@"|
	sed "s@_BOND_LENGTH_HISTOGRAM_FILE@bond_length_histogram@"|
	sed "s@_POTENTIAL_FILE@${potential_dir}/ch.sedrebo@" > strain.lmp
$lammps_executable < strain.lmp > log.lmp

cd ..
echo 'Initial structure "ready." Stretching...'

# Conduct the stretch sequence.
for index in $(seq 1 $num_strains); do
	strain_id=${strain[$index]}

	#	Prepare next minimization.
	mkdir -p min.$strain_id
	cd min.$strain_id

	#	Create stretched input.
	grep "STRAIN=$strain_id" ../../strain_lengths.tmp > box_lengths
	read strain new_Lx new_Ly other < box_lengths
	echo "$prev_strain_id"
	pwd

	final_prev_cooorddump_file=$(find ../min.$prev_strain_id -name '*.coorddump'|sort -r|sed -n 1p)
	echo $final_prev_cooorddump_file
	$bin_dir/lammps_dump_input $final_prev_cooorddump_file stretched.input.tmp $new_Lx $new_Ly
	#sed -e "s@# LAMMPS data file@LAMMPS data file edited\n@" stretched.input.tmp|sed -e "s@\s*atoms@ atoms\n@"|sed 's/  / /' > stretched.input
	sed -e "s@[0-9.-]\+\s\+[0-9.-]\+\s\+zlo zhi@0.0 3.350 zlo zhi@" stretched.input.tmp > stretched.input
	rm stretched.input.tmp

	#	Run minimization.
	cat $script_dir/lammps/strain.lmp|
		sed "s@_DATA_FILE@stretched.input@"|
		sed "s@_OUTPUT_DIR@.@"|
		sed "s@_BOND_LENGTH_HISTOGRAM_FILE@bond_length_histogram@"|
		sed "s@_POTENTIAL_FILE@${potential_dir}/ch.sedrebo@" > strain.lmp
	$lammps_executable < strain.lmp > log.lmp

	# Prepare for next strain.
	cd ..	
	echo -n "$strain_id "
	prev_strain_id=$strain_id
done

echo -ne "\n"
cd $origin_dir
