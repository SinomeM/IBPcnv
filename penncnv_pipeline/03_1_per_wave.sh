#!/bin/bash

#SBATCH --account=${4}
#SBATCH --mem=50g
#SBATCH -c 2
#SBATCH --time 12:00:00
#SBATCH --output=/faststorage/jail/project/recurrent_cnvs/people/smontalbano/logs/%x.%j.out
#SBATCH --error=/faststorage/jail/project/recurrent_cnvs/people/smontalbano/logs/%x.%j.err
#
# This script run one time for each batch

# Variables
wkdir=${1}
scripts=${2}
wv=${3}
s_acc=${4}

snpposfile=${wkdir}/snppos.txt
gcmodel=${wkdir}/gcmodel.txt

simg="singularity exec ${wkdir}/ibpcnv.simg"

# listfile are already created by the preprocessing script
listfile=$wkdir/listfile/batch${3}.txt
pfb=${wkdir}/pfb/batch${wv}.pfb

# intensity files must be already in the correct format

# PFB file #

echo -e "\nComputing PFB for Wave n ${wv}"

mkdir -p $wkdir/pfb

$simg compile_pfb.pl -snpposfile $snpposfile -output $pfb -listfile $listfile

echo -e "\n Done!\n"
sleep 2


# CNV calling #

# calculate the number of chunks based on the total samples
n_samples=$( cat $listfile | wc -l )
n_chunks=$(( $n_samples/200 ))
last_chunk=$(( $n_samples%200 ))
# in this way there will be $n_chunks of exactly 200 samples, plus a final with the remaining ones

echo -e "\n Calling CNVs in the Wave ${wv}, samples will run in $n_chunks+1 chunks."

# call a sbatch script
for i in $( seq 1 1 $n_chunks ); do
  # extract chunks of 200 samples
  nn=$(( $i-1 ))
  nt=$(( 200*$nn))
  # for the first chunk nt needs to remain 0
  if [[ $nt -gt 0 ]];then
    let nt++
  fi
  tail $listfile -n+${nt} | head -n 200 > ${wkdir}/listfile/listfile${wv}_${i}.txt
  # launch the sbatch script for this chunk
  sbatch ${scripts}/penncnv_pipeline/cnv_calling.sh $wv $i $s_acc
  sleep 0.5
done

sleep 1

# last batch
let i++
tail $listfile -n $last_chunk > ${wkdir}/listfile/listfile${wv}_${i}.txt
sbatch ${scripts}/penncnv_pipeline/cnv_calling.sh $wv $i $s_acc

echo -e "\n Done!\n"
sleep 2
