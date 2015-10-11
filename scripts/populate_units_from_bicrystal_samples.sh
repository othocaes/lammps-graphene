#	This program will create graphene bicrystal unit cells that can constitute
# an infinite lattice when periodic boundary conditions are applied (in 2d).

# Usage: ./populate_units_from_bicrystal_samples.sh <root dir> [source dir]


#	The program will create a unit cell from any POSCAR files found under 
# [source dir] (or pwd if [source dir] is not specified]. It will create a 
# new directory structure under <root dir>, maintaining naming and directory 
# conventions. The program uses LAMMPS sample minimization and simulation box
# relaxation to create the lowest possible energy state from the given lattice.

#	The program is meant to be used to minimize samples created by Kien in the MSL. The program should minimize all samples and output
# unit cells that can then be used in future LAMMPS PBC simulations.



#	The program is organized into three stages: preparation, minimization, and
# analysis

#	In stage 1, the program will find all files ending in .POSCAR in any
# subdirectories of user's current pwd, convert them to jmol cartesian
# snapshots, then populate a new directory tree under <root dir> with 
# these snapshots. The program will then convert each jmol snapshot to a
# LAMMPS input file and shrink the initial box around the sample. The 
# program will also populate an info file for each sample, and store at
# this time the grain boundary mismatch angle in that file. The current info
# file format as of 2014 July 19 is:

#	All angles in degrees
#	All energies in eV (presuming metal units in LAMMPS)

#	<sample dir>/<sample name>
#	==============
#	<misorientation angle>
#	<num atoms> atoms
#	<formation energy> - <formation energy of pristine graphene>
#	<initial box dimensions>
#	<final box dimensions>
#	Coordinations
#	-------------
#		4: # atoms
#		3: # atoms
#		2: # atoms
#		1: # atoms


#	In stage 2, the program will run relax_sample_and_box.sh on each sample
# from stage 1, thus creating a unit cell for PBC from each sample. 

#	In stage 3, the program will then check bond lengths for each sample and
# report any outliers in that sample's info file. Next, a JMOL snapshot will   
# be generated. Finally, the system's change in energy over the minimzation
# will be calculated and stored in the info file. A report is then produced 
# in <root dir> containing a print of all info files.


script_dir=$( cd $(dirname $0) ; pwd -P |sed 's@^\(.*\)/scripts.*@\1/scripts@')
bin_dir="$script_dir/../bin"
root_dir=$1
if [[ -z $2 ]]; then source_dir=$(pwd);	else source_dir=$2; fi

source $script_dir/func/utility.src


# (Stage 1) -- Preparation

$script_dir/bicrystal/stage1.sh $root_dir $source_dir
echo -e "\nStage 1 complete. \n"


# (Stage 2) -- Minimization

$script_dir/bicrystal/stage2.sh $root_dir
echo -e "Stage 2 complete.\n"


# (Stage 3) -- Analysis

echo "Please run stage 3 manually: scripts/bicrystal/stage3.sh $root_dir"

# $script_dir/bicrystal/stage3.sh $root_dir
# echo -e "Stage 3 complete.\n"


echo Program complete.


