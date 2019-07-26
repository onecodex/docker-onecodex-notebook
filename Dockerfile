# Copyright (c) Reference Genomics, Inc.
# Distributed under the terms of the Modified BSD License.
# Extended from github.com/jupyter/docker-stacks
# See also http://blog.dscpl.com.au/2016/01/roundup-of-docker-issues-when-hosting.html

FROM python:3.6.6-slim-stretch

LABEL maintainer="Nick Greenfield <nick@onecodex.com>"

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -yq --no-install-recommends \
    apt-transport-https \
    build-essential \
    bzip2 \
    ca-certificates \
    cmake \
    curl \
    fonts-dejavu \
    gcc \
    gfortran \
    git \
    gnupg \
    locales \
    python-dev \
    sudo \
    unzip \
    vim \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Add Tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini
RUN chmod +x /usr/local/bin/tini \
    && echo "12d20136605531b09a2c2dac02ccee85e1b874eb322ef6baf7561cd93f93c855 /usr/local/bin/tini" | sha256sum -c -

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
    # beautifulsoup4==4.6 \
    biopython==1.72 \
    bokeh==1.0.3 \
    certifi==2018.10.15 \
    click==7.0 \
    # cloudpickle==0.2.2 \
    cython==0.29.2 \
    # dill==0.2 \
    # h5py==2.9.0 \
    ipywidgets==7.4.2 \
    jupyterthemes==0.20.0 \
    jupyter_contrib_nbextensions==0.5.1 \
    matplotlib==3.0.2 \
    numba==0.42.0 \
    numexpr==2.6.9 \
    openpyxl==2.6.1 \
    pandas==0.23.0 \
    # patsy==0.4.0 \
    # scikit-image==0.13.0 \
    scikit-learn==0.19.0 \
    scipy==1.1.0 \
    seaborn==0.9.0 \
    selenium==3.141.0 \
    # sqlalchemy==1.1.0 \
    # statsmodels==0.8.0 \
    # sympy==1.1 \
    # vincent==0.4.0 \
    weasyprint==47 \
    xlrd==1.2.0

# Jupyter notebook should have already been installed above, but here we force a particular version
RUN pip install notebook==5.7.4

# Pin tornado version, as 6.0.0 apparently breaks jupyter notebook
RUN pip install tornado==5.1.1

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
RUN apt-get update && apt-get install -yq --no-install-recommends google-chrome-stable
RUN wget https://chromedriver.storage.googleapis.com/74.0.3729.6/chromedriver_linux64.zip \
    && unzip chromedriver_linux64.zip \
    && mv chromedriver /usr/bin/chromedriver \
    && chmod 755 /usr/bin/chromedriver \
    && rm chromedriver_linux64.zip

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

# Dependencies for weasyprint. Known bugs on libcairo < 1.15.4. Must pull from debian-buster to get 1.16
RUN echo "deb http://deb.debian.org/debian buster main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -yq --no-install-recommends \
    libffi6 \
    libcairo2 \
    libpango1.0.0 \
    fonts-texgyre \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure container startup
EXPOSE 8888
COPY notebook/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["jupyter", "notebook"]

# Add assets
RUN mkdir /opt/onecodex/
# COPY install/* /opt/onecodex/
COPY notebook/notebook.html /usr/local/lib/python3.6/site-packages/notebook/templates
COPY notebook/override.css /usr/local/lib/python3.6/site-packages/notebook/static/notebook/css
COPY notebook/onecodex.js /home/$NB_USER/.jupyter/custom/
COPY notebook/one-codex-spinner.svg /home/$NB_USER/.jupyter/custom/

# Add local files
COPY notebook/jupyter_notebook_config.py /home/$NB_USER/.jupyter/
COPY notebook/token_notebook.py /usr/local/bin/token_notebook.py
RUN chmod +x /usr/local/bin/token_notebook.py

# Add patch to jupyter notebook for export to One Codex document portal
COPY notebook/notebook.patch /usr/local/lib/python3.6/site-packages/notebook
RUN cd /usr/local/lib/python3.6/site-packages/notebook \
    && patch -p0 < notebook.patch

# Install Node and vega-cli for server-side image rendering
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get -y install nodejs
RUN npm install -g --unsafe-perm vega-cli@5.4.0 vega-lite@2.7.0
COPY notebook/vega-cli.patch /usr/lib/node_modules
RUN cd /usr/lib/node_modules && patch -p0 < vega-cli.patch

# Install One Codex Python lib
RUN pip install --no-cache onecodex[all]==0.6.1

# Finally fix permissions on everything
# See https://github.com/jupyter/docker-stacks/issues/188
RUN chown -R $NB_USER:root /home/$NB_USER && chmod -R u+w,g+w /home/$NB_USER

# Switch to unprivileged user, jovyan
USER $NB_USER
