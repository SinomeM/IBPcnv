
wkdir=$1
ibpcnv=$2

snp=${wkdir}/snppos.txt
samps=${wkdir}/samples_list.txt

LANG=C

echo "Sorting SNPs list"

tail -n +2 $snp | sort -f -k1 -t '	' > ${snp}.sorted

echo "Submitting jobs"

for i in $( seq 2 $( wc -l $samps | cut -d' ' -f1 ) ); do

  echo $i
  in=$( sed -n "$i"p $samps | cut -f2 )
  out=$( sed -n "$i"p $samps | cut -f4 )
  sbatch $ibpcnv/penncnv_pipeline/05_1_tabix_indexing.sh $in $out $wkdir $ibpcnv

done
