#!/bin/bash


script_dir=`echo $0|sed 's/\(.*\)\/[^/]*/\1/'`

# Used to determine angle for displacement calculations.
reference_atom=37


# Usage: loc_x <LAMMPS input file> <atom #>
function loc_x { cat $1|grep "^$2\s*[0-9]"|sed "s/^$2\s*1\s*\([-0-9.]*\)\s*[-0-9.]*\s*[-0-9.]*\s*/\1/"; }
function loc_y { cat $1|grep "^$2\s*[0-9]"|sed "s/^$2\s*1\s*[-0-9.]*\s*\([-0-9.]*\)\s*[-0-9.]*\s*/\1/"; }

# Usage: pullout <LAMMPS input file> <atom #> <x displacement> <y disp>
#
#	Return LAMMPS input file text after adding displacement*sin(theta) to
# y coord, and displacement*cos(theta) to the x coord, of indicated atom #.
function pullout {
	newloc_x=$(bc <<< "$(loc_x $1 $2) + $3")
	newloc_y=$(bc <<< "$(loc_y $1 $2) + $4")
	# echo $1 $2 $3 $4 > /dev/stderr
	cat $1|sed "s/^\($2\s*1\s*\)\([-0-9.]*\)\(\s*\)\([-0-9.]*\)\(\s*\)\([-0-9.]*\)\(\s*$\)/\1${newloc_x}\3${newloc_y}\5\6\7/"
}


function clean.func {
	if [ -z $1 ]; then
		dir="."
	else
		dir="$1"
	fi
	
	echo -n "Cleaning temporary files in \"$dir\"... "
	
	rm ${dir}/*tmp* 2> /dev/null
	
	echo Done.
	exit 0
}


if [[ -z $* ]]; then
	echo No list given. Exiting.
	exit 1
fi

list=" $* "
for runtype in $list; do
	mkdir $runtype
	rm $runtype/*
	pulled_atom=$(grep 'group' $runtype.in|grep 'pulled'|sed 's/^.*id *\([0-9]*\).*$/\1/')
	
	echo "Creating coordinate tables and input scripts."

	for increment in $(seq 0 5 900); do
		displacement=$(bc <<< "scale=2; $increment / 100"|sed 's/^\([0-9]\)*$/\1\.00/'|sed 's/\.\([0-9]\)\s*$/\.\10/'|sed 's/^\./0\./')
		delta_x=$( bc <<< "scale=6; $(loc_x $runtype.input ${pulled_atom}) - $(loc_x $runtype.input ${reference_atom})" )
		delta_y=$( bc <<< "scale=6; $(loc_y $runtype.input ${pulled_atom}) - $(loc_y $runtype.input ${reference_atom})" )
		slope=$( bc <<< "scale=5; ${delta_y} / ${delta_x}" )
		theta=$( bc -l <<< "a(${slope})" )
		disp_x=$(bc -l <<< "$displacement * c($theta)")
		disp_y=$(bc -l <<< "$displacement * s($theta)")
		# echo $displacement $theta $delta_y $delta_x
		# echo "$(loc_x $runtype.input ${pulled_atom}) $(loc_y $runtype.input ${pulled_atom}) "
		input_filename="$runtype.$displacement.input.tmp"
		in_filename="$runtype.$displacement.in.tmp"
		pullout $runtype.input $pulled_atom $disp_x $disp_y > $input_filename
		cat $runtype.in|sed "s/^\(read_data\s*\)\([-_a-zA-Z0-9]*\)\.input\s*/\1${input_filename}/"|sed "s/DISPLACEMENT/$displacement/g" > $runtype.$displacement.in.tmp

		echo -n "$displacement "
	done
	echo
	
	echo "Processing LAMMPS inputs."

	for LAMMPS_input in $(find . -regextype sed -regex ".*/$runtype\.[0-9.]*\.in\.tmp"|sort -n); do
		displacement=$(echo $LAMMPS_input|sed "s/.*\/$runtype\.\([0-9.]\+\)*\.in\.tmp/\1/")
		../../bin/lmp_serial.icc  < $LAMMPS_input > $runtype/log.$displacement
		echo -n "$displacement "
	done
done

echo
echo Done.

clean.func

