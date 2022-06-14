#!/bin/bash

# Variables
wkdir=${1}
scripts=${2} # the location of IBPcnv repo clone
batches=${3}
hg=${4}

cd ${wkdir}/logs #unelegant solution to put PBS output in logs

snpposfile=${wkdir}/snppos_filtered.txt
gcmodel=${wkdir}/gcmodel.txt
gccont=${scripts}/gcfile/${hg}gc.txt

simg="singularity exec ${wkdir}/ibpcnv.simg"

cd $wkdir

# GC model #
echo -e "\nCreating GC content model"

# uncomment and edit this version of the command to use a SLURM account
# srun --account=$s_acc -c2 --mem=50g --time 00:30:00 \
#   $simg cal_gc_snp.pl $gccont $snpposfile --output $gcmodel
qsub -c1 --mem=10g --time 00:30:00 \
  $simg cal_gc_snp.pl $gccont $snpposfile --output $gcmodel

# Main loop #
for wv in $( seq 1 $batches ); do

  echo -e "\nLaunching the calling pipeline in batch n${wv}\n"
  qsub ${scripts}/penncnv_pipeline/03_1_per_wave.sh $wkdir $scripts $wv
  sleep 2

done

echo -e "\nPipeline launched in all batches!"
