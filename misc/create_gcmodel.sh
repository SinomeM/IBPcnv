# this script create the CG model file needed by PennCNV GC waviness adjustment
# in the tabix indexing step. It uses the GC content and the snppos files as input.

# Variables
wkdir=${1}
gcfile=${2}
snppos=${3}
gcmodel=${4}

singularity exec ${wkdir}/ibpcnv.simg cal_cg_snp.pl ${gcfile} ${snppos} -output ${gcmodel}
