# Nextflow tutorial working example

This repo is for deploying an example of a workflow with nextflow. 

## Defining parameters: 
Input: FinalReport.txt (GenomeStudio illumine report containing 10 random samples from the VCAMM study genotype dataset). 

Process: Converting illumina final report txt format to lgen format for plink 
Usage in CLI: Rscript illumina_finalreport_to_plink.r --report FinalReport.txt --out <define output file name>

Output: <output name>.lgen/.fam/.map

Rscript adapted from
https://github.com/Broccolito/illumina_finalreport_to_plink

## Usage in Nextflow: 
nextflow run main.nf
