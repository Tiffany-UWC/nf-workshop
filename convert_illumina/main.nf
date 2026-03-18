#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Channel directing the raw data as input
input_ch = Channel.fromPath("${params.input_dir}/${params.input_file}")

process illuminaToPlink {
    publishDir "${params.output_dir}"

    input:
    path(file_report)

    output:
    path("${file_report.baseName}*") 
    
    """
    illumina_finalreport_to_plink.R --report ${file_report}
    """
}

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
    illuminaToPlink(input_ch)
    basicQC(illuminaToPlink.out)
}
