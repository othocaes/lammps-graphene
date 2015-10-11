#!/bin/bash

#	This script will run a single instance of lammps using the supplied
# arguments on circe's Grid Engine cluster. It is intended to be used
# in scripts that generate multiple LAMMPS runs.

# Currently only supports 2 processors.

# Usage: ./lammps_exec.sh <input file> <log output file>

script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*\)/scripts.*@\1/scripts@')
bin_dir=$script_dir/../bin
lammps_exec=$bin_dir/lmp_circe-mkl

module purge
modules="compilers/intel/2013_cluster_xe"
for module in $modules; do
	module load $module
done

sub_name="BICRYSTAL_UNITS_RELAX"
sub_shell="/bin/bash"
lnch_res="h_rt=23:55:00,cpu_model=E5-2670,pcpus=2"
merge_stderrout="y"
output_file="lammps_sub.\$JOB_ID"
sub_mail_opts="abe"
sub_email="othoulrich@gmail.com"

qsub -b y -m $sub_mail_opts -M $sub_email -o $output_file -cwd -j $merge_stderrout -N $sub_name -l $lnch_res -S $sub_shell $lammps_exec < $1 > $2 



