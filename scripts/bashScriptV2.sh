#!/bin/sh

number=$1

[ -z "$number" ] && echo -e "Error: number is missing.\nUsage: bashScriptV1.sh <numbert>" && exit 1

for i in {1..50}; do
    
    input=numbers$i.txt
    
    #@1,0,findNumber,,input,sbatch -p short -c 1 --mem 2G -t 50:0 
    findNumber.sh $number $input > $number.$i.txt
  
    ##@2,1,findNumber,,input,sbatch -p short -c 1 --mem 2G -t 50:0 
    #findNumber.sh $number $input >> $number.$i.txt
done

##@3,1.2,mergeNumber,,,sbatch -p short -c 1 --mem 2G -t 50:0 
#cat $number.*.txt > all$number.txt