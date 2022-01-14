
# CHANGE THIS if batches should be larger or smaller #
bs <- 2000


args <- commandArgs(trailingOnly=TRUE)

# read samples list
slistp <- paste0(args[1], "/samples_list.txt")
if (!file.exists(slistp)) error("Samples list file not found")

slist <- fread(args[1])
if (!all(c("sample_ID", "file_path") %in% colnames(slist)))
  error("Wrong columns in samples list file")

if (any(duplicated(slist[, sample_ID]))) error("Duplicated samples ID!")

# test 25% random files
if (!all(file.exists(sample(slist[, file_path], nrow(slist)*0.25))))
  error("Some intensity files are missing!")

# test 100 random files format
for (f in sample(slist[, file_path], 100)) {
  if!(file.exists(f))
    error(paste0("Intensity file missing! File: ", f))
  # read only the first 20 lines
  tmp <- fread(paste0("head ", f, " -n20"), skip = "Position")
  # if some lines are missing they were skipped by fread()
  if (nrow(tmp) < 19)
    error(paste0("Intensity file in the wrong format. Long header not removed? File: ", f))
  # check is 'Sample ID' column is present, if yes check content
  if (`Sample ID` %in% colnames(tmp)) {
    tmp <- fread(f, select = "Sample ID")[, `Sample ID`]
    if (!all(tmp == tmp[1])) error(paste0("Multiple samples per intensity file! File: ", f))
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

# overwrite samples list and write individual batches files
fwrite(slist, args[1], sep = "\t")

lf <- paste0(args[1], "/listfile")
dir.create(lf)

for (i in unique(slist[, batch]))
  fwrite(slist[batch := i, .(file_path)], paste0(lf, "/batch", i,".txt"), col.names = F)

