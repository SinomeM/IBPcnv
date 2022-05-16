
require(data.table)

args <- commandArgs(trailingOnly=TRUE)
bs <- args[3]
tf <- args[4]

# read samples list
slistp <- paste0(args[1], "/samples_list.txt")
if (!file.exists(slistp)) stop("Samples list file not found")
slist <- fread(slistp)

if (args[2] == 1) {
  if (!all(c("sample_ID", "file_path") %in% colnames(slist)))
    stop("Wrong columns in samples list file")

  if (any(duplicated(slist[, sample_ID]))) stop("Duplicated samples ID!")

  # test 25% random files
  if (!all(file.exists(sample(slist[, file_path], nrow(slist)*0.25))))
    stop("Some intensity files are missing!")

  # test 100 random files format
  for (f in sample(slist[, file_path], 100)) {
    if(!file.exists(f))
      stop(paste0("Intensity file missing! File: ", f))
    # read only the first 20 lines
    tmp <- fread(cmd = paste0("head ", f, " -n20"), skip = "Name")
    # if some lines are missing they were skipped by fread()
    if (nrow(tmp) < 19)
      stop(paste0("Intensity file in the wrong format. Long header not removed? File: ", f))
    
    # check is 'Sample ID' column is present, if yes check content
    if (`Sample ID` %in% colnames(tmp)) {
      tmp <- fread(f, select = "Sample ID")[, `Sample ID`]
      if (!all(tmp == tmp[1])) stop(paste0("Multiple samples per intensity file! File: ", f))
      
    # check required columns 
    if(!c('Chr', 'Position', 'Log R Ratio', 'B Allele Freq', 'Name') %in% colnames(tmp))
      stop("Essential columns are missing.\n Available ones are: ", colnames(tmp))
    }
  }
}

# check if batches are included or create them
if (!"batch" %in% colnames(slist)) {
  n <- nrow(slist)
  nb <- n %/% bs

  # if the last batch would be too small decrease by one number of batches
  if(n %% bs > 0.75 * bs) nb <- nb - 1

  # because in any case all batches will have same number of samples (max difference is 1)
  tmp <- rep(1:bs, length.out = n)
  batches <- sample(tmp)

  slist[, batch := batches]
}

if ("batch" %in% colnames(slist))
  if (!all(is.integer(slist[, batch])) | is.na(is.integer(slist[, batch])))
    stop("Batch column is in the wrong format!")

slist[, file_path_tabix := paste0(tf, "/", sample_ID, ".tabix")]

# overwrite samples list and write individual batches files
fwrite(slist, args[1], sep = "\t")

lf <- paste0(args[1], "/listfile")
dir.create(lf)

for (i in unique(slist[, batch]))
  fwrite(slist[batch := i, .(file_path)], paste0(lf, "/batch", i,".txt"), col.names = F)

message("Step 1 done! ", i, " batches will be used.")
