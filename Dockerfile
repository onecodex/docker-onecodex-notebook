# Copyright (c) Reference Genomics, Inc.
# Distributed under the terms of the Modified BSD License.
# Extended from github.com/jupyter/docker-stacks
# See also http://blog.dscpl.com.au/2016/01/roundup-of-docker-issues-when-hosting.html

FROM python:3.9-slim-bullseye

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
    libffi7 \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libcairo2 \
    sudo \
    unzip \
    vim \
    wget \
    fonts-texgyre \
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


ADD requirements.txt /root/
RUN pip install -U pip && \
    pip install -q -r /root/requirements.txt

# Activate ipywidgets extension in the environment that runs the notebook server
RUN jupyter nbextension enable --py widgetsnbextension
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

# Copy `onecodex` installed fonts to local directory
RUN cp /usr/local/lib/python3.9/site-packages/onecodex/assets/fonts/*.otf /usr/local/share/fonts && fc-cache

# Configure container startup
EXPOSE 8888
COPY notebook/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["jupyter", "notebook"]

# Add assets
RUN mkdir /opt/onecodex/
COPY notebook/notebook.html /usr/local/lib/python3.9/site-packages/notebook/templates
COPY notebook/override.css /usr/local/lib/python3.9/site-packages/notebook/static/notebook/css
COPY notebook/onecodex.js /home/$NB_USER/.jupyter/custom/
COPY notebook/one-codex-spinner.svg /home/$NB_USER/.jupyter/custom/
COPY notebook/override.css /home/$NB_USER/.jupyter/custom/custom.css

# Add local files
COPY notebook/jupyter_notebook_config.py /home/$NB_USER/.jupyter/
COPY notebook/token_notebook.py /usr/local/bin/token_notebook.py
COPY notebook/save_message_handler.js /usr/local/share/jupyter/customextensions/
RUN jupyter nbextension install /usr/local/share/jupyter/customextensions/ \
    && jupyter nbextension enable customextensions/save_message_handler
RUN chmod +x /usr/local/bin/token_notebook.py

# Add patch to jupyter notebook for export to One Codex document portal
COPY notebook/notebook.patch /usr/local/lib/python3.9/site-packages/notebook
RUN cd /usr/local/lib/python3.9/site-packages/notebook \
    && patch -p0 < notebook.patch

# Finally fix permissions on everything
# See https://github.com/jupyter/docker-stacks/issues/188
# RUN chown -R $NB_USER:root /home/$NB_USER && chmod -R u+rw,g+rw /home/$NB_USER
RUN chown -R $NB_USER:root /home/$NB_USER && find /home/$NB_USER -type d -exec chmod 775 {} \;

ENV PYTHONPATH "/home/jovyan/.local/lib/python3.9"

# Provide full access to the Python directory to allow for pip installs
RUN chown -R $NB_USER:root /usr/local/lib/python3.9

# Switch to unprivileged user, jovyan
USER $NB_USER
