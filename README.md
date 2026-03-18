# Nextflow tutorial working example

This repo displays an example of a workflow with nextflow- including conversion of a GenomeStudio illumina report, basic quality control, and then visualisation of the results

## Workflow structure:
1. Conversion of illumina FinalReport.txt to plink compatible files - Rscript (.lgen/.fam/.map)
2. Basic QC (SNP and sample missingness, HWE, MAF, etc.) - Plink v1.9
3. Visualisation of QC filtering outputs - R 

## Example of usage on local machine: 
nextflow run main.nf

## Example of usage on HPC:
module load nextflow
nextflow run main.nf -profile slurm
