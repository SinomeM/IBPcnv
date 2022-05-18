#!/bin/bash

###SBATCH --account=account_here
#SBATCH --mem=4g
#SBATCH -c 1
#SBATCH --time 15:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x%j.err

# Settings
min_snp=5
min_bps=1000

# Variables
wkdir=${1}
scripts=${2}
wv=${3}
i=${4}

snpposfile=${wkdir}/snppos.txt
gcmodel=${wkdir}/gcmodel.txt

simg="singularity exec ${wkdir}/ibpcnv.simg"

hmm=${scripts}/lib/hhall.hmm

output=${wkdir}/calling_res/
log=${wkdir}/logs

cd $wkdir

mkdir -p $output

# Autosomes
$simg detect_cnv.pl \
  --test \
  --hmmfile $hmm \
  --pfbfile $pfbfile \
  --gcmodelfile $gcmodel \
  --minsnp ${min_snp} \
  --minlength ${min_bps} \
  --confidence \
  --output $output/wave${wv}_${i}.rawcnv \
  --logfile ${log}/wave${wv}_${i}_autosome.log \
  --directory ${raw}/ \
  --listfile ${wkdir}/listfile/listfile${wv}_${i}.txt
