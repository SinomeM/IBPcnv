# README

Scripts to run the PennCNV pipeline using the SLURM job scheduler.

### Steps

1. `01_preprocess.R`, divide the cohort into batches. Create the `snppos.txt` file.
1. `02_select_SNPs.sh`, select SNPs based on the MAF and HWE
2. `03_penncnv_pipeline.sh`, launches the pipeline in each wave, calling `per_wave.sh`.
   Also create the GC content file.
3. `03_1_per_wave.sh`, also creates the PFB file for each wave.
4. `03_2_cnv_calling.sh`, performs the actual jobs submission.
5. `04_combine_results.sh`, create two single `.rawcnv` and `qc` files.

### Additional steps

If the intensity files are in the "complete" format, meaning they contain
a lot of columns (e.g. also "X" and "Y") and, more importantly, a multi-line
header, they need to be preprocessed in order for PennCNV to accept them.   
`../misc/fix_int_files.sh` can be used to run the `split_illumina_report.pl` PennCNV
script using SLURM.

The script `../misc/create_gcmodel.sh` can be used to covert the gc5 file from
genome browser into the format required by PennCNV.
