# Nextflow tutorial working example

This repo displays an example of a workflow with nextflow- including conversion of a GenomeStudio illumina report, basic quality control, and then visualisation of the results

## Workflow structure:
1. Conversion of illumina FinalReport.txt to plink compatible files - Rscript (.lgen/.fam/.map)
2. Basic QC (SNP and sample missingness, HWE, MAF, etc.) - Plink v1.9
3. Visualisation of QC filtering outputs - R 

# 1. Convert illumina Final Report to plink-compatible files (.lgen/.map/.fam)

## Defining parameters: 
Input: FinalReport.txt (GenomeStudio illumina report containing 10 random samples from the study genotype dataset). 
(unzip before use)

Process: Converting illumina final report txt format to lgen format for plink 
Usage in CLI: Rscript illumina_finalreport_to_plink.r --report <report_name>.txt --out <output_file_name>

Output: <output_name>.lgen/.fam/.map  --> to be used as input for basic QC process 

## Rscript for conversion adapted from: 
https://github.com/Broccolito/illumina_finalreport_to_plink

# 2. Basic quality control (QC) of converted plink-compatible files (.lgen/.map/.fam)

## Defining parameters:
Input: FinalReport.lgen/.fam/.map (output from conversion of illumina report to plink format).

Process: Conducting qc (sample/SNP missingness, heterozygosity checks, MAF, HWE, etc.)

Output: FinalReport files passing QC

## Pipeline for QC adapted from:
https://github.com/MareesAT/GWA_tutorial/

# Example of usage on local machine: 
nextflow run <script_name.nf>

## Example of usage on HPC:
nextflow run <script_name.nf> -c nextflow.config -profile slurm
