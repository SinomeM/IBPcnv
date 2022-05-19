
wkdir=$1
ibpcnv=$2

$snp=${wkdir}/snppos.txt
$samps=${wkdir}/samples_list.txt

LANG=C

tail -n +2 $snp | sort -f -k1 -t '	' > ${snp}.sorted

for i in ...
  bash $ibp/penncnvpipeline/05_1_tabix_indexing.sh INPUT OUTPUT $wkdir $ibpcnv
done
