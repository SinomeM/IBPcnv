#!/bin/bash

###SBATCH --account=account_name_here
#SBATCH --mem=20g
#SBATCH -c 1
#SBATCH --time 10:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Variables
wkdir=${1}
scripts=${2} # the location of IBPcnv repo clone
mg=${3}

simg="singularity exec ${wkdir}/ibpcnv.simg"
res=$wkdir/results

# Soft CNV stitching #

echo -e "\nSoft CNV stitching and filtering using PennCNV clean_cnv.pl and filter_cnv.pl"
mkdir -p $wkdir/clean_res

for i in $( ls ${wkdir}/calling_res ); do

  $simg clean_cnv.pl --fraction $mg --bp --signalfile $wkdir/snppos_filtered.txt combineseg ${wkdir}/calling_res/$i > ${wkdir}/clean_res/$i

done


# Extract QC measures from PennCNV log files #
# adapted from Andres scripts

echo -e "\nCombining QC measure in Autosomes"
mkdir -p $res
# rm ${res}/autosome.qc
touch ${res}/autosome.qc

for i in $( ls ${wkdir}/pennlogs | grep autosome ); do

  wv=$( echo $i | sed -E 's|wave||' | sed -E 's|_\d*\w*.log||' )

  cat ${wkdir}/pennlogs/${i} | grep 'quality summary' | \
    awk '{print $5,$6,$7,$8,$9,$10,$11,$12,$13,$14}' | \
    sed 's/.split://g' | sed 's/=/ /g' | \
    awk '{print $1,$3,$5,$7,$9,$11,$13,$15,$17,$19,$21}' | \
    sed "s/$/ ${wv}/" | cat ${res}/autosome.qc - >  ${res}/tmp.qc
  mv ${res}/tmp.qc ${res}/autosome.qc

done

# Add header
cat ${wkdir}/pennlogs/${i} | grep 'quality summary' | \
  awk '{print $5,$6,$7,$8,$9,$10,$11,$12,$13,$14}' | \
  sed 's/.split://g' | sed 's/=/ /g' | \
  awk '{print "sample_ID",$2,$4,$6,$8,$10,$12,$14,$16,$18,$20,"batch"}' | \
  head -1 > ${res}/header.qc

cat ${res}/autosome.qc | cat ${res}/header.qc - > ${res}/tmp.qc

mv ${res}/tmp.qc ${res}/autosome.qc
rm ${res}/header.qc


# Combine CNV calls from all chunks #

echo -e "\nCombining CNV calls in Autosomes"
# rm ${res}/autosome.cnv

echo "chr start stop sample_ID numsnp length type conf batch" > ${res}/autosome.cnv

for i in $( ls ${wkdir}/clean_res | grep -v chrX ); do

  wv=$( echo $i | sed -E 's|wave||' | sed -E 's|_\d*\w*.rawcnv||' )

  cat ${wkdir}/clean_res/$i | awk '{print$1,$2,$3,$4,$5,$8}' | \
    sed 's/:/ /g' | sed 's/-/ /g' |  sed 's/,//g' | \
    sed 's/numsnp=//g' | sed 's/length=//g' | sed 's/conf=//g' | \
    sed 's/.split//g' | sed 's/=/ /g' | awk '{print$1,$2,$3,$8,$4,$5,$7,$9}' | \
    sed "s/$/ ${wv}/" | cat ${res}/autosome.cnv - > ${res}/tmp.cnv
  mv ${res}/tmp.cnv ${res}/autosome.cnv

done

# remove the ':' after samples name
sed -i 's/:\ /\ /g' ${res}/autosome.qc

echo -e "\nAll done!"
