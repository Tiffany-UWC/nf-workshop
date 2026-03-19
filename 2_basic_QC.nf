#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Channel directing the raw data as input
qc_input_ch = Channel.fromPath("${params.output_dir_convert}/${params.input_qc}")

process basicQC {
    publishDir "${params.output_dir_qc}"

    input: 
    path(qc_files)

    output:
    path("${qc_files.baseName}*") 

    """
    QC_script.sh
    """
}

// Workflows connect channels to processes
workflow {
    basicQC(qc_input_ch)
}
