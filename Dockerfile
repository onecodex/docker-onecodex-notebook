FROM quay.io/refgenomics/docker-scipy-notebook:v0.1.4
MAINTAINER Nick <nick@onecodex.com>

# Add jessie-backports repository, install bwa 0.7.13 and samtools 1.3.1
USER 0
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/bioinformatics.list \
    && apt-get -y update \
    && apt-get -t jessie-backports install -y "samtools" \
    && apt-get -t jessie-backports install -y "bwa" \
    && apt-get clean

# Add assets
RUN mkdir /opt/onecodex/
ADD install/* /opt/onecodex/
RUN chmod +x /opt/onecodex/notebook_report.py && \
    ln -s /opt/onecodex/notebook_report.py /usr/local/bin/notebook_report.py

USER 1000

# Update pip
RUN pip install --upgrade pip

# Jupyter notebook extensions
RUN pip install jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --user && \
    jupyter nbextension enable python-markdown/main

# Install Python dependencies (Python 3 only)
RUN pip install --no-cache awscli==1.10.58

# Install One Codex Python lib
RUN pip install --no-cache onecodex[all]==0.2.7

# Run as unprivileged user 1000
USER 1000
