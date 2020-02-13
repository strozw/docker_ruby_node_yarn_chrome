ARG RUBY_VERSION=2.4.6

FROM ruby:$RUBY_VERSION

ARG NODE_VERSION=12.14.1
ARG BUNDLER_VERSION=1.17.3
ARG YARN_VERSION=1.22.0
ARG SRC_DIR=/usr/local/src

# addo node.js to source list
# RUN set -x && \
#     curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR_VERSION.x | bash -

# install node.js from archive
RUN set -x && \
    mkdir -p /usr/local/lib/nodejs && \
    wget -N https://nodejs.org/download/release/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz && \
    tar -xJvf node-v$NODE_VERSION-linux-x64.tar.xz -C /usr/local/lib/nodejs && \
    rm node-v$NODE_VERSION-linux-x64.tar.xz

# addo yarn to source list
RUN set -x && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

# get stable version chromedriver
RUN set -x && \
    CHROME_DRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
    wget -N http://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip -P ~/ && \
    unzip ~/chromedriver_linux64.zip -d ~/ && \
    rm ~/chromedriver_linux64.zip && \
    chown root:root ~/chromedriver && \
    chmod 755 ~/chromedriver && \
    mv ~/chromedriver /usr/bin/chromedriver

# add stable chrome to source list
RUN set -x && \
    sh -c 'wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -' && \
    sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

# install dependencies
RUN set -x && \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
      build-essential \
      nodejs \
      yarn=$YARN_VERSION \
      google-chrome-stable \
      fonts-ipa*

# 外部のAptfileで他に必要なものをインストール
# COPY .dockerdev/Aptfile /tmp/Aptfile
# RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends $(cat /tmp/Aptfile | xargs)

# cleanup install logs
RUN set -x && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# setup bundler and PATH
ENV LANG=C.UTF-8
ENV GEM_HOME=/bundle
ENV BUNDLE_JOBS=4
ENV BUNDLE_RETRY=3
ENV BUNDLE_PATH=$GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH
ENV BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH=$SRC_DIR/bin:/usr/local/lib/nodejs/node-v$NODE_VERSION-linux-x64/bin:$BUNDLE_BIN:$PATH

# upgrade ruby gems and install bundler
RUN gem update --system &&\
    gem install bundler:$BUNDLER_VERSION

WORKDIR $SRC_DIR

EXPOSE 3000

CMD /sbin/init
