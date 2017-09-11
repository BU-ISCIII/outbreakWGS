#!/bin/bash
## Author S. Monzon                                                                                                  ## version v2.0                                                                                                      

# Test whether the script is being executed with sge or not.
if [ -z $sge_task_id ]; then
	use_sge=0
else
	use_sge=1
fi

## Usage
if [ $# != 11 -a "$use_sge" == "1" ]; then
	echo "usage: ............"
	exit
elif [ $# != 12 -a "$use_sge" == "0" ]; then
	echo "usage: ............"
	exit
fi

# Exit immediately if a pipeline, which may consist of a single simple command, a list, or a compound command returns a non-zero status
set -e
# Treat unset variables and parameters other than the special parameters ‘@’ or ‘*’ as an error when performing para meter expansion. An error message will be written to the standard error, and a non-interactive shell will exit
set -u
#Print commands and their arguments as they are executed.
set -x 

echo `date`

# VARIABLES

threads=$1
input_dir=$2
output_dir=$3
samples=$4
know_snps=$5
know_indels=$6
input_list=$7
realignedBamArray_list=$8
recalibratedBamArray_list=$9 
ref_path=${10}
gatk_path=${11}



if [ "$use_sge" = "1" ]; then
	sample_count=$sge_task_id
else
	sample_count=${12}
fi

sample=$( echo $samples | tr ":" "\n" | head -$sample_count | tail -1)
input=$( echo $input_list | tr ":" "\n" | head -$sample_count | tail -1)
realignedBamArray=$( echo $realignedBamArray_list | tr ":" "\n" | head -$sample_count | tail -1)
recalibratedBamArray=$( echo $recalibratedBamArray_list | tr ":" "\n" | head -$sample_count | tail -1)

mkdir -p $output_dir/realignment

if [ $know_indels == "NO" ]; then

	java -Djava.io.tmpdir=$TEMP $JAVA_RAM -jar $gatk_path/GenomeAnalysisTK.jar \
 		-T RealignerTargetCreator \
		-I $input_dir/$sample/$input \
 		-R $ref_path \
 		-o $output_dir/realignment/$input-IndelRealigner.intervals \
 		-nt $threads \
 		-S LENIENT \
 		-log $output_dir/realignment/$input-targetCreator.log
                                                                                       
	java -Djava.io.tmpdir=$TEMP $JAVA_RAM -jar $gatk_path/GenomeAnalysisTK.jar \
 		-T IndelRealigner \
		-I $input_dir/$sample/$input \
 		-R $ref_path \
 		-targetIntervals $output_dir/realignment/$input-IndelRealigner.intervals \
 		-o $output_dir/realignment/$realignedBamArray \
 		-S LENIENT \
 		-log $output_dir/$input-realigner.log

else
    
   	 java -Djava.io.tmpdir=$TEMP $JAVA_RAM -jar $gatk_path/GenomeAnalysisTK.jar \
    		-T RealignerTargetCreator \
    		-I $input/$sample/$input \
    		-known $know_indels \
    		-R $ref_path \
    		-o $output_dir/realignment/$input-IndelRealigner.intervals \
    		-nt $threads \
    		-S LENIENT \
    		-log $output_dir/realignment/$input-targetCreator.log
                                                                                        
    	java -Djava.io.tmpdir=$TEMP $JAVA_RAM -jar $gatk_path/GenomeAnalysisTK.jar \
    		-T IndelRealigner \
    		-I $input_dir/$sample/$input \
    		-known $know_indels \
    		-R $ref_path \
    		-targetIntervals $output_dir/realignment/$input-IndelRealigner.intervals \
    		-o $output_dir/realignment/$realignedBamArray \
    		-S LENIENT \
    		-log $output_dir/$input-realigner.log                                        

fi


if [ $know_snps != "NO" ]; then
	echo -e "2) Base Quality Recalibration"                                               
                                                                                       
	mkdir -p $output_dir/recalibration
	
	java -Djava.io.tmpdir=$TEMP $JAVA_RAM -jar $gatk_path/GenomeAnalysisTK.jar \
      		-T BaseRecalibrator \
      		-R $ref_path \
 		-I $output_dir/realignment/$realignedBamArray \
 		-knownSites $know_snps \
 		-cov ReadGroupCovariate \
 		-cov QualityScoreCovariate \
 		-cov CycleCovariate \
 		-cov ContextCovariate \
      		-o $output_dir/recalibration/$input-recal1_data.grp \
 		-nct $threads \
 		-S LENIENT \
 		-log $output_dir/gatk_trio/$input-recal.log
                                                                                       
	java -Djava.io.tmpdir=$TEMP $JAVA_RAM -jar $gatk_path/GenomeAnalysisTK.jar \
    		-T BaseRecalibrator \
    		-BQSR $output_dir/recalibration/$input-recal1_data.grp \
    		-R $ref_path \
    		-I $output_dir/realignment/$realignedBamArray \
    		-knownSites $know_snps \
   		-cov ReadGroupCovariate \
    		-cov QualityScoreCovariate \
    		-cov CycleCovariate \
    		-cov ContextCovariate \
    		-o $output_dir/recalibration/$input-recal2_data.grp \
    		-nct $threads \
    		-S LENIENT \
    		-log $output_dir/$input-recal.log                                        
                                                                                       
	java -Djava.io.tmpdir=$TEMP $JAVA_RAM -jar $gatk_path/GenomeAnalysisTK.jar \
    		-T AnalyzeCovariates \
    		-R $ref_path \
    		-before $output_dir/recalibration/$input-recal1_data.grp \
    		-after $output_dir/recalibration/$input-recal2_data.grp \
    		-csv $output_dir/recalibration/$input-BQSR.csv \
    		-plots $output_dir/recalibration/$input-BQSR.pdf \
    		-log $output_dir/$input-analyzecovariates.log                       
                                                                                       
	java -Djava.io.tmpdir=$TEMP $JAVA_RAM -jar $gatk_path/GenomeAnalysisTK.jar \
    		-T PrintReads \
    		-R $ref_path \
    		-I $output_dir/realignment/$realignedBamArray \
    		-BQSR $output_dir/recalibration/$input-recal1_data.grp \
    		-o $output_dir/recalibration/$recalibratedBamArray \
    		-nct $threds \
    		-S LENIENT \
    		-log $output_dir/$input-print_recal.log
fi
