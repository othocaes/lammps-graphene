#!/bin/bash

script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*\)/scripts.*@\1/scripts@')
msl_dir=$script_dir/..

date > $msl_dir/upload_date

rsync -avv --exclude 'reports' --exclude 'mnt' --exclude 'inc' --exclude 'devel' --exclude 'papers' --exclude 'proc' $msl_dir/ oulrich@192.168.1.2:/home/oulrich/msl


