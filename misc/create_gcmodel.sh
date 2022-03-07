# this script create the CG model file needed by PennCNV GC waviness adjustment
# in the tabix indexing step. It uses the GC content and the snppos files as input.

# Variables
wkdir=${1}
snpposfile=${wkdir}/snppos.txt
gcmodel=${wkdir}/gcmodel.txt
gcfile=${wkdir}/gccontent.txt

singularity exec ${wkdir}/ibpcnv.simg cal_cg_snp.pl ${gcfile} ${snppos} -output ${gcmodel}
