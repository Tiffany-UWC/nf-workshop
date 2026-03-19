# Prepare data before use:

## 1. Unzip FinalReport.zip
```{bash}
unzip FinalReport.zip
```

## 2. Download and prepare HGDP-CEPH reference files:
Reference files found here: https://www.cog-genomics.org/plink/2.0/resources
```{bash}
# Move to data/hgdp-ref directory
cd hgdp-ref

# Download files from links.txt file
wget -i hgdp_links.txt

# Unzip the .pgen.zst file(s):
zstd -d hgdp_all.pgen.zst -o hgdp_all.pgen

# Rename hgdp.psam to "hgdp_all.psam" before use
mv hgdp.psam hgdp_all.psam

```
