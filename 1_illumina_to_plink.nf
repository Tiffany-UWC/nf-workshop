#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Channel directing the raw data as input
input_ch = Channel.fromPath("${params.input_dir}/${params.input_file}")

process illuminaToPlink {
    publishDir "${params.output_dir}", mode: 'copy'

    input:
    path(file_report)

    output:
    path("${file_report.baseName}*") 
    
    """
    illumina_finalreport_to_plink.R --report ${file_report}
    """
}

// Workflows connect channels to processes
workflow {
    illuminaToPlink(input_ch)
}


