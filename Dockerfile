FROM python:3.7-bullseye

# Acknowledgements:
# The following Dockerfile adapted from https://github.com/SeleniumHQ/docker-selenium

# Add sources for apt-get
RUN echo "deb http://deb.debian.org/debian bullseye main\n" > /etc/apt/sources.list \
    && echo "deb-src http://deb.debian.org/debian bullseye main\n" >> /etc/apt/sources.list \
    && echo "deb http://deb.debian.org/debian-security/ bullseye-security main\n" >> /etc/apt/sources.list \
    && echo "deb-src http://deb.debian.org/debian-security/ bullseye-security main\n" >> /etc/apt/sources.list \
    && echo "deb http://deb.debian.org/debian bullseye-updates main\n" >> /etc/apt/sources.list \
    && echo "deb-src http://deb.debian.org/debian bullseye-updates main\n" >> /etc/apt/sources.list

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
RUN apt-get -qqy update \
    && apt-get -qqy --no-install-recommends install \
    acl \
    bzip2 \
    ca-certificates \
    openjdk-11-jre-headless \
    tzdata \
    sudo \
    unzip \
    wget \
    jq \
    curl \
    supervisor \
    gnupg2 \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
    && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-11-openjdk-amd64/conf/security/java.security

# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
ENV TZ "UTC"
RUN echo "${TZ}" > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata

# Firefox
ARG FIREFOX_VERSION=latest
RUN FIREFOX_DOWNLOAD_URL=$(if [ $FIREFOX_VERSION = "latest" ] || [ $FIREFOX_VERSION = "beta-latest" ] || [ $FIREFOX_VERSION = "nightly-latest" ] || [ $FIREFOX_VERSION = "devedition-latest" ] || [ $FIREFOX_VERSION = "esr-latest" ]; then echo "https://download.mozilla.org/?product=firefox-$FIREFOX_VERSION-ssl&os=linux64&lang=en-US"; else echo "https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FIREFOX_VERSION/linux-x86_64/en-US/firefox-$FIREFOX_VERSION.tar.bz2"; fi) \
    && apt-get update -qqy \
    && apt-get -qqy --no-install-recommends install firefox-esr libavcodec-extra \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
    && wget --no-verbose -O /tmp/firefox.tar.bz2 $FIREFOX_DOWNLOAD_URL \
    && apt-get -y purge firefox-esr \
    && rm -rf /opt/firefox \
    && tar -C /opt -xjf /tmp/firefox.tar.bz2 \
    && rm /tmp/firefox.tar.bz2 \
    && mv /opt/firefox /opt/firefox-$FIREFOX_VERSION \
    && ln -fs /opt/firefox-$FIREFOX_VERSION/firefox /usr/bin/firefox

# GeckoDriver
ARG GECKODRIVER_VERSION=latest
RUN GK_VERSION=$(if [ ${GECKODRIVER_VERSION:-latest} = "latest" ]; then echo "0.32.1"; else echo $GECKODRIVER_VERSION; fi) \
    && echo "Using GeckoDriver version: "$GK_VERSION \
    && wget --no-verbose -O /tmp/geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/v$GK_VERSION/geckodriver-v$GK_VERSION-linux64.tar.gz \
    && rm -rf /opt/geckodriver \
    && tar -C /opt -zxf /tmp/geckodriver.tar.gz \
    && rm /tmp/geckodriver.tar.gz \
    && mv /opt/geckodriver /opt/geckodriver-$GK_VERSION \
    && chmod 755 /opt/geckodriver-$GK_VERSION \
    && ln -fs /opt/geckodriver-$GK_VERSION /usr/bin/geckodriver

WORKDIR /python-tdd-book

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

CMD ["sh", "-c", "geckodriver", "--version"]