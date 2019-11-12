#!/bin/bash

CHROME_VERSION=`/opt/google/chrome/chrome --version | cut -d ' ' -f 3`
CHROME_VERSION_MAJOR=`echo $CHROME_VERSION | cut -d '.' -f 1`

CHROMEDRIVER_VERSION=`curl -s https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_VERSION_MAJOR}`

wget https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip \
  && unzip chromedriver_linux64.zip \
  && mv chromedriver /usr/bin/chromedriver \
  && chmod 755 /usr/bin/chromedriver \
  && rm chromedriver_linux64.zip
