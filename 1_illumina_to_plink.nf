#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Channel directing the raw data as input
convert_input_ch = Channel.fromPath("${params.input_dir_convert}/${params.input_file_report}")

process illuminaToPlink {
    publishDir "${params.output_dir_convert}", mode: 'copy'

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
    illuminaToPlink(convert_input_ch)
}
