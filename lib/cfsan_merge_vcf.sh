#!/bin/bash
#help
#Usage: cfsan_merge_vcf.sh

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

dir=$1

cfsan_snp_pipeline merge_vcfs -n consensus.vcf -o $dir/snpma.fasta $dir/sampleDirectories.txt.OrigVCF.filtered
cfsan_snp_pipeline merge_vcfs -n consensus_preserved.vcf -o $dir/snpma_preserved.fasta $dir/sampleDirectories.txt.PresVCF.filtered