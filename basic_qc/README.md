# Basic quality control (QC) of converted plink-compatible files (.lgen/.map/.fam)

## Defining parameters:
Input: FinalReport.lgen/.fam/.map (output from conversion of illumina report to plink format).

Process: Conducting qc (sample/SNP missingness, heterozygosity checks, MAF, HWE, etc.)

Output: FinalReport files passing QC

## Pipeline for QC adapted from:
Tan, 2020 (https://github.com/huw-morris-lab/snp-array-QC)
