#!/bin/bash
## Author: A.Hernandez
## version v2.0

if [ $# -eq 0 ];then
        echo -e "\nScript to concat Fastq files\n"
        echo -e "Usage: concat.sh input_dir output_dir samples_list FastqR1_list FastqR2_list concatFastq_list"
        exit
fi

#Test whether the script is being used with sge or not.
if [ -z $SGE_TASK_ID ]; then
	use_sge=0
else
	use_sge=1
fi

# Exit immediately if a pipeline, which may consist of a single simple command, a list, or a compound command returns a non-zero status 
set -e  
# Treat unset variables and parameters other than the special parameters ‘@’ or ‘*’ as an error when performing parameter expansion. An error message will be written to the standard error, and a non-interactive shell will exit
set -u 
#Print a trace of simple commands, for commands, case commands, select commands, and arithmetic for commands and their arguments or associated word lists after they are expanded and before they are executed
set -x

# VARIABLES

dir=$1
output_dir=$2
samples=$3
fastq_files_R1=$4
fastq_files_R2=$5
concatFastq_list=$6

if [ "$use_sge" = "1" ]; then
	sample_count=$SGE_TASK_ID
else
 	sample_count=$7
fi

sample=$( echo $samples | tr ":" "\n" | head -$sample_count | tail -1)
fastq_R1=$( echo $fastq_files_R1 | tr ":" "\n" | head -$sample_count | tail -1)
fastq_R2=$( echo $fastq_files_R2 | tr ":" "\n" | head -$sample_count | tail -1)
concatFastq=$( echo $concatFastq_list | tr ":" "\n" | head -$sample_count | tail -1)

echo -e "concat files for $sample \n\n"

zcat $dir/$sample/$fastq_R1 $dir/$sample/$fastq_R2 > $output_dir/$concatFastq

echo -e "Concat $sample finished \n\n"
