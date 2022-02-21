# get the folder path from user
args <- commandArgs(trailingOnly=TRUE)
setwd(args[1])

# Downloads SNPs list from HRC
# only strictly biallelic SNPs, with at least 1 alternate allele count, and only known (no ".")
system(paste0("bcftools view -m2 -M2 -v snps -c10:minor -k -Ou ftp://ngs.sanger.ac.uk/production/hrc/HRC.r1-1/HRC.r1-1.GRCh37.wgs.mac5.sites.vcf.gz | bcftools filter -i 'AF > ", args[2], "' -Oz > hg19_snp_list.vfc.gz"))
system("tabix hg19_snp_list.vfc.gz")


library(VariantAnnotation); library(data.table)

# create snppos.txt, from the first intensity file
slistp <- paste0 (args[1], "/samples_list.txt")
tmp <- fread (slistp[1, file_path], skip = "Position")[, .(`SNP Name`, chr, Position)]

# read VCF
fl <- ("hg19_snp_list.vfc.gz")
message ("Loading SNPS info into R")
vcf <- rowRanges(readVcf(fl, "hg19"))
vcf <- vcf[names(gr) %in% tmp$` SNP Name`]

# as dt
message ("Filtering SNPS")
dt <- as.data.table( cbind(as.data.frame(ranges (vcf)), as.data.frame(seqnames (vcf))) ) [, .(value, start, names)]
colnames (dt) <- c("chr", "pos", "SNP_ID")

# remove SNPS that map on the same position
dt <- dt[!paste(chr, pos) %in% dt[duplicated (dt[, paste(chr, pos)]), paste(chr, pos)], ]
# remove SNPS with duplicated names
dt <- dt[!SNP_ID %in% dt[duplicated (SNP_ID), SNP_ID], ]

# Write snppos.txt
message ( "Writing snppos.txt file")
dt <- dt[, .(SNP_ID, chr, pos)]
colnames (dt) <- c("SNP Name", "Chr", "Position")
fwrite(dt, paste0(args [1], "/snopos.txt"), sep = "\t")
