# get the folder path from user
args <- commandArgs(trailingOnly=TRUE)
setwd(args[1])

# Downloads SNPs list from HRC
# only strictly biallelic SNPs, with at least 1 alternate allele count, and only known (no ".")
if (args[3] == "hg19") {
  if (!file.exists("hg19_snp_list.vcf.gz")) {
    message("\nDownloading HRC VCF")
    system(paste0("bcftools view -m2 -M2 -v snps -c10:minor -k -Ou ftp://ngs.sanger.ac.uk/production/hrc/HRC.r1-1/HRC.r1-1.GRCh37.wgs.mac5.sites.vcf.gz | bcftools filter -i 'AF > ", args[2], "' -Oz > hg19_snp_list.vcf.gz"))
  }
}

if (!file.exists(paste0(args[3], "_snp_list.vcf.gz.tbi")))
  system(paste0("tabix ", args[3], "_snp_list.vcf.gz"))

suppressMessages(suppressWarnings(library(VariantAnnotation,warn.conflicts = F, quietly = T)))
suppressMessages(suppressWarnings(library(data.table,warn.conflicts = F, quietly = T)))

tmp <- fread("snppos.txt")
# if there are more columns, drop them for later
if (length(colnames(tmp)) > 3) fwrite(tmp[, .(Name, Chr, Postion)], "snppos.txt", sep = "\t")

# Read VCF
fl <- (paste0(args[3], "_snp_list.vcf.gz"))
message ("Loading SNPS info into R")
vcf <- rowRanges(readVcf(fl, args[3]))
dt <- as.data.table( cbind(as.data.frame(ranges (vcf)), as.data.frame(seqnames (vcf))) ) [, .(value, start, names)]
colnames (dt) <- c("chr", "pos", "SNP_ID")

# Filter Markers
message ("Filtering SNPS")
# selct SNPs on the array
dt <- dt[paste0(chr, pos) %in% tmp[, paste0(Chr, Position)], ]

if (args[4]) {
  # remove SNPS that map on the same position
  dt <- dt[!paste(chr, pos) %in% dt[duplicated (dt[, paste(chr, pos)]), paste(chr, pos)], ]
  # remove SNPS with duplicated names
  dt <- dt[!SNP_ID %in% dt[duplicated (SNP_ID), SNP_ID], ]
} else message("Skipping duplicated SNPs filtering")

# Write snppos.txt
dt <- dt[, .(SNP_ID, chr, pos)]
colnames (dt) <- c("Name", "Chr", "Position")
fwrite(dt, paste0(args [1], "/snppos_filtered.txt"), sep = "\t")
