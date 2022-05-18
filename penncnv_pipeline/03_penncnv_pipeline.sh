#!/bin/bash

# Variables
wkdir=${1}
scripts=${2} # the location of IBPcnv repo clone
batches=${3}
hg=${4}

snpposfile=${wkdir}/snppos.txt
gcmodel=${wkdir}/gcmodel.txt
gccont=${script}/gcfile/${hg}gc.txt

simg="singularity exec ${wkdir}/ibpcnv.simg"

# GC model #
echo -e "\nCreating GC content model"

# srun --account=$s_acc -c2 --mem=50g --time 00:30:00 \
#   $simg cal_gc_snp.pl $gccont $snpposfile --output $gcmodel
srun -c2 --mem=50g --time 00:30:00 \
  $simg cal_gc_snp.pl $gccont $snpposfile --output $gcmodel

# Main loop #
for wv in {1..${batches}}; do

  echo -e "\nLaunching the calling pipeline in batch n${wv}\n"
  # batch number and SLURM account are passed to the script
  sbatch ${scripts}/penncnv_pipeline/03_1_per_wave.sh $wkdir $scripts $wv
  sleep 2

done

echo -e "\nPipeline launched in all batches!"
