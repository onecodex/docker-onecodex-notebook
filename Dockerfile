# Copyright (c) Reference Genomics, Inc.
# Distributed under the terms of the Modified BSD License.
# Extended from github.com/jupyter/docker-stacks
# See also http://blog.dscpl.com.au/2016/01/roundup-of-docker-issues-when-hosting.html

FROM python:3.6.6-slim-stretch

MAINTAINER Nick Greenfield <nick@onecodex.com>

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    gnupg \
    apt-transport-https \
    sudo \
    locales \
    git \
    vim \
    build-essential \
    python-dev \
    unzip \
    fonts-dejavu \
    gfortran \
    gcc \
    cmake \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.9.0/tini && \
    echo "faafbfb5b079303691a939a747d7f60591f2143164093727e870b289a44d9872 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Configure environment
ENV SHELL /bin/bash
ENV NB_USER jovyan
ENV NB_UID 1000
ENV HOME /home/$NB_USER
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV PATH $HOME/.local/bin:$PATH

# Create jovyan user with UID=1000 and in the root group
# See https://github.com/jupyter/docker-stacks/issues/188
RUN useradd -m -s /bin/bash -N -u $NB_UID -g 0 $NB_USER

# Setup jovyan home directory
RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    mkdir -p -m 770 /home/$NB_USER/.local/share/jupyter && \
    echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/$NB_USER/.curlrc

# Update pip
RUN pip install --upgrade pip

# Numpy must be installed first
RUN pip install numpy==1.15.4

# Install Python 3 packages
RUN pip install \
    awscli==1.16.81 \
    beautifulsoup4==4.6 \
    biopython==1.70 \
    bokeh==0.12 \
    certifi \
    click \
    cloudpickle==0.2.2 \
    cython==0.26 \
    dill==0.2 \
    h5py==2.7.0 \
    ipywidgets==5.2.2 \
    jupyterthemes==0.20.0 \
    jupyter_contrib_nbextensions==0.5.0 \
    pandas==0.20.3 \
    matplotlib==2.0.0 \
    numba==0.34.0 \
    numexpr==2.6.0 \
    patsy==0.4.0 \
# do we need skimage? it's rather large
#    scikit-image==0.13.0 \
    scikit-learn==0.19.0 \
    scipy==0.19.0 \
    seaborn==0.8 \
    selenium==3.141.0 \
    sqlalchemy==1.1.0 \
    statsmodels==0.8.0 \
    sympy==1.1 \
    vincent==0.4.0 \
    weasyprint==0.42.3 \
    xlrd==1.2.0

# Jupyter notebook should have already been installed above, but here we force a particular version
RUN pip install notebook==5.7.4

# Activate ipywidgets extension in the environment that runs the notebook server
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix
RUN jupyter contrib nbextension install --user && \
    jupyter nbextension enable python-markdown/main

WORKDIR /home/$NB_USER/work

# Install nss_wrapper
RUN wget https://ftp.samba.org/pub/cwrap/nss_wrapper-1.1.2.tar.gz && \
    mkdir nss_wrapper && \
    tar -xC nss_wrapper --strip-components=1 -f nss_wrapper-1.1.2.tar.gz && \
    rm nss_wrapper-1.1.2.tar.gz && \
    mkdir nss_wrapper/obj && \
    (cd nss_wrapper/obj && \
        cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DLIB_SUFFIX=64 .. && \
        make && \
        make install) && \
    rm -rf nss_wrapper

# Allows rendering of Vega images in headless chrome browser
RUN curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
RUN apt-get update && apt-get install -yq --no-install-recommends google-chrome-stable chromedriver

# Dependencies for weasyprint
RUN apt-get update && apt-get install -yq --no-install-recommends libffi6 libcairo2 libpango1.0

# Install R and some basic packages
RUN apt-get update && apt-get install -yq --no-install-recommends \
    r-base \
    r-cran-dplyr \
    r-cran-plyr \
    r-cran-ggplot2 \
    r-cran-tidyr \
    r-cran-shiny \
    r-cran-stringr \
    r-cran-rsqlite \
    r-cran-reshape2 \
    r-cran-caret \
    r-cran-rcurl \
    r-cran-crayon \
    r-cran-randomforest \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# This lets us select R from inside the notebook
RUN echo "install.packages(\"IRkernel\", repos=\"https://cran.rstudio.com\")" | R --no-save
RUN echo "IRkernel::installspec()" | R --no-save

# Configure container startup
EXPOSE 8888
COPY notebook/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["jupyter", "notebook"]

# Add assets
RUN mkdir /opt/onecodex/
COPY install/* /opt/onecodex/
RUN chmod +x /opt/onecodex/notebook_report.py && \
    ln -s /opt/onecodex/notebook_report.py /usr/local/bin/notebook_report.py

# Add local files
COPY notebook/jupyter_notebook_config.py /home/$NB_USER/.jupyter/
COPY notebook/token_notebook.py /usr/local/bin/token_notebook.py
RUN chmod +x /usr/local/bin/token_notebook.py

# Install One Codex Python lib
RUN pip install --no-cache onecodex[all]==0.2.14

# Install forked ipyvega that opens links in a new window/tab
# See https://github.com/onecodex/onecodex/issues/137
RUN pip install -U git+https://github.com/onecodex/ipyvega.git@target-blank

# Finally fix permissions on everything
# See https://github.com/jupyter/docker-stacks/issues/188
RUN chown -R $NB_USER:root /home/$NB_USER && chmod -R u+w,g+w /home/$NB_USER

# Switch to unprivileged user, jovyan
USER $NB_USER
