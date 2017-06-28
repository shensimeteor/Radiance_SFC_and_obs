#!/bin/bash

narg=$#
if [ $narg -lt 1 ]; then
    echo "<usage>: [radiation_obs_file_cat]"
    echo "will adjust the date(to UTC) in input file, then split by hour into output/* files"
    exit 2
fi
input_file=$1

echo "step1. adjust time & cat to ${output}.temp1"
output="cat.all.output.txt"
rm -rf ${output}* &> /dev/null
while read date time id lat lon v1 v2 v3 v4 v5 v6 v7 v8; do
    lonplus=$(echo "$lon+7.5" | bc)
    t_offset=$(echo "$lonplus / 15" | bc)	
    newdate=$(date -d "$date $time $t_offset hour ago" +"%Y-%m-%d %H:%M:%S")
    echo $newdate $id $lat $lon $v1 $v2 $v3 $v4 $v5 $v6 $v7 $v8 >> $output".temp1"
done < $1

#sort
echo "step2. sort ${output}.temp1 to ${output}.temp2"
sort $output".temp1" > $output".temp2"

#split by date
output_dir="output/"
test -d $output_dir || mkdir $output_dir
IFS=$'\n'
for datex in $(cut -c 1-20 ${output}.temp2 | uniq); do
    date_name=$(date -d "$datex" +"%Y%m%d%H%M")
    if [ ! -e $output_dir/${date_time}"_Radiation.txt" ]; then
        echo "title line 1" > $output_dir/$date_name"_Radiation.txt"
        echo "title line 2" >> $output_dir/$date_name"_Radiation.txt"
    fi
    grep "$datex" $output".temp2" >> $output_dir/$date_name"_Radiation.txt"
done



