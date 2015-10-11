#!/bin/bash

# Usage: ./generate_stress_strain_curves.sh <root dir>


script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*/scripts\).*@\1@')
strain_run_dirs=$(find $1 -name 'strain_runs' -type d)

echo Generation stress-strain graphs...

count="0"
for strain_run_dir in $strain_run_dirs; do
	$script_dir/analysis/graph_stress_afo_strain.sh $strain_run_dir/.. $strain_run_dir/../stress_afo_strain.xm > /dev/null
	echo -n "$((count++)) "
done
echo -ne "\n"
