# Convert illumina Final Report to plink-compatible files (.lgen/.map/.fam)

## Defining parameters: 
Input: FinalReport.txt (GenomeStudio illumina report containing 10 random samples from the study genotype dataset). 

Process: Converting illumina final report txt format to lgen format for plink 
Usage in CLI: Rscript illumina_finalreport_to_plink.r --report <report_name>.txt --out <output_file_name>

Output: <output_name>.lgen/.fam/.map  --> to be used as input for basic QC process 

## Rscript for conversion adapted from: 
https://github.com/Broccolito/illumina_finalreport_to_plink
























