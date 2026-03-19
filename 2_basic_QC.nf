#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Channel directing the raw data as input
input_ch = Channel.fromPath("${params.input_dir}/${params.input_file}")

process basicQC {
    publishDir "${params.output_dir}"

    input: 
    path(converted_raw)

    output:
    path("${converted_raw.baseName}*") 

    """
    QC_script.sh
    """
}

// Workflows connect channels to processes
workflow {
    basicQC(illuminaToPlink.out)
}
