#!/bin/bash

script_dir=`echo $0|sed 's/\(.*\)\/[^/]*/\1/'`

source $script_dir/load_lammps_functions.sh

if [[ -z $* ]]; then
	echo No list given. Exiting.
	exit 1
fi

list=" $* "
for runtype in $list; do

	if [[ ! -r $runtype.in || ! -r samples/$runtype.input ]]; then
		echo "Input files not found or cannot be read for ${runtype}. Skipping."
		continue
	fi

	mkdir $runtype
	rm $runtype/*
	
	echo "Preparing run for ${runtype}."
	echo "Creating coordinate tables and input scripts."
	pulled_atoms=$(get_pulled_atoms $runtype.in)
	echo $pulled_atoms
	for increment in $(seq 0 5 900); do
		displacement=$(convert_to_pull_displacement $increment 100)
		echo Hello
		input_filename="$runtype/$displacement.input.tmp"
		in_filename="$runtype/$displacement.in.tmp"
		pullout samples/$runtype.input "$pulled_atoms" $displacement 0 > $input_filename
		cat $runtype.in|
			sed "s/^\(read_data\s*\)\([-_a-zA-Z0-9]*\)\.input\s*/\1${input_filename}/"|
			sed "s/DISPLACEMENT/$displacement/g" > $in_filename
		echo -n "$displacement "
	done
	echo
	echo "Processing LAMMPS inputs. (Not Really)"

#	for LAMMPS_input in $(find . -regextype sed -regex ".*/$runtype\.[0-9.]*\.in\.tmp"|
#										sort -n); do
#		displacement=$(echo $LAMMPS_input|
#						sed "s/.*\/$runtype\.\([0-9.]\+\)*\.in\.tmp/\1/")
#		../../bin/lmp_serial.icc  < $LAMMPS_input > $runtype/output.$displacement
#		echo -n "$displacement "
#	done
done

echo
echo Done.

# clean_tmp . $list 

