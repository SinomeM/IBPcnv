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

# GC adjustment, will produce $in.adjusted
singularity exec ${wkdir}/ibpcnv.simg genomic_wave.pl -adjust --gcmodelfile $wkdir/gcmodel.txt $in

# sort adjuste on 'Name'
tail -n +2 $in.adjusted | cut -f 1,2 | sort -f -k1 -t '	' > ${in}.adjusted2

# sort unadjusted on 'Name'
tail -n +2 $in | sort -f -k1 -t '	' > ${in}.sorted

# join on 'Name' to get 'Chr' and 'Position'
join -i -t '	' -1 1 -2 1 $snpsort ${in}.sorted > ${in}.joined

# 'Chr' 'Position' 'LRR' 'BAF' 'adjLRR'
# also change 'X' to 23, 'Y' to 24 and 'XY' to 25
join -i -t '	' -1 1 -2 1 ${in}.joined ${in}.adjusted2 | \
  awk '{gsub("XY", 25, $2);gsub("X","23",$2);gsub("Y", "24", $2);gsub("MT", 26, $2);print $2, $3, $3, $4, $5, $6}' OFS='\t' | \
  sort -nk 1 -nk 2 > ${in}.joined2

# gzip
bgzip ${in}.joined2 && mv ${in}.joined2.gz ${out}

#tabix indexing
singularity exec ${wkdir}/ibpcnv.simg tabix -f -p bed ${out}


# delete temp files
rm ${in}.adjusted
rm ${in}.adjusted2
rm ${in}.sorted
rm ${in}.joined
