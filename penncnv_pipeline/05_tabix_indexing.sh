#!/bin/bash

###SBATCH --account=account_here
#SBATCH --mem=5g
#SBATCH -c 1
#SBATCH --time 00:30:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

in=${1}
out=${2}
wkdir=$3
snpsort=${wkdir}/snppos.txt.sorted

LANG=C

# will produce $in.adjusted
singularity exec ${wkdir}/ibpcnv.simg genomic_wave.pl -adjust --gcmodelfile $wkdir/gcmodel.txt $in
tail -n +2 $in.adjusted | cut -f 1,2 | sort -f -k1 -t '	' > ${in}.adjusted2
tail -n +2 $in | sort -f -k1 -t '	' > ${in}.sorted
join -i -t '	' -1 1 -2 1 $snpsort ${in}.sorted > ${in}.joined
# should be 'Name' 'Chr' 'Position' 'LRR' 'BAF' 'adjLRR'
join -i -t '	' -1 1 -2 1 ${in}.sorted ${in}.adjusted2 > ${in}.joined2

rm ${in}.adjusted
rm ${in}.adjusted2
rm ${in}.sorted
rm ${in}.joined
#rm ${in}.joined2
