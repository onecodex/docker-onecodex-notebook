# Jupyter Notebooks on One Codex
[![Docker Repository on Quay](https://quay.io/repository/refgenomics/docker-onecodex-notebook/status "Docker Repository on Quay")](https://quay.io/repository/refgenomics/docker-onecodex-notebook)

This repository includes a base Docker image capable of running Jupyter notebooks embedded in the One Codex platform. It generally includes a superset of the packages found in the Jupyter Project's [scipy-notebook](https://github.com/jupyter/docker-stacks/blob/master/scipy-notebook/Dockerfile) and [r-notebook](https://github.com/jupyter/docker-stacks/blob/master/r-notebook/Dockerfile) and supports Python 2, Python 3, and R. See the Dockerfile for additional bioinformatics tools installed by default. [Example notebook](https://app.onecodex.com/notebooks/public/0f5fe71670974b9a) running on One Codex:

[![Example](https://cloud.githubusercontent.com/assets/535969/20200476/47ea2c74-a766-11e6-8d56-700c9475a7d8.png)](https://app.onecodex.com/notebooks/public/0f5fe71670974b9a)

Please feel free to email [support@onecodex.com](mailto:support@onecodex.com) if you have a paid account on One Codex and would like a custom Docker image with additional packages installed.
