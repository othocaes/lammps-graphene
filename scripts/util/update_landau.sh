#!/bin/bash

script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*\)/scripts.*@\1/scripts@')
msl_dir=$script_dir/..

rsync -e 'ssh -p 5024' -avv --exclude 'reports' --exclude 'templates' --exclude 'office' --exclude 'devel' --exclude 'inc' --exclude 'papers' --exclude 'proc' $msl_dir/ oulrich@landau.cas.usf.edu:/home/oulrich/msl
