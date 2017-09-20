#!/bin/bash

#Author:A hernandez
#help
#usage: cfsan_target_creator.sh

# Test whether the script is being executed with sge or not.
if [ -z $sge_task_id ]; then
        use_sge=0
else
        use_sge=1
fi


# Exit immediately if a pipeline, which may consist of a single simple command, a list, or a compound command returns a non-zero status
set -e
# Treat unset variables and parameters other than the special parameters ‘@’ or ‘*’ as an error when performing parameter expansion. An error message will be written to the standard error, and a non-interactive shell will exit
set -u
#Print commands and their arguments as they are executed.
set -x

#VARIABLES

threads=$1
dir=$2
samples=$3
dedup_bam_list=$4
intervals_list=$5
gatk_path=$6
ref_path=$7

if [ "$use_sge" = "1" ]; then                                                                                                                                                                                               
   	sample_count=$sge_task_id                                                                      
else                                                                                              
   	sample_count=$8                                              
fi

sample=$( echo $samples | tr ":" "\n" | head -$sample_count | tail -1)
dedup_bam_file=$( echo $dedup_bam_list | tr ":" "\n" | head -$sample_count | tail -1)
intervals_file=$( echo $intervals_list | tr ":" "\n" | head -$sample_count | tail -1)


java -Djava.io.tmpdir=$TEMP $JAVA_RAM -jar $gatk_path/GenomeAnalysisTK.jar \
	-T RealignerTargetCreator \
	-R $ref_path \
	-I $dir/$sample/$dedup_bam_file \
	-o $dir/$sample/$intervals_file 

