#!/bin/sh
#SBATCH -J Mutect2
#SBATCH -o /fast/users/a1092098/launch/slurm-%j.out
#SBATCH -A robinson
#SBATCH -p batch
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --time=12:00:00
#SBATCH --mem=8GB

# Notification configuration
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=clare.vaneyk@adelaide.edu.au

# load modules
module load Java/1.8.0_121
module load GATK
module load SAMtools

# run the executable
# A script to call somatic variants gatk Mutect2, designed for the Phoenix supercomputer

usage()
{
echo "# A script to call somatic variants gatk Mutect2, designed for the Phoenix supercomputer
# Requires: GATK and a list of samples
#
# Usage sbatch --array 0-(nSamples-1) $0  -b /path/to/bam/files [-o /path/to/output] | [ - h | --help ]
#
# Options
# -S    REQUIRED. List of sample ID in a text file
# -b    REQUIRED. /path/to/bamfiles.bam. Path to where you want to find your bam files. Every file matching a sample ID will be used.
# -O    OPTIONAL. Path to where you want to find your file output (if not specified current directory is used)
# -h or --help  Prints this message.  Or if you got one of the options above wrong you'll be reading this too!
#
#
# Original: Derived from GATK.HC.Phoenix by Mark Corbett, 16/11/2017
# Modified: (Date; Name; Description)
# 21/06/2018; Mark Corbett; Modify for Haloplex
# 09/07/2018; Clare van Eyk; modify for use with Mutect2 command from GATK
# 09/08/2019; Clare van Eyk; modify to call somatic variants with PONs and gnomad frequencies

"
}

## Set Variables ##
while [ "$1" != "" ]; do
        case $1 in
                -S )                    shift
                                        SAMPLE=$1
                                        ;;
                -b )                    shift
                                        bamDir=$1
                                        ;;
                -O )                    shift
                                        VcfFolder=$1
                                        ;;
                -h | --help )           usage
                                        exit 0
                                        ;;
                * )                     usage
                                        exit 1
        esac
        shift
done

if [ -z "$SAMPLE" ]; then # If no SAMPLE name specified then do not proceed
        usage
        echo "#ERROR: You need to specify a list of sample ID in a text file eg.                                                                                                           /path/to/SAMPLEID.txt"
        exit 1
fi

# Define batch jobs based on samples
sampleID=($(cat $SAMPLE))

if [ -z "$bamDir" ]; then # If no bamDir name specified then do not proceed
        usage
        echo "#ERROR: You need to tell me where to find the bam files."
        exit 1
fi
if [ -z "$VcfFolder" ]; then # If no output directory then use default directory
        VcfFolder=$FASTDIR/WGS/Mosaic/Calls_with_PON
        echo "Using $FASTDIR/WGS/Mosaic/Calls_with_PON as the output directory"
fi
if [ ! -d $VcfFolder ]; then
        mkdir -p $VcfFolder
fi

tmpDir=$FASTDIR/tmp/${sampleID[$SLURM_ARRAY_TASK_ID]} # Use a tmp directory for all of the GATK and samtools temp files
if [ ! -d $tmpDir ]; then
        mkdir -p $tmpDir
fi

## Start of the script ##
###On each sample###
cd $tmpDir
gatk Mutect2 \
-I $bamDir/${sampleID[$SLURM_ARRAY_TASK_ID]}.*dedup.realigned.recalibrated.bam \
-tumor ${sampleID[$SLURM_ARRAY_TASK_ID]} \
-R /data/biohub/Refs/human/gatk_bundle/2.8/b37/human_g1k_v37_decoy.fasta \
--germline-resource /data/neurogenetics/RefSeq/GATK/b37/somatic-b37_af-only-gnomad.raw.sites.vcf \
--panel-of-normals $FASTDIR/WGS/Mosaic/pon.vcf.gz \
--af-of-alleles-not-in-resource -1 \
--max-population-af 0.02 \
-O $VcfFolder/${sampleID[$SLURM_ARRAY_TASK_ID]}.mosaic.PONs_gnomad.vcf >> $tmpDir/${sampleID[$SLURM_ARRAY_TASK_ID]}.somatic.pipeline.log 2>&1
