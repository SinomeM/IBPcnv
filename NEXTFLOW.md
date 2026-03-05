# Nextflow Integration Guide

This document explains how to use the Nextflow version of the IBPcnv pipeline.

## Prerequisites

1. **Nextflow** (>= 21.10.3)
   ```bash
   curl -s https://get.nextflow.io | bash
   # Move to a directory in your PATH
   sudo mv nextflow /usr/local/bin/
   ```

2. **Singularity** (already in use with your current pipeline)

3. **Your PennCNV Singularity container** (`ibpcnv.simg`) in your working directory

## Quick Start

### Basic Usage

```bash
nextflow run main.nf \
  --wkdir /path/to/working/directory \
  --genome hg38 \
  -profile slurm,singularity
```

### With SLURM Account

Edit [nextflow.config](nextflow.config#L45) and uncomment/set your SLURM account:
```groovy
clusterOptions = '--account=your_account'
```

Or pass it at runtime:
```bash
nextflow run main.nf \
  --wkdir /path/to/working/directory \
  --genome hg38 \
  -profile slurm,singularity \
  -process.clusterOptions '--account=your_account'
```

### Resume Failed Runs

One of the biggest advantages of Nextflow - simply add `-resume`:
```bash
nextflow run main.nf \
  --wkdir /path/to/working/directory \
  --genome hg38 \
  -profile slurm,singularity \
  -resume
```

## Parameters

### Required
- `--wkdir`: Working directory containing your data

### Optional
- `--genome`: Reference genome (default: `hg38`, options: `hg18`, `hg19`, `hg38`)
- `--batch_size`: Number of samples per batch (default: `200`)
- `--min_snp`: Minimum SNPs per CNV call (default: `5`)
- `--min_bps`: Minimum base pairs per CNV (default: `1000`)
- `--merge_gap`: Gap fraction for soft CNV stitching (default: `0.2`)

### Example with Custom Parameters
```bash
nextflow run main.nf \
  --wkdir /scratch/my_project \
  --genome hg19 \
  --batch_size 150 \
  --min_snp 10 \
  --min_bps 5000 \
  -profile slurm,singularity
```

## Profiles

Available execution profiles:

- **`slurm`**: Use SLURM job scheduler
- **`singularity`**: Enable Singularity containers
- **`standard`**: SLURM + Singularity (recommended for production)
- **`local`**: Run locally without job scheduler (for testing small datasets)
- **`test`**: Reduced resources for testing
- **`debug`**: Extra debugging information

Combine profiles with commas: `-profile slurm,singularity`

## Advantages Over Bash Scripts

### 1. **Automatic Dependency Management**
No more manual `sleep` commands or checking if previous jobs finished. Nextflow handles all dependencies automatically.

### 2. **Resume Failed Jobs**
If a job fails, fix the issue and run with `-resume`. Only failed tasks will re-run, not the entire pipeline.

### 3. **Better Parallelization**
Channel-based parallelization is automatic and more efficient than nested bash loops with sbatch.

### 4. **Built-in Reporting**
Automatic generation of:
- Execution timeline (`pipeline_info/execution_timeline.html`)
- Execution report (`pipeline_info/execution_report.html`)
- Execution trace (`pipeline_info/execution_trace.txt`)
- DAG visualization (`pipeline_info/pipeline_dag.svg`)

### 5. **Portable & Reproducible**
Same pipeline works on different HPC systems with minimal configuration changes.

## File Structure

Your project now has:
```
IBPcnv/
├── main.nf                          # Main workflow definition
├── nextflow.config                  # Global configuration
├── conf/
│   └── base.config                 # Process-specific resources
├── penncnv_pipeline/               # Original R and bash scripts (still used)
│   ├── 01_preprocess.R
│   ├── 02_select_SNPs.R
│   └── 04_combine_results.sh
├── gcfile/                         # GC content files
├── lib/                            # HMM files
└── NEXTFLOW.md                     # This file
```

## Monitoring Jobs

### View Running Workflow
```bash
# In another terminal
tail -f .nextflow.log
```

### Check SLURM Queue
```bash
squeue -u $USER
```

### View Pipeline Reports
After completion, open the HTML reports in `pipeline_info/`:
- Timeline shows when each process ran
- Report shows resource usage
- DAG shows workflow structure

## Troubleshooting

### Pipeline Fails Early
Check `.nextflow.log` for errors:
```bash
tail -100 .nextflow.log
```

### Individual Process Fails
Check the work directory printed in error:
```bash
cat work/a1/b2c3d4.../task.sh      # The command that was run
cat work/a1/b2c3d4.../.command.log  # Process output
cat work/a1/b2c3d4.../.command.err  # Error messages
```

### Resource Issues
Adjust resources in [conf/base.config](conf/base.config) for specific processes.

### Clean Up Work Directory
After successful completion:
```bash
# Remove intermediate files (be careful!)
rm -rf work/
# Keep only if you might need to resume
```

## Migration from Bash Scripts

The Nextflow pipeline replaces:
- `03_penncnv_pipeline.sh` - Now handled by the main workflow
- `03_1_per_wave.sh` - Now the `CREATE_PFB` and `SPLIT_BATCH_INTO_CHUNKS` processes
- `03_2_cnv_calling.sh` - Now the `CNV_CALLING` process

The R scripts (`01_preprocess.R`, `02_select_SNPs.R`) and the combine script (`04_combine_results.sh`) are still used but called automatically by Nextflow.

## Next Steps

1. **Test on a small dataset** with `-profile test,local`
2. **Set your SLURM account** in `nextflow.config`
3. **Adjust resource requirements** in `conf/base.config` if needed
4. **Run on full dataset** with `-profile slurm,singularity`
5. **Check the pipeline reports** to optimize resource allocation

## Getting Help

- Nextflow documentation: https://www.nextflow.io/docs/latest/
- Nextflow patterns: https://nextflow-io.github.io/patterns/
- IBPcnv protocol: https://doi.org/10.1002/cpz1.621
