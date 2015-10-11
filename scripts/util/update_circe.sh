#!/bin/bash

script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*\)/scripts.*@\1/scripts@')
msl_dir=$script_dir/..

rsync -avv --exclude 'inc' --exclude 'papers' --exclude 'proc' $msl_dir/ oulrich@circe.rc.usf.edu:/work/o/oulrich/msl