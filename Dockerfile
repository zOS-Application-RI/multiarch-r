FROM ubuntu
SHELL ["/bin/bash", "-c"]
## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get full-upgrade -y \
    && apt-get install -y --no-install-recommends \
    && ln -fs /usr/share/zoneinfo/Asia/Kolkata /etc/localtime \
    && apt-get -y install sudo wget curl locales tzdata 

# USER root
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8 \
    LC_CTYPE=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    CRAN=${CRAN:-https://cran.rstudio.com}


## Setup R
ADD build_r.sh /tmp/
RUN cd /tmp \
    # && wget https://raw.githubusercontent.com/linux-on-ibm-z/scripts/master/R/4.1.1/build_r.sh \
    # && bash build_r.sh -y -j AdoptJDK-OpenJ9 \
    && bash build_r.sh -y  \
    && source /root/setenv.sh

## Setup Time Zone and required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
    libfontconfig1-dev \
    libgit2-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    zlib1g \
    zlib1g-dev \
    libjpeg-dev \
    libicu-dev \
    libpng-dev \
    libreadline-dev \
    libxt-dev \
    libsodium-dev \
    texinfo \
    texlive-extra-utils \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-latex-recommended \
    xauth \
    xfonts-base \
    xvfb 

## Install R Plugins
COPY packages.R /tmp/
RUN Rscript /tmp/packages.R
RUN rm -rf /tmp/* \
    && apt-get autoremove -y \
    && apt-get autoclean -y 

CMD ['R']