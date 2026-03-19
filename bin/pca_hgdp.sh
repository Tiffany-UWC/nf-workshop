#!/usr/bin/env bash
set -euo pipefail

# =============================================++++++++++++++++++++++++++++++++++++++===============
# PCA with HGDP Reference (PLINK)
# Script name: pca_hgdp.sh
# Description: Bash script for performing principal component analysis (PCA) in PLINKV1.9/V2 
#              On study samples (Final_Report) merged with the Human Genome Diversity Project (HGDP)
#              To infer population structure, visualize ancestry clusters, and detect outliers.
# Adaped from: https://github.com/huw-morris-lab/snp-array-QC
# Date: March 2026
# Last updated: 19/03/2026
# ========================================++++++++++++++++++++++++++++++++++++++====================

# Start of script
echo "========================================"
echo "Starting PLINK PCA pipeline"
echo "========================================"

# Define input and output variables
INFILE_SAMPLE="Final_Report"
INFILE_REF="hgdp_all"
OUTFILE_AFR="hgdp_AFR"

# Step 1: Create a Plink --keep file with FID and IID
awk '$6=="AFRICA" {print $1, $1}' "${INFILE_REF}.psam" > AFR_samples.txt

# Step 2: Extract AFR sampled with Plink2:
plink2 --pfile 'vzs' ${INFILE_REF} --keep AFR_samples.txt --make-bed --out ${OUTFILE_AFR}

# Step 3: Basic quality control (QC):
# Cleaned up the dataset (HWE & MAF filtering, recode the variant IDs to avoid duplicate ID issues)

QC_OUTREF="${OUTFILE_AFR}.qc"

plink2 --pfile 'vzs' ${OUTFILE_AFR} --make-pgen --autosome --snps-only --hwe 0.5 --maf 0.05 --set-all-var-ids @:#\$r,\$a --out ${QC_OUTREF} 

# Step 4: estimate linkage disequilibrium (LD) & create LD-pruned dataset

LD_OUTREF="${QC_OUTREF}.ld"

plink2 --pfile 'vzs' ${QC_OUTREF} --indep-pairphase 100 0.8 --out ${QC_OUTREF}

# Then extract pruned SNPs:
plink2 --pfile 'vzs' ${QC_OUTREF} --make-pgen --extract "${QC_OUTREF}.prune.in" --out ${LD_OUTREF}

# Step 5: compute reference-only PCs 

PCA_OUTREF="${LD_OUTREF}.pca.ref_only"

plink2 --pfile 'vzs' ${LD_OUTREF} --freq counts --keep-founders --pca biallelic-var-wts --out ${PCA_OUTREF}

# Step 6: plot the REF-only individuals using R

#A<-gen_popstrat_A('${PCA_OUTREF}')
#popstrat_plot2d(A,c("PC1","PC2"))



# End of script
echo "========================================"
echo "Plink PCA completed successfully"
echo "========================================"

