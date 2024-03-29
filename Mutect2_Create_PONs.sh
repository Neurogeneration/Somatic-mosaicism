#!/bin/sh
#SBATCH -J CreatePONs
#SBATCH -o /fast/users/a1092098/launch/slurm-%j.out
#SBATCH -A robinson
#SBATCH -p batch
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --time=01:00:00
#SBATCH --mem=8GB

# Notification configuration
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=clare.vaneyk@adelaide.edu.au

# load modules
module load Java/1.8.0_121
module load GATK

gatk CreateSomaticPanelOfNormals \
-vcfs pon_vcf.args \
-O pon.vcf.gz >> CreatePONs.pipeline.log 2>&1
