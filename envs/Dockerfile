# syntax=docker/dockerfile:1

# Base image from ubuntu:26.04
FROM ubuntu:26.04

#Metadata (declaring ownership)
LABEL maintainer="4129565@myuwc.ac.za"

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies, incl for conda
RUN apt-get update && apt-get install -y --no-install-recommends \
  wget bzip2 ca-certificates curl git \
  && rm -rf /var/lib/apt/lists/*

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip \
        r-base r-base-dev libcurl4-openssl-dev libxml2-dev libssl-dev \
        wget curl git bzip2 ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install tidyverse in R
RUN R -e "install.packages('tidyverse', repos='https://cloud.r-project.org/')"

# Install PLINK1.9 & PLINK 2 (latest Linux binaries)
RUN wget -q https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20250819.zip /tmp/plink2.zip && \
    unzip /tmp/plink1.zip -d /usr/local/bin/ && \
    rm /tmp/plink1.zip && \
    chmod +x /usr/local/bin/plink

# Install Plink1 & Plink2 (latest Linux binary)
RUN wget -q https://s3.amazonaws.com/plink2-assets/plink2_linux_x86_64_20260311.zip /tmp/plink2.zip && \
    unzip /tmp/plink2.zip -d /usr/local/bin/ && \
    rm /tmp/plink2.zip && \
    chmod +x /usr/local/bin/plink2

# Install EIGENSOFT (smartpca)
RUN wget -q https://github.com/DReichLab/EIG/archive/refs/heads/master.zip -O /tmp/eigensoft.zip && \
    unzip /tmp/eigensoft.zip -d /opt/ && \
    rm /tmp/eigensoft.zip

# Add EIGENSOFT to PATH
ENV PATH="/opt/EIG-master/src:${PATH}"

# Default command
CMD ["/bin/bash"]
