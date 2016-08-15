FROM quay.io/refgenomics/docker-scipy-notebook:v0.1.0
MAINTAINER Nick <nick@onecodex.com>

# TODO: Install additional packages wanted here, e.g., bwa, samtools, etc.

# Run as unprivileged user 1000
USER 1000
