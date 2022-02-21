# get the folder path from user
args <- commandArgs(trailingOnly=TRUE)
setwd(args[1])

# Downloads SNPs list from HRC
# only strictly biallelic SNPs, with at least 1 alternate allele count, and only known (no ".")
system(paste0("bcftools view -m2 -M2 -v snps -c10:minor -k -Ou ftp://ngs.sanger.ac.uk/production/hrc/HRC.r1-1/HRC.r1-1.GRCh37.wgs.mac5.sites.vcf.gz | bcftools filter -i 'AF > ", args[2], "' -Oz > hg19_snp_list.vfc.gz"))
system("tabix hg19_snp_list.vfc.gz")

# read VCF
library(VariantAnnotation)
fl <- ("hg19_snp_list.vfc.gz")

# only in chr 11
rng <- GRanges(seqnames="11", ranges=IRanges(start=0, end=10000000000))
vcf <- readVcf(fl, "hg19", ScanVcfParam(which=rng))


gr <- rowRanges(vcf)
dup <- gr[duplicated(gr)]
start(ranges(dup))
gr[IRanges(start=start(ranges(dup)), end = end(ranges(dup)))]
gr[ranges(dup)]

tmp <- GRanges(seqnames="11", ranges=IRanges(start=c(0:10,1), end=c(0:10,1)))
duplicated(tmp)
