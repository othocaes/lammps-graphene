#!/bin/bash

# Usage: ./graph_stress_afo_strain.sh <sample directory> <output file>

#	This program creates xmgrace-readable output from a LAMMPS dump file.
# Independent variable: x displacement of each atom
# Dependent variable: 	energy of correlated atom

script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*/scripts\).*@\1@')      
source $script_dir/func/log_parsing.src
source $script_dir/func/utility.src

# Test validity of input and output files, and create list of input files.

sample_dir=$1
xmgrace_file=$2
default_output_file=analyses/script_output.xm

if [ -z $sample_dir ]; then
	echo No input dir specified. Exiting.
	exit 1
fi

echo Using input dir $sample_dir.

if [ -z $xmgrace_file ]; then
	xmgrace_file=${default_output_file}
fi

mkdir -p analyses

if `! touch $xmgrace_file`; then
	echo Cannot access $xmgrace_file. Exiting.
	exit 2
fi

echo Output to $xmgrace_file.

> $xmgrace_file


lammps_logs=$(find $sample_dir -name 'log.lmp')

# Find all minimization results and sort.
min_dirs=$(find $sample_dir -name 'min.*' -type d|sort)

# Load dependent (stress) and independent (strain) values.
count="0"
for dir in $min_dirs; do
	(( count++ ))
	log=$dir/log.lmp
	stress_in_bar=$(parse_final_system_stress $log)
	indep[$count]=$(echo $dir|sed 's@/*$@@'|sed 's@.*/\([^/]*\)@\1@'|sed 's@min@0@')
	dep[$count]=$(bc <<< "scale=10; $stress_in_bar * 10^-4")
done

# Write array to xmgrace-readable file.
echo Writing $count entries to table.

for index in $(seq 1 $count); do
	echo ${indep[$index]} ${dep[$index]} >> $xmgrace_file
done

echo Done.
exit 0
