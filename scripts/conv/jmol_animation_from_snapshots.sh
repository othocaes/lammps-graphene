#!/bin/bash

#	A script to create a jmol-formatted animation file from xyz files
# output by LAMMPS.

# Usage: ./create_animation.sh <input directory> <output file>
#
#	<directory> must contain xyz output files from a LAMMPS
# simulation. These files must be formatted as prescribed by
# create_xyz.sh as this script uses create_xyz.sh to create
# individual jmol-formatted files. Any files in <directory>
# ending in .xyz will be processed. The files are processed
# in alphanumerical order by first converting integer values
# to floats.

script_dir=`echo $0|sed 's/\(.*\)\/[^/]*/\1/'`

# Some functions used by this program.







# Test validity of input and output files, and create list of input files.

input_directory=$1
output_file=$2
default_output_file=script_output.ani

if [ -z $input_directory ]; then
	input_directory=`pwd`
	echo No input directory specified. Using current directory.
fi

echo Using input directory $input_directory.

if [ -w $input_directory -a -r $input_directory ]; then
	# Have to translate integers to doubles in stream to sort properly.
	sorted_list=`find $input_directory -maxdepth 1 -name '0-0.xyz' -o -name '*.xyz' -a ! -name '*-0.xyz'|sed 's/\/\([0-9]*\)-\([0-9]\)/\/\1.0-\2/'|sort -n`
	# Stream edit must be removed so filenames correlate.
	input_files=`echo "$sorted_list"|sed 's/\([0-9]\)\.0-/\1-/'`
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
else
	> $output_file
fi

echo Output to $output_file.



# Create jmol-readable xyz file for each animation step.

log_file=./tmp.anim.log
step_num=0
tmp_output_files=""

echo Creating individual coordinate sets for animation.

echo " " >> $log_file
echo " " >> $log_file
echo New run occuring. >> $log_file
echo `date` >> $log_file

for input_file in $input_files; do
	echo " " >> $log_file
	echo Creating new animation step. >> $log_file
	step_file=$input_directory/tmp.anim.$step_num
	if `${script_dir}/create_xyz.sh $input_file $step_file $step_num >> tmp.anim.log`; then
		tmp_output_files="$tmp_output_files $step_file"
		echo -n "$((++step_num)) "
	fi
done

echo ""

num_steps=`find $input_directory -maxdepth 1 -name 'tmp.anim.[0-9]*'|wc -w`
echo Created $num_steps animation steps. $step_num expected. Log in $log_file.



# Create jmol-readable animation file from output_files.

echo Creating animation from coordinate sets.
for file in $tmp_output_files; do
	cat $file >> $output_file
done

${script_dir}/clean.sh

echo Done.
exit 0




