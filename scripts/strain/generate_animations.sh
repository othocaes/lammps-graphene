#!/bin/bash

# Usage: ./generate_animations.sh <root dir>


#SBATCH -J LAMMPS_1core
#SBATCH -o anim.o%j
#SBATCH -e anim.e%j
#SBATCH --share
#SBATCH -n 1
#SBATCH -t 12:00:00
#SBATCH --partition=amd_rack


script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*/scripts\).*@\1@')
strain_run_dirs=$(find $1 -name 'strain_runs' -type d)
origin_dir=$(pwd)

echo Generating Animations...

count="0"
for strain_run_dir in $strain_run_dirs; do
	cd $origin_dir
	cd $strain_run_dir
	cd ..
	pwd
	$script_dir/strain/create_animation_from_all_dumps.sh
	$script_dir/strain/create_animation_from_final_dumps.sh
	echo -n "$((count++)) "
done
echo -ne "\n"