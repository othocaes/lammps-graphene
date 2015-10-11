#!/bin/bash

### NEEDS UPDATING ###

# Usage: ./create_graph.sh <input directory> <output file>

#	This program creates xmgrace-readable correlation tables from LAMMPS output
# logs. It uses the central atom depth as the independent variable, and
# as the # dependent variable, ( (E_pair - E_pair[initial])  / number of atoms )
# -- i.e., average energy per atom setting the equilibrium state E_pair[initial] = 0.
#
#	For every file matching "log.[0123456789.]*" in <input directory> this
# program locates the E_pair value from the final step, then correlates this
# value with DEPTH as described above. The assumed LAMMPS step output table
# format is:
#
#	Step Temp PotEng TotEng KinEng E_pair Press p2 
#


# Test validity of input and output files, and create list of input files.

input_directory=$1
output_file=$2
default_output_file=script_output.xm

if [ -z $input_directory ]; then
	input_directory=`pwd`
	echo No input directory specified. Using current directory.
fi

echo Using input directory $input_directory.

if [ -w $input_directory -a -r $input_directory ]; then

	input_files=`find "$input_directory" -maxdepth 1 -name 'log.[0-9.]*'|sort`
	echo Found `echo $input_files| wc -w` input files.
else
	echo Cannot access directory. Exiting.
	exit 1
fi

if [ -z $output_file ]; then
	output_file=${input_directory}/${default_output_file}
	echo No output file specified. Using $output_file.
fi

if `! touch $output_file`; then
	echo Cannot access $output_file. Exiting.
	exit 2
fi

> $output_file
> equilibrium_energy.tmp
echo Output to $output_file.


# Compile array of 2d data points by parsing input files.

index=0
for file in $input_files; do
	displacement=`parse_disp $file`
	equilibrium_status=`bc <<< "$displacement == 0"`
	U[$index]=`parse_energy_per_atom $file $equilibrium_status`
	Z[$index]=$displacement
	echo -n "$(( ++index )) "
done
echo

num_entries="$index"


# Write array to xmgrace-readable file.
echo Writing $num_entries entries to table.

for index in $(seq 0 $((num_entries-1)) ); do
	echo ${Z[$index]} ${U[$index]} >> $output_file
done

./clean.sh
echo Done.
exit 0
