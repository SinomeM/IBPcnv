#!/bin/bash

#SBATCH --account=ripsych
#SBATCH --mem=4g
#SBATCH -c 1
#SBATCH --time 15:00:00

# Variables
wkdir=${1}
scripts=${2}
wv=${3}
i=${4}
s_acc=${5}

snpposfile=${wkdir}/snppos.txt
gcmodel=${wkdir}/gcmodel.txt

simg="singularity exec ${wkdir}/ibpcnv.simg"

hmm=${scripts}/lib/hhall.hmm

# Settings
min_snp=5
min_bps=1000

output=${wkdir}/calling_res/
log=${wkdir}/logs

mkdir -p $output
mkdir -p $log

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
