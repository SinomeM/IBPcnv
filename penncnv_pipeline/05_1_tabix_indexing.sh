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

tmp=$(echo $out | sed 's/tabix\.gz/tmp/')
cp $in $tmp
in=$tmp

LANG=C

# GC adjustment, will produce $in.adjusted
singularity exec ${wkdir}/ibpcnv.simg genomic_wave.pl -adjust --gcmodelfile $wkdir/gcmodel.txt $in

# sort adjusted on 'Name'
# The `cut` command needs to be changed depending on the intensity files format, it may need to be `cut -f 1,2`
tail -n +2 $in.adjusted | cut -f 1,5 | sort -f -k1 -t '	' > ${in}.adjusted2

# sort unadjusted on 'Name'
tail -n +2 $in | sort -f -k1 -t '	' > ${in}.sorted

if [ $(awk '{print NF}' OFS="\t" $tmp | sort -nu | head -n1) = 5 ]; then
  join -i -t '	' -1 1 -2 1 ${in}.sorted ${in}.adjusted2 | \
    awk '{gsub("XY", 25, $2);gsub("X","23",$2);gsub("Y", "24", $2);gsub("MT", 26, $2);print $2, $3, $3, $5, $4, $6}' OFS='\t' | \
    sort -nk 1 -nk 2 > ${in}.joined2
else
  # join on 'Name' to get 'Chr' and 'Position'
  join -i -t '	' -1 1 -2 1 $snpsort ${in}.sorted > ${in}.joined

  # 'Chr' 'Position' 'LRR' 'BAF' 'adjLRR'
  # also change 'X' to 23, 'Y' to 24 and 'XY' to 25
  join -i -t '	' -1 1 -2 1 ${in}.joined ${in}.adjusted2 | \
    awk '{gsub("XY", 25, $2);gsub("X","23",$2);gsub("Y", "24", $2);gsub("MT", 26, $2);print $2, $3, $3, $4, $5, $6}' OFS='\t' | \
    sort -nk 1 -nk 2 > ${in}.joined2
fi

# gzip
singularity exec ${wkdir}/ibpcnv.simg bgzip ${in}.joined2
mv ${in}.joined2.gz ${out}

#tabix indexing
singularity exec ${wkdir}/ibpcnv.simg tabix -f -p bed ${out}


# delete temp files
rm ${in}.adjusted
rm ${in}.adjusted2
rm ${in}.sorted
rm ${in}.joined
rm $tmp
