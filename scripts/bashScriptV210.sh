#!/bin/sh

outputs=""
for i in {5..5}; do
    input=bigText$i.txt
    output=1234.$i.txt
    #@1,0,useMemTimeWithInput10,,input,sbatch -p short -c 1 --mem 2G -t 50:0 
    useMemTimeWithInput10.sh $input; grep 1234 $input > $output
    outputs=$outputs,$output
    
    # output=5678.$i.txt
    # #@2,0,useMemTimeWithInput10,,input,sbatch -p short -c 1 --mem 2G -t 50:0
    # useMemTimeWithInput10.sh $input; grep 5678 $input > $output
    # outputs=$outputs,$output
done

input=bigText1.txt
output=all.txt
#@3,1.2,useMemTimeWithInput10,,input
useMemTimeWithInput10.sh $input; cat 1234.*.txt 5678.*.txt > $output

