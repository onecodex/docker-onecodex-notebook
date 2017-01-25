FROM quay.io/refgenomics/docker-scipy-notebook:v0.1.1
MAINTAINER Nick <nick@onecodex.com>

# Add jessie-backports repository, install bwa 0.7.13 and samtools 1.3.1
USER 0
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/bioinformatics.list \
    && apt-get -y update \
    && apt-get -t jessie-backports install -y "samtools" \
    && apt-get -t jessie-backports install -y "bwa" \
    && apt-get clean
USER 1000

# Update pip
RUN pip2 install --upgrade pip && pip3 install --upgrade pip

# Jupyter notebook extensions
RUN pip3 install jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --user && \
    jupyter nbextension enable python-markdown/main

# Install Python dependencies
RUN pip2 install --no-cache awscli==1.10.58 biopython==1.68 seaborn==0.7.1

# Scikit bio is Py3 only
RUN pip3 install --no-cache awscli==1.10.58 biopython==1.68 seaborn==0.7.1 scikit-bio==0.5.1

# Install One Codex Python lib
RUN pip2 install --no-cache onecodex==0.2.3
RUN pip3 install --no-cache onecodex==0.2.3

# Run as unprivileged user 1000
USER 1000
