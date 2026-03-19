#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Quality control steps for SNP array data, e.g. FinalReport
# Script name: QC_script.sh
# Description: Bash script for running PLINK QC steps
#              Pipeline is structured for final report from illumina (GenomeStudio) to plink lgen format 
# Adaped from: https://github.com/MareesAT/GWA_tutorial/
# Date: February 2026
# Last updated: 19/03/2026
# ============================================================

# Start of script
echo "========================================"
echo "Starting PLINK QC pipeline"
echo "========================================"

# ============================================================
# Step 0: Convert lgen/map to Plink binary files
# ============================================================

# Define input and output variables
LFILE="FinalReport"
OUT_PREFIX="Final_Report"

plink --lfile ${LFILE} --make-bed --out ${OUT_PREFIX}

echo ""
echo ">>> Step 0 completed: Plink Binary files created."

# ============================================================
# Step 1: QC - missingness checks
# ============================================================

MISSING_PREFIX="${OUT_PREFIX}.missing"

plink --bfile ${OUT_PREFIX} --missing --out ${MISSING_PREFIX}

# Check individual & SNP-level missingness
awk '$6 > 0.05' ${MISSING_PREFIX}.imiss > fail_missing_individuals.txt
awk '$5 > 0.05' ${MISSING_PREFIX}.lmiss > fail_missing_snps.txt

echo ""
echo ">>> Step 1 completed: Checked individual and SNP missingness."

# ============================================================
# Step 2: QC - check for sex discrepancy
# ============================================================

SEX_CHECK_PREFIX="${OUT_PREFIX}.sexcheck"

plink --bfile ${OUT_PREFIX} --check-sex 0.2 0.7 --out ${SEX_CHECK_PREFIX}

# Keep samples that pass sexcheck (FID and IID) or have missing clinical sex (column 3 is 0) 
grep "PROBLEM" ${SEX_CHECK_PREFIX}.sexcheck| awk '($3=="0" || $5=="OK") {print$1,$2}'> sex_discrepancy.txt

echo ""
echo ">>> Step 2 completed: Checked sex discrepancy."

# ============================================================
# Step 3: QC - Investigate SNPs with a low MAF
# ============================================================

MAF_PREFIX="${OUT_PREFIX}.freq"

plink --bfile ${OUT_PREFIX} --freq --out ${MAF_PREFIX}

#Check MAFs with:
awk '$5 < 0.01' ${MAF_PREFIX}.frq > low_maf_snps.txt

echo ""
echo ">>> Step 3 completed: Investigated low MAF."

# ============================================================
# Step 4: QC - Hardy Weinberg Equilibrium (HWE) filtering
# ============================================================

HWE_PREFIX="${OUT_PREFIX}.hwe"

# Generate a stats file which shows HWE stats for each SNP. 
# This doesn't filter any variants, just makes some new files with the stats.

plink --bfile ${OUT_PREFIX} --hardy --out ${HWE_PREFIX}

# Extract a stringent HWE threshold.
awk '$9 < 1e-6' ${HWE_PREFIX}.hwe > hwe_fail_snps.txt

echo ""
echo ">>> Step 4 completed: Filtered HWE"

# ============================================================
# Step 5: QC - identify excess heterozygosity
# ============================================================

INDEP_PREFIX="${OUT_PREFIX}.indepSNP"

# write marker lists for pruning heterozygous SNPs (save this for pca)
plink --bfile ${OUT_PREFIX} --indep-pairwise 50 5 0.2 --out ${INDEP_PREFIX}

echo ""
echo ">>> Step 5 completed: Checked for excess heterozygosity."

# ============================================================
# Step 6: Apply all QC filters
# ============================================================

QC_OUT_PREFIX="${OUT_PREFIX}.qc"

plink --bfile ${OUT_PREFIX} \
  --remove fail_missing_individuals.txt \
  --exclude fail_missing_snps.txt \
  --maf 0.05 \
  --hwe 1e-6 \
  --geno 0.5 \
  --make-bed \
  --out ${QC_OUT_PREFIX}

echo ""
echo ">>> Step 6 completed: Applied all QC filters."

# ============================================================
# Step 7: PCA from QC data (no reference panels)
# ============================================================

PCA_PREFIX="${QC_OUT_PREFIX}.pca.no-ref"

plink --bfile ${QC_OUT_PREFIX} --pca --out ${PCA_PREFIX}

echo ""
echo ">>> Step 7 completed: PCA on cleaned files."

# End of script
echo "========================================"
echo "Plink QC completed successfully on ${LFILE}"
echo "========================================"
