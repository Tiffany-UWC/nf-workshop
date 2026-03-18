#!/usr/bin/env Rscript

options(
  warn = 2,
  error = function() {
    cat("\n!!! finalreport_to_plink FAILED !!!\n", file = stderr())
    cat(geterrmessage(), file = stderr())
    cat("\nTraceback:\n", file = stderr())
    traceback(2)
    quit(status = 1)
  }
)

# finalreport_to_plink.R
# Convert Illumina FinalReport to PLINK .lgen/.map/.fam
# Version: 2.0 
# Date: 2026-03-02
# Adapted from: https://github.com/Broccolito/illumina_finalreport_to_plink
# Usage with custom out prefix: Rscript finalreport_to_plink.R --report FinalReport.txt --out Final_Report

# ---- Install and load packages ----
suppressPackageStartupMessages({
  if (!requireNamespace("data.table", quietly = TRUE))
    install.packages("data.table", repos="https://cloud.r-project.org")
  library(data.table)
})

# ---- Parse CLI arguments ----
parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  get_arg <- function(flag, default = NULL) {
    idx <- which(args == flag)
    if (length(idx) == 1 && length(args) >= idx + 1)
      return(args[idx + 1])
    return(default)
  }

  list(
    report = get_arg("--report"),
    fam    = get_arg("--fam", NULL),
    out    = get_arg("--out", NULL)
  )
}

args <- parse_args()

if (is.null(args$report)) {
  stop("ERROR: --report FinalReport.txt required", call. = FALSE)
}

report_file <- args$report

if (!file.exists(report_file))
  stop("ERROR: Report file not found: ", report_file, call. = FALSE)

prefix <- ifelse(is.null(args$out),
                 sub("\\.txt$", "", basename(report_file)),
                 args$out)

fam_file <- args$fam

cat("=== finalreport_to_plink ===\n")
cat("Report:", report_file, "\n")
cat("Output prefix:", prefix, "\n")

# ---------------- READ REPORT ----------------
read_report <- function(file) {
  cat("Loading report...\n")

  dt <- fread(file, skip = 9)

  expected_cols <- c(
    "snp_name","sample_id","chr","pos",
    "allele1","allele2","gc_score"
  )                                        #update according to columns present in your FinalReport file

  if (ncol(dt) < length(expected_cols))
    stop("ERROR: Unexpected FinalReport format")

  setnames(dt, expected_cols)
  return(dt)
}

# ---------------- CLEAN REPORT ----------------
clean_report <- function(dt) {

  valid_alleles <- c("A","C","G","T")

  dt <- dt[
    allele1 %in% valid_alleles &
    allele2 %in% valid_alleles
  ]

  dt[, chr := ifelse(chr %in% c(as.character(1:22),"X","Y","MT"), chr, "0")]
  dt[, fid := sample_id]
  dt[, empty := "0"]

  # remove multiallelic SNPs
  allele_counts <- dt[, .(
    num_alleles = length(unique(c(allele1, allele2)))
  ), by = snp_name]

  bad_snps <- allele_counts[num_alleles > 2, snp_name]
  dt <- dt[!snp_name %in% bad_snps]

  return(dt)
}

# ---------------- FAM HANDLING ----------------
create_default_fam <- function(sample_ids) {
  data.table(
    fid = sample_ids,
    sample_id = sample_ids,
    father_id = 0,
    mother_id = 0,
    sex = 0,
    phenotype = -9
  )
}

load_or_create_fam <- function(fam_file, sample_ids) {

  if (!is.null(fam_file) && file.exists(fam_file)) {
    cat("Using provided FAM file:", fam_file, "\n")
    fam <- fread(fam_file, header = FALSE)

    if (ncol(fam) < 6) {
      warning("FAM file malformed → creating default")
      fam <- create_default_fam(sample_ids)
    }

  } else {
    if (!is.null(fam_file))
      warning("FAM file not found → creating default")

    cat("Creating default FAM from sample IDs\n")
    fam <- create_default_fam(sample_ids)
  }

  return(fam)
}

# ---------------- WRITE PLINK ----------------
write_plink <- function(dt, prefix, fam) {

  cat("Writing PLINK files...\n")

  map <- unique(dt[, .(chr, snp_name, empty, pos)])
  setorder(map, chr, pos)

  lgen <- unique(dt[, .(fid, sample_id, snp_name, allele1, allele2)])
  setorder(lgen, sample_id, snp_name)

  fwrite(map, paste0(prefix, ".map"),
         sep="\t", col.names=FALSE)

  fwrite(lgen, paste0(prefix, ".lgen"),
         sep="\t", col.names=FALSE)

  fwrite(fam, paste0(prefix, ".fam"),
         sep="\t", col.names=FALSE)
}

# ---------------- PIPELINE ----------------
dt <- read_report(report_file)
dt <- clean_report(dt)

samples <- sort(unique(dt$sample_id))
fam <- load_or_create_fam(fam_file, samples)

write_plink(dt, prefix, fam)

cat("Conversion completed! \n")

#####################################################
