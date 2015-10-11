#!/bin/bash

# Usage: ./stage3.sh <root dir>

#	Stage 3 of the bicrystal unit population program runs
# post-processing analyses on completed LAMMPS runs located
# under <root dir>.
#
#
#	Post-processing procedure:
#
#	- Create initial and final state xyz files from .dump files.
#	- Create ecfg with atomic coordinates, energy, and pressure
#	- Create xmgrace-readable tables for each structure:
#		* atomic energy as function of x displacement
#		* atomic pressure as function of x displacement
#		* atomic stress xy component as function of x displacement
#	- Append info files with:
#		<num atoms> atoms
#		<formation energy> - <formation energy of pristine graphene>
#		<initial box dimensions>
#		<final box dimensions>
#		Coordinations
#		-------------
#			4: # atoms
#			3: # atoms
#			2: # atoms
#			1: # atoms
#
#
#	- Copy contents of all info files to file named "report" under
#	<root dir>.




script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*/scripts\).*@\1@')      
bin_dir=$script_dir/../bin
root_dir=$1

source $script_dir/func/log_parsing.src
source $script_dir/func/dump_parsing.src
source $script_dir/func/utility.src

pristine_form_energy="-7.956" # eV/atom, value obtained from SEDREBO
								# relaxation of pristine structure.


# Find all info files, used as indicators of completed LAMMPS run.
info_files=$(find $root_dir -name 'info')
num_info_files=$(echo $info_files|wc -w)

# Find and write formation energy difference and coordination histogram.
echo -n "Analysing data, writing xyz files, creating tables, and "
echo -ne "appending info files for $num_info_files structures.\n"
sample_count=1
count=0
echo -n "0% complete."

for info_file in $info_files; do
	# Locate files.
	proc_dir=$(dirname $info_file)
	initial_dump_file=$(find $proc_dir -name '*.dump'|sort -n|sed -n 1p)
	final_dump_file=$(find $proc_dir -name '*.dump'|sort -n -r|sed -n 1p)

	# Create initial and final state xyz files.
	$script_dir/conv/lammps_dump_to_xyz.sh $initial_dump_file $proc_dir/initial.xyz >> /dev/null
	$script_dir/conv/lammps_dump_to_xyz.sh $final_dump_file $proc_dir/final.xyz >> /dev/null

	#echo yo!

	# Create ecfg file with atomic energies and pressures.
	$script_dir/conv/lammps_dump_to_xyz_with_energy_and_pressure.sh $final_dump_file $proc_dir/final_wEP.xyz.tmp >> /dev/null
	$bin_dir/ylconv -sxyz:ecfg $proc_dir/final_wEP.xyz.tmp > $proc_dir/final.ecfg >> /dev/null 2> /dev/null

	# Create "minimized.input" for each final dump.
	$script_dir/conv/lammps_dump_to_input.sh $final_dump_file $proc_dir/minimized.input >> /dev/null

	# Create xmgrace-readable tables.
	energy_table_file="$proc_dir/energy_afo_x.xm"
	pressure_table_file="$proc_dir/pressure_afo_x.xm"
	stressxy_table_file="$proc_dir/stressxy_afo_x.xm"
	$script_dir/analysis/graph_energy_afo_x_displacement.sh $final_dump_file $energy_table_file >> /dev/null
	$script_dir/analysis/graph_pressure_afo_x_displacement.sh $final_dump_file $pressure_table_file >> /dev/null
	$script_dir/analysis/graph_stressxy_afo_x_displacement.sh $final_dump_file $stressxy_table_file >> /dev/null

	#echo here!

	# Gather info.
	energy=$(parse_final_energy $proc_dir/log.lmp)
	num_atoms=$(parse_num_atoms_from_dump $final_dump_file)
	form_energy=$(bc <<< "scale=10; $energy / $num_atoms")
	form_energy_diff=$(bc <<< "scale=10; $form_energy - $pristine_form_energy")
	box_xyz_initial=$(parse_box_dimensions_from_dump $initial_dump_file)
	box_xyz_final=$(parse_box_dimensions_from_dump $final_dump_file)

	#echo hello?

	# Write to info file.
	echo "$num_atoms atoms" >> $info_file
	echo $form_energy_diff >> $info_file
	echo $box_xyz_initial >> $info_file
	echo $box_xyz_final >> $info_file
	echo -e "Coordinations\n-------------" >> $info_file
	coordination_histogram=$(parse_coordinations $final_dump_file)
	for coordination_number in $(seq 0 9); do
		num_with_coordination=$(echo $coordination_histogram|cut -d' ' -f$((coordination_number +1)) )
		if [[ $num_with_coordination > 0 ]]; then
			echo -e "\t $coordination_number: $num_with_coordination" >> $info_file
		fi
	done
	
	#echo Hey!

	clean $proc_dir >> /dev/null

	(( count++ ))
	ratio=$(echo "
		scale=2
		count = $count
		num = $num_info_files
		count / num
	" | bc)
	percent=$(echo $ratio|sed 's/\.//')
	echo -ne "\r${percent}% complete."
done
echo -en "\n"


# Compile info files to report.
echo Compiling info files to report.
report_file=$root_dir/report   # $(date +%Y-%m-%d-%H:%M:%S)
date > $report_file
echo "" >> $report_file
sorted_info_files=$(echo $info_files|sort)
count=0
echo -n "0% complete."
for info_file in $sorted_info_files; do
	cat $info_file >> $report_file
	echo -en "\n\n" >> $report_file

	(( count++ ))
	ratio=$(echo "
		scale=2
		count = $count
		num = $num_info_files
		count / num
	" | bc)
	percent=$(echo $ratio|sed 's/\.//')
	echo -ne "\r${percent}% complete."
done
echo -en "\n"


