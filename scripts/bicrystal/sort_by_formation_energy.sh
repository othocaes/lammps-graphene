#	This program searches info files under <root dir> and organizes them based
# on criteria outlined below.

# Usage: ./sort_by_Formation_energy.sh <root dir> <output file>


root_dir=$1
output_file=$2

pristine_form_energy="7.956" # eV/atom
info_files=$(find $root_dir -name 'info')

# write info file names to array.
count=0
for info_file in $info_files; do
# Skip structures with energy diff over a threshold.
#	greater_than_.3_diff=$(echo "scale=4
#		diff = $(sed -n 5p $info_file)
#		pristine = $pristine_form_energy
#		ratio = diff/pristine
#		ratio > .3 
#		" | bc)
#	if [[ $greater_than_.3_diff == "1" ]]; then continue; fi
	info_array[$((++count))]=$info_file
done

echo "$count info files processed."

# Bubble sort array according to formation energy diff.
#echo -n "[                    ]"
size=$count
count=0
until [[ $made_swap == "false" ]]; do
	made_swap="false"
	count=0
	for index in $(seq 2 $size); do
		diff1=$(sed -n 5p ${info_array[$((index-1))]})
		diff2=$(sed -n 5p ${info_array[$index]})
		if [[ $(echo "$diff1 > $diff2"|bc) == "1" ]]; then
			temp_info=${info_array[$((index-1))]}
			info_array[$((index-1))]=${info_array[$index]}
			info_array[$index]=$temp_info
			made_swap="true"
		fi

		(( count++ ))

		num_tiles_float=$(echo "
		scale=4
		count = $count
		size = $size
		ratio = count / size
		ratio * 20
		" | bc)
		#echo 	$num_tiles_float
		num_tiles=$(printf "%d" "$num_tiles_float" 2> /dev/null)
		#echo $num_tiles
		echo -ne "\r["
		for tile in $(seq 1 $num_tiles); do
			echo -n "="
		done
		for space in $(seq 1 $(( 20 - num_tiles))); do
			echo -n ' '
		done
		echo -n ']'
	done

done

echo ""
echo -e "Output to $output_file."

# output array to <output file>
echo $(date) > $output_file
echo ""	>> $output_file
for index in $(seq 1 $size); do
	echo "[$index]" >> $output_file
	cat ${info_array[$index]} >> $output_file
	echo "" >> $output_file
done

