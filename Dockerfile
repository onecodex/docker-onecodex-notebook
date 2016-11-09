FROM quay.io/refgenomics/docker-scipy-notebook:v0.1.0
MAINTAINER Nick <nick@onecodex.com>

# Add jessie-backports repository, install bwa 0.7.13 and samtools 1.3.1
USER 0
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/bioinformatics.list \
    && apt-get -y update \
    && apt-get -t jessie-backports install -y "samtools" \
    && apt-get -t jessie-backports install -y "bwa" \
    && apt-get clean
USER 1000

# Install Python dependencies
RUN pip2 install --no-cache awscli==1.10.58 biopython==1.68 seaborn==0.7.1
RUN pip3 install --no-cache awscli==1.10.58 biopython==1.68 seaborn==0.7.1

# Run as unprivileged user 1000
USER 1000