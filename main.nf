#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Import sub-workflows to main workflow

include { convert_workflow }        from './1_illumina_to_plink.nf'
include { basicqc_workflow }        from './2_basic_QC.nf'
include { pca_hgdp_workflow }       from './3_pca_hgdp.nf'
// to include later: include { vis_workflow }            from './visualise_outputs.nf'

// Channels direct inputs to processes
convert_input_ch = Channel.fromPath(params.input_file_report)
hgdp_ref_ch = Channel.fromPath(params.hgdp_ref)   // HGDP reference dataset

workflow {

    // Step 1: Convert illumina FinalReport.txt to Plink compatable files
    output_convert_ch = convert_workflow(convert_input_ch, checkIfExists: true), emit: convert_out

    // Step 2: Basic QC on converted plink files 
    basic_qc_ch = basicqc_workflow(output_convert_ch, checkIfExists: true), emit: basic_qc_out

    // Step 3: Population structure analysis (PCA)
    pca_ch = pca_hgdp_workflow(basic_qc_ch, hgdp_ref_ch, checkIfExists: true), emit: pca_out

}
