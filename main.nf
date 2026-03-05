#!/usr/bin/env nextflow

/*
========================================================================================
    IBPcnv - PennCNV Pipeline in Nextflow
========================================================================================
    Based on the published CNV calling protocol: https://doi.org/10.1002/cpz1.621
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl=2

/*
========================================================================================
    PARAMETERS
========================================================================================
*/

params.wkdir          = null
params.samples_list   = "${params.wkdir}/samples_list.txt"
params.batch_size     = 200
params.genome         = 'hg38'  // hg18, hg19, or hg38
params.tabix_folder   = "${params.wkdir}/tabix_output"
params.min_snp        = 5
params.min_bps        = 1000
params.merge_gap      = 0.2

// Validate required parameters
if (!params.wkdir) {
    error "Please provide --wkdir parameter"
}

/*
========================================================================================
    PROCESSES
========================================================================================
*/

process PREPROCESS {
    label 'process_low'
    publishDir "${params.wkdir}", mode: 'copy'
    
    input:
    path samples_list
    val batch_size
    val tabix_folder
    
    output:
    path "samples_list.txt", emit: samples_list_updated
    path "listfile/batch*.txt", emit: batch_files
    path "snppos.txt", emit: snppos
    
    script:
    """
    Rscript ${projectDir}/penncnv_pipeline/01_preprocess.R \\
        ${params.wkdir} \\
        1 \\
        ${batch_size} \\
        ${tabix_folder}
    """
}

process SELECT_SNPS {
    label 'process_medium'
    publishDir "${params.wkdir}", mode: 'copy'
    
    input:
    path snppos
    
    output:
    path "snppos_filtered.txt", emit: snppos_filtered
    
    script:
    """
    Rscript ${projectDir}/penncnv_pipeline/02_select_SNPs.R \\
        ${params.wkdir}
    """
}

process CREATE_GC_MODEL {
    label 'process_low'
    publishDir "${params.wkdir}", mode: 'copy'
    
    input:
    path snppos_filtered
    
    output:
    path "gcmodel.txt", emit: gcmodel
    
    script:
    def gccont = "${projectDir}/gcfile/${params.genome}gc.txt"
    """
    singularity exec ${params.wkdir}/ibpcnv.simg \\
        cal_gc_snp.pl ${gccont} ${snppos_filtered} --output gcmodel.txt
    """
}

process CREATE_PFB {
    label 'process_medium'
    tag "batch${batch_num}"
    publishDir "${params.wkdir}/pfb", mode: 'copy'
    
    input:
    tuple val(batch_num), path(listfile)
    path snppos_filtered
    
    output:
    tuple val(batch_num), path("batch${batch_num}.pfb"), emit: pfb
    
    script:
    """
    singularity exec ${params.wkdir}/ibpcnv.simg \\
        compile_pfb.pl \\
        -snpposfile ${snppos_filtered} \\
        -output batch${batch_num}.pfb \\
        -listfile ${listfile}
    """
}

process SPLIT_BATCH_INTO_CHUNKS {
    tag "batch${batch_num}"
    
    input:
    tuple val(batch_num), path(listfile)
    
    output:
    tuple val(batch_num), path("listfile${batch_num}_*.txt"), emit: chunks
    
    script:
    """
    #!/bin/bash
    n_samples=\$(cat ${listfile} | wc -l)
    n_chunks=\$(( \$n_samples/200 ))
    last_chunk=\$(( \$n_samples%200 ))
    
    for i in \$(seq 1 \$n_chunks); do
        nn=\$(( \$i-1 ))
        nt=\$(( 200*\$nn ))
        if [[ \$nt -gt 0 ]]; then
            let nt++
        fi
        tail ${listfile} -n+\${nt} | head -n 200 > listfile${batch_num}_\${i}.txt
    done
    
    # Last chunk
    if [[ \$last_chunk -gt 0 ]]; then
        let i++
        tail ${listfile} -n \$last_chunk > listfile${batch_num}_\${i}.txt
    fi
    """
}

process CNV_CALLING {
    label 'process_medium'
    tag "batch${batch_num}_chunk${chunk_num}"
    publishDir "${params.wkdir}/calling_res", mode: 'copy'
    
    input:
    tuple val(batch_num), val(chunk_num), path(listfile), path(pfb)
    path gcmodel
    
    output:
    path "wave${batch_num}_${chunk_num}.rawcnv", emit: rawcnv
    path "wave${batch_num}_${chunk_num}_autosome.log", emit: log
    
    script:
    def hmm = "${projectDir}/lib/hhall.hmm"
    """
    singularity exec ${params.wkdir}/ibpcnv.simg \\
        detect_cnv.pl \\
        --test \\
        --hmmfile ${hmm} \\
        --pfbfile ${pfb} \\
        --gcmodelfile ${gcmodel} \\
        --minsnp ${params.min_snp} \\
        --minlength ${params.min_bps} \\
        --confidence \\
        --output wave${batch_num}_${chunk_num}.rawcnv \\
        --logfile wave${batch_num}_${chunk_num}_autosome.log \\
        --listfile ${listfile}
    """
}

process CLEAN_CNV {
    label 'process_low'
    tag "${rawcnv.baseName}"
    publishDir "${params.wkdir}/clean_res", mode: 'copy'
    
    input:
    path rawcnv
    path snppos_filtered
    
    output:
    path "${rawcnv}", emit: cleaned_cnv
    
    script:
    """
    singularity exec ${params.wkdir}/ibpcnv.simg \\
        clean_cnv.pl \\
        --fraction ${params.merge_gap} \\
        --bp \\
        --signalfile ${snppos_filtered} \\
        combineseg ${rawcnv} > ${rawcnv}.cleaned
    
    mv ${rawcnv}.cleaned ${rawcnv}
    """
}

process COMBINE_RESULTS {
    label 'process_high'
    publishDir "${params.wkdir}/results", mode: 'copy'
    
    input:
    path "clean_res/*"
    path "pennlogs/*"
    
    output:
    path "autosome.cnv", emit: combined_cnv
    path "autosome.qc", emit: combined_qc
    
    script:
    """
    bash ${projectDir}/penncnv_pipeline/04_combine_results.sh \\
        ${params.wkdir} \\
        ${projectDir} \\
        ${params.merge_gap}
    """
}

/*
========================================================================================
    WORKFLOW
========================================================================================
*/

workflow {
    // Input channels
    samples_list_ch = Channel.fromPath(params.samples_list, checkIfExists: true)
    
    // Step 1: Preprocess - create batches
    PREPROCESS(
        samples_list_ch,
        params.batch_size,
        params.tabix_folder
    )
    
    // Step 2: Select SNPs based on MAF and HWE
    SELECT_SNPS(
        PREPROCESS.out.snppos
    )
    
    // Step 3: Create GC model
    CREATE_GC_MODEL(
        SELECT_SNPS.out.snppos_filtered
    )
    
    // Prepare batch channel from listfiles
    batch_ch = PREPROCESS.out.batch_files
        .flatten()
        .map { file -> 
            def batch_num = (file.name =~ /batch(\d+)\.txt/)[0][1]
            tuple(batch_num.toInteger(), file)
        }
    
    // Step 4: Create PFB file for each batch
    CREATE_PFB(
        batch_ch,
        SELECT_SNPS.out.snppos_filtered
    )
    
    // Step 5: Split batches into chunks and prepare for CNV calling
    SPLIT_BATCH_INTO_CHUNKS(
        batch_ch
    )
    
    // Combine chunks with their corresponding PFB files
    chunks_with_pfb = SPLIT_BATCH_INTO_CHUNKS.out.chunks
        .transpose()
        .map { batch_num, chunk_file ->
            def chunk_num = (chunk_file.name =~ /listfile\d+_(\d+)\.txt/)[0][1]
            tuple(batch_num, chunk_num.toInteger(), chunk_file)
        }
        .combine(CREATE_PFB.out.pfb, by: 0)
        .map { batch_num, chunk_num, chunk_file, pfb ->
            tuple(batch_num, chunk_num, chunk_file, pfb)
        }
    
    // Step 6: CNV calling
    CNV_CALLING(
        chunks_with_pfb,
        CREATE_GC_MODEL.out.gcmodel
    )
    
    // Step 7: Clean CNVs (soft stitching)
    CLEAN_CNV(
        CNV_CALLING.out.rawcnv,
        SELECT_SNPS.out.snppos_filtered
    )
    
    // Step 8: Combine all results
    COMBINE_RESULTS(
        CLEAN_CNV.out.cleaned_cnv.collect(),
        CNV_CALLING.out.log.collect()
    )
}

/*
========================================================================================
    WORKFLOW COMPLETION
========================================================================================
*/

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'SUCCESS' : 'FAILED' }"
    println "Duration: $workflow.duration"
}
