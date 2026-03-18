#!/usr/bin/env bash

# ============================================================
# Quality control steps for SNP array data, e.g. FinalReport
# Script name: run_plink_qc.sh
# Description: Bash script for running PLINK QC steps
#              Pipeline is structured for final report from illumina (GenomeStudio) to plink lgen format 
# Adaped from: Manuela Tan (https://github.com/huw-morris-lab/snp-array-QC)
# Date: February 2026
# Last updated: 10/02/2026
# ============================================================

MAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RSCRIPT_DIR="${MAIN_DIR}/data/QC_Rscripts"
REFERENCE_DIR="${MAIN_DIR}/data/NGS_Reference/1KG_Reference"

# Start of script
echo "========================================"
echo "Starting PLINK QC pipeline"
echo "========================================"

# ============================================================
# Step 1: Create Plink binary files
# ============================================================

# You should do these QC steps just on the individuals that you are using for your analysis.
# If the dataset contains all individuals from your array data, you should extract only the relevant individuals you need for analysis. 
# Make a tab or separated extract.txt file with the FID and IID of the individuals you want to keep.

echo ""
echo "Step 1: Creating binary files for plink..."

# Define input and output variables
LFILE="FinalReport"
KEEP_FILE="extract.txt"
OUT_PREFIX="Final_Report"

# Extract a subset of individual cases and create binary files for plink
if [ -f "$KEEP_FILE" ]; then
    echo "Extract file found. Subsetting individuals for analysis..."

    plink --lfile "$LFILE" \
          --keep "$KEEP_FILE" \
          --make-bed \
          --out "$OUT_PREFIX"
else
    echo "No extract file found. Using all individuals..."

    plink --lfile "$LFILE" \
          --make-bed \
          --out "$OUT_PREFIX"
fi

echo ""
echo ">>> Step 1 completed: Plink Binary files created."

# ============================================================
# Step 2: QC - sample and SNP filtering
# ============================================================
echo ""
echo "Step 2: PLINK QC - sample and variant filtering..."

# Variant filtering - remove variants with MAF < 1% and genotyping rate < 95%

OUT_PREFIX_GENO_MAF="${OUT_PREFIX}.geno_0.95.maf_0.01"

plink --bfile "${OUT_PREFIX}" \
    --geno 0.05 \
    --maf 0.01 \
    --make-bed \
    --out "${OUT_PREFIX_GENO_MAF}"

# Sample filtering - generate statistics for missingness and heterozygosity

OUT_PREFIX_SAMPLE="${OUT_PREFIX_GENO_MAF}.sampleqc"

plink --bfile "${OUT_PREFIX_GENO_MAF}" \
    --missing \
    --het \
    --out "${OUT_PREFIX_SAMPLE}"

# Plot sample heterozygosity and genotyping rates
# Uses the sampleqc.R script in the /data/QC_Rscripts folder

Rscript --vanilla "${RSCRIPT_DIR}/sampleqc.R" \
        "${OUT_PREFIX_SAMPLE}.imiss" \
        "${OUT_PREFIX_SAMPLE}.het" \
        imiss_het_plot.pdf

# Exclude individuals who do not meet call rate (>98%) or heterozygosity (2SDs away from mean) cutoffs

OUT_PREFIX_SAMPLE_HET_FILT="${OUT_PREFIX_SAMPLE}.sample_0.98.het_2SD"

plink --bfile "${OUT_PREFIX_GENO_MAF}" \
    --remove samples_to_remove.txt \
    --make-bed \
    --out "${OUT_PREFIX_SAMPLE_HET_FILT}"

echo ""
echo ">>> Step 2 completed: Filtered individuals based on call rate & heterozygosity."

# ============================================================
# Step 3: QC - sex checking 
# ============================================================

# Update clincal genders in fam file (if this has not been added in GenomeStudio).
# You need a ClinicalGenders.txt file with FID, IID and clinical sex (1 or M = male, 2 or F = female, 0 = missing).
# If you don't have clinical info, plink will just infer sex from X chromosome data. 

echo ""
echo "Step 3: PLINK QC - checking sex..."

GENDERS="ClinicalGenders.txt"
OUT_PREFIX_UPDATED_SEX="${OUT_PREFIX_SAMPLE_HET_FILT}.updatesex"
OUT_PREFIX_SEXCHECK="${OUT_PREFIX_SAMPLE_HET_FILT}.sexcheck"
OUT_PREFIX_SEX_PASS="${OUT_PREFIX_SAMPLE_HET_FILT}.sexpass"

# If clinical sex exists:
if [ -f "$GENDERS" ]; then
    echo "Clinical gender file found. Updating sex and checking concordance..."

    # Update sex
    plink --bfile "${OUT_PREFIX_SAMPLE_HET_FILT}" \
          --update-sex "$GENDERS" \
          --make-bed \
          --out "${OUT_PREFIX_UPDATED_SEX}"

    # Sex check
    plink --bfile "${OUT_PREFIX_UPDATED_SEX}" \
          --check-sex 0.2 0.7 \
          --out "${OUT_PREFIX_SEXCHECK}"
    # You can check the mismatches by opening the .sexcheck file in text editor. 
    # But if there are a lot of mismatches, there may have been a problem with the genotyping (plate flip, sample mixup)

    # Keep samples that pass sexcheck (FID and IID) or have missing clinical sex (column 3 is 0) 
    awk '($3=="0" || $5=="OK") {print $1 "\t" $2}' \
        "${OUT_PREFIX_SEXCHECK}.sexcheck" > sex_samples_to_keep.txt

    # Remove discordant samples
    plink --bfile "${OUT_PREFIX_UPDATED_SEX}" \
          --keep sex_samples_to_keep.txt \
          --make-bed \
          --out "${OUT_PREFIX_SEX_PASS}"

    FINAL_PREFIX_SEXCHECK="${OUT_PREFIX_SEX_PASS}"

# If no clinical sex available:
# You should still save .sexcheck for reporting / later inspection or updates
else
    echo "No clinical gender file found, performing sex inference only (no samples removed)."

    plink --bfile "${OUT_PREFIX_SAMPLE_HET_FILT}" \
          --check-sex 0.2 0.7 \
          --out "${OUT_PREFIX_SEXCHECK}"

    # Carry forward unchanged dataset
    FINAL_PREFIX_SEXCHECK="${OUT_PREFIX_SAMPLE_HET_FILT}"
fi

echo ""
echo ">>> Step 3 completed: Checked and removed discordant sex samples."
echo ">>> Dataset carried forward: ${FINAL_PREFIX_SEXCHECK}"

# ============================================================
# Step 4: Hardy Weinberg Equilibrium (HWE) filtering
# ============================================================

echo ""
echo "Step 4: PLINK QC - filtering HWE..."

OUT_PREFIX_HWE="${FINAL_PREFIX_SEXCHECK}.hwe"

# Generate a stats file which shows HWE stats for each SNP. 
# This doesn't filter any variants, just makes some new files with the stats.

plink --bfile "${FINAL_PREFIX_SEXCHECK}" \
    --hardy \
    --out "${OUT_PREFIX_HWE}"

# Filter out variants with HWE p value < 0.00001 (you can decide what cutoff you want to use).

plink --bfile "${FINAL_PREFIX_SEXCHECK}" \
    --hwe 0.00001 \
    --make-bed \
    --out "${OUT_PREFIX_HWE}"

echo ""
echo ">>> Step 4 completed: Filtered HWE"

# ============================================================
# Step 5:  Identity-By-Descent (IBD) filtering
# ============================================================

echo ""
echo "Step 5: PLINK QC - filtering by descent..."

# You don't need to do this step if you are doing family-based studies etc.

OUT_PREFIX_IBD="${OUT_PREFIX_HWE}.IBD_0.1"

# First create pruned list of variants (independent SNPs, removed variants that are in linkage) (without restriction on MAF)

plink --bfile "${OUT_PREFIX_HWE}" \
    --indep-pairwise 50 5 0.05 \
    --out Samples.pruned

# Run IBD only on the pruned SNP list - called Samples.pruned.prune.in
# The min 0.1 means that plink will only output pairs of samples that have PI-HAT > 0.1. 
# But you can adjust this if you want to look at samples that are more distantly related

plink --bfile "${OUT_PREFIX_HWE}" \
    --extract Samples.pruned.prune.in \
    --genome \
    --min 0.1 \
    --out Samples.IBD

# Look at your related samples (the Samples.IBD.genome file) in text editor or Excel.
# PI-HAT of 1 indicates that the samples are the same individual or identical twins. PI-HAT of 0.5 indicates parent/child relationship.
# You need to use some judgement here to decide which samples to remove. 
# If a sample is related to lots of other people, this may indicate sample contamination. You can remove one individual from each pair.
# However if one related pair with PI-HAT close to 1 also has very similar sample IDs, this suggests there has been sample mixup and may be removed. 

# Write a list of individuals to remove (FID and IID in IBD_remove.txt file), and remove related individuals (pi-hat > 0.1).

if [ -f IBD_remove.txt ] && [ -s IBD_remove.txt ]; then
    plink --bfile "${OUT_PREFIX_HWE}" \
        --remove IBD_remove.txt \
        --make-bed \
        --out "${OUT_PREFIX_IBD}"
else
    OUT_PREFIX_IBD="${OUT_PREFIX_HWE}"
fi

# End of script
echo "========================================"
echo "Plink QC Pipeline completed successfully"
echo "========================================"
