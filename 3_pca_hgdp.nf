#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Channel directing to input data (HGDP reference files)
pca_ch=Channel.fromPath(${params.hgdp_files})

process pca_hgdp {
  publishDir("${params.pca_output}", mode: 'copy'}
  input:
  path hgdp_ref
  path finalreport_qc
  
  output:
  path "*", emit: pca_output

  script:
  """
  pca_hgdp.sh
  """
}

workflow {
  pca_hgdp(pca_ch)
}
