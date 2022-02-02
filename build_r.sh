#!/bin/bash
# © Copyright IBM Corporation 2021.
# LICENSE: Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)
#
# Instructions:
# Download build script: wget https://raw.githubusercontent.com/linux-on-ibm-z/scripts/master/R/4.1.2/build_r.sh
# Execute build script: bash build_r.sh    (provide -h for help)
#

set -e -o pipefail
shopt -s extglob

PACKAGE_NAME="R"
PACKAGE_VERSION="4.1.2"
CURDIR="$(pwd)"
JAVA_PROVIDED="OpenJDK"
FORCE="false"
TESTS="false"

LOG_FILE="$CURDIR/logs/${PACKAGE_NAME}-${PACKAGE_VERSION}-$(date +"%F-%T").log"

R_URL="https://cran.r-project.org/src/base/R-4"
R_URL+="/R-${PACKAGE_VERSION}.tar.gz"

BUILD_ENV="$HOME/setenv.sh"

# Check CPU Arch
        case $(uname -m) in
        s390x ) export archt=s390x
        ;;
        x86_64 ) export archt=x64
        ;;
        ppc64le ) export archt=ppc64le
        ;;
        esac

trap cleanup 0 1 2 ERR

#Check if directory exsists
if [ ! -d "$CURDIR/logs" ]; then
        mkdir -p "$CURDIR/logs"
fi

if [ -f "/etc/os-release" ]; then
        source "/etc/os-release"
fi

DISTRO="$ID-$VERSION_ID"

function checkPrequisites() {
        if command -v "sudo" >/dev/null; then
                printf -- 'Sudo : Yes\n' >>"$LOG_FILE"
        else
                printf -- 'Sudo : No \n' >>"$LOG_FILE"
                printf -- 'Install sudo from repository using apt, yum or zypper based on your distro. \n'
                exit 1
        fi

        if [[ "$FORCE" == "true" ]]; then
                printf -- 'Force attribute provided hence continuing with install without confirmation message\n' |& tee -a "$LOG_FILE"
        else
                # Ask user for prerequisite installation
                printf -- "\nAs part of the installation , dependencies would be installed/upgraded.\n"
                while true; do
                        read -r -p "Do you want to continue (y/n) ? :  " yn
                        case $yn in
                        [Yy]*)
                                printf -- 'User responded with Yes. \n' >>"$LOG_FILE"
                                break
                                ;;
                        [Nn]*) exit ;;
                        *) echo "Please provide confirmation to proceed." ;;
                        esac
                done
        fi
}

function cleanup() {
    # Remove artifacts
    printf -- "Cleaned up the artifacts\n" >> "$LOG_FILE"
}

function configureAndInstall(){
  printf -- 'Configuration and Installation started \n'

  printf -- "Building R %s \n,$PACKAGE_VERSION"

   echo "Java provided by user $JAVA_PROVIDED" >> "$LOG_FILE"
    if [[ "$JAVA_PROVIDED" == "Semeru11" ]]; then
        # Install AdoptOpenJDK 11 (With OpenJ9)
        printf -- "\nInstalling IBM Semeru Runtime (previously known as AdoptOpenJDK openj9) . . . \n"
        cd "$CURDIR"
        wget https://github.com/AdoptOpenJDK/semeru11-binaries/releases/download/jdk-11.0.13%2B8_openj9-0.29.0/ibm-semeru-open-jdk_${archt}_linux_11.0.13_8_openj9-0.29.0.tar.gz
	tar -xf ibm-semeru-open-jdk_${archt}_linux_11.0.13_8_openj9-0.29.0.tar.gz
	export JAVA_HOME=$CURDIR/jdk-11.0.13+8
        printf -- "Installation of IBM Semeru Runtime (previously known as AdoptOpenJDK openj9) is successful\n" >> "$LOG_FILE"
        
      elif [[ "$JAVA_PROVIDED" == "Temurin11" ]]; then
        printf -- "\nInstalling Eclipse Adoptium Temurin Runtime (previously known as AdoptOpenJDK hotspot) . . . \n"
	cd $CURDIR
	wget https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.13%2B8/OpenJDK11U-jre_${archt}_linux_hotspot_11.0.13_8.tar.gz
        tar -xf OpenJDK11U-jre_${archt}_linux_hotspot_11.0.13_8.tar.gz
	export JAVA_HOME=$CURDIR/jdk-11.0.13+8-jre
	printf -- "Installation of Eclipse Adoptium Temurin Runtime (previously known as AdoptOpenJDK hotspot) is successful\n" >> "$LOG_FILE"

    elif [[ "$JAVA_PROVIDED" == "OpenJDK" ]]; then
        cd "$CURDIR"


  case "$DISTRO" in
  "ubuntu-"* )
      sudo apt-get install -y openjdk-11-jdk openjdk-11-jdk-headless
      export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-${archt}/
          printf -- "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-${archt}/\n" >> "$BUILD_ENV"
    ;;

  "rhel-"*)
      sudo yum install -y java-11-openjdk java-11-openjdk-devel
          export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
      printf -- "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk\n" >> "$BUILD_ENV"
    ;;

  "sles-"*)
      sudo zypper install -y java-11-openjdk java-11-openjdk-devel
          export JAVA_HOME=/usr/lib64/jvm/java-11-openjdk/
      printf -- "export JAVA_HOME=/usr/lib64/jvm/java-11-openjdk/\n" >> "$BUILD_ENV"
    ;;

  esac


    else
        err "$JAVA_PROVIDED is not supported, Please use valid java from {Semeru11, Temurin11, OpenJDK} only"
        exit 1
    fi

    export PATH=$JAVA_HOME/bin:/usr/local/bin:/sbin:$PATH
    printf -- 'export PATH=$JAVA_HOME/bin:/usr/local/bin:/sbin:$PATH\n'  >> "$BUILD_ENV"
    printf -- 'export JAVA_HOME for "$ID"  \n'  >> "$LOG_FILE"


  cd "$CURDIR"
  java -version
  curl -sSL $R_URL | tar xzf -
  mkdir build && cd build
  ../R-${PACKAGE_VERSION}/configure --with-x=no --with-pcre1
  make
  sudo make install

  # Run Tests
  runTest

  #Cleanup
  cleanup

  printf -- "\n Installation of %s %s was successful \n\n" $PACKAGE_NAME $PACKAGE_VERSION
}

function runTest() {
  if [[ "$TESTS" == "true" ]]; then
    printf -- "TEST Flag is set , Continue with running test \n"
    printf -- "Installing the dependencies for testing %s,$PACKAGE_NAME \n"

  case "$DISTRO" in
  "ubuntu-"* )
      sudo apt-get install -y texlive-latex-base texlive-latex-extra \
        texlive-fonts-recommended texlive-fonts-extra
      sudo locale-gen "en_US.UTF-8"
      sudo locale-gen "en_GB.UTF-8"
      export LANG="en_US.UTF-8"
      printf -- 'export LANG="en_US.UTF-8"\n'  >> "$BUILD_ENV" 
    ;;

  "rhel-"*)
      sudo yum install -y texlive
      export LANG="en_US.UTF-8"
      printf -- 'export LANG="en_US.UTF-8"\n'  >> "$BUILD_ENV" 
    ;;

  "sles-"*)
      sudo zypper install -y texlive-courier texlive-dvips
      export LANG="en_US.UTF-8"
      printf -- 'export LANG="en_US.UTF-8"\n'  >> "$BUILD_ENV" 
    ;;

  esac

  cd "$CURDIR/build"
  set +e
  make check
  set -e
  printf -- "\nTest execution completed.\n"
  fi
}

function logDetails() {
        printf -- '**************************** SYSTEM DETAILS *************************************************************\n' >"$LOG_FILE"
        if [ -f "/etc/os-release" ]; then
                cat "/etc/os-release" >>"$LOG_FILE"
        fi

        cat /proc/version >>"$LOG_FILE"
        printf -- '*********************************************************************************************************\n' >>"$LOG_FILE"

        printf -- "Detected %s \n" "$PRETTY_NAME"
        printf -- "Request details : PACKAGE NAME= %s , VERSION= %s \n" "$PACKAGE_NAME" "$PACKAGE_VERSION" |& tee -a "$LOG_FILE"
}

# Print the usage message
function printHelp(){
  cat <<eof
  Usage:
  bash build_r.sh [-y] [-d] [-t] [-j (Temurin11|Semeru11|OpenJDK)]
  where:
   -y install-without-confirmation
   -d debug
   -t test
   -j which JDK to use:
        Temurin11 - Eclipse Adoptium Temurin Runtime (previously known as AdoptOpenJDK hotspot)
        Semeru11 - IBM Semeru Runtime (previously known as AdoptOpenJDK openj9)
        OpenJDK - for OpenJDK 11
eof
}

while getopts "h?dytj:" opt; do
        case "$opt" in
        h | \?)
                printHelp
                exit 0
                ;;
        d)
                set -x
                ;;
        y)
                FORCE="true"
                ;;
        t)
                TESTS="true"
                ;;
        j)
                JAVA_PROVIDED="$OPTARG"
        ;;
        esac
done

function gettingStarted()
{
  cat <<-eof
        ***********************************************************************
        Usage:
        *Getting Started * 
        Run following commands to get started: 
        Note: Environmental Variable needed have been added to $HOME/setenv.sh
        Note: To set the Environmental Variable needed for R, please run: source $HOME/setenv.sh
        ***********************************************************************
          R installed successfully.
          More information can be found here:
          https://www.r-project.org/
eof
}


logDetails
checkPrequisites

case "$DISTRO" in
"ubuntu-18.04" | "ubuntu-20.04" | "ubuntu-21.04" | "ubuntu-21.10")
  printf -- "Installing %s %s for %s \n" "$PACKAGE_NAME" "$PACKAGE_VERSION" "$DISTRO" |& tee -a "$LOG_FILE"
  printf -- "Installing dependencies... it may take some time.\n"
  sudo apt-get update -y |& tee -a "$LOG_FILE"
  sudo apt-get install -y  \
    wget curl tar gcc g++ ratfor gfortran libx11-dev make r-base \
    libcurl4-openssl-dev locales \
    |& tee -a "$LOG_FILE"

  configureAndInstall |& tee -a "$LOG_FILE"
;;

"rhel-7.8" | "rhel-7.9")
  printf -- "Installing %s %s for %s \n" "$PACKAGE_NAME" "$PACKAGE_VERSION" "$DISTRO" |& tee -a "$LOG_FILE"
        printf -- "Installing dependencies... it may take some time.\n"
  sudo yum install -y \
    gcc curl wget tar make rpm-build zlib-devel xz-devel ncurses-devel \
    cairo-devel gcc-c++ libcurl-devel libjpeg-devel libpng-devel \
    libtiff-devel readline-devel texlive-helvetic texlive-metafont \
    texlive-psnfss texlive-times xdg-utils pango-devel tcl-devel \
    tk-devel perl-macros info gcc-gfortran libXt-devel \
    perl-Text-Unidecode.noarch bzip2-devel pcre-devel help2man procps \
    |& tee -a "$LOG_FILE"

  configureAndInstall |& tee -a "$LOG_FILE"
;;

"sles-12.5" | "sles-15.2" | "sles-15.3")
  printf -- "Installing %s %s for %s \n" "$PACKAGE_NAME" "$PACKAGE_VERSION" "$DISTRO" |& tee -a "$LOG_FILE"
        printf -- "Installing dependencies... it may take some time.\n"
  sudo zypper install -y \
    curl wget tar rpm-build help2man zlib-devel xz-devel ncurses-devel \
    make cairo-devel gcc-c++ gcc-fortran libcurl-devel libjpeg-devel \
    libpng-devel libtiff-devel readline-devel fdupes texlive-helvetic \
    texlive-metafont texlive-psnfss texlive-times texlive-ae texlive-fancyvrb xdg-utils \
    pango-devel tcl-devel tk-devel xorg-x11-devel perl-macros texinfo \
    |& tee -a "$LOG_FILE"

  configureAndInstall |& tee -a "$LOG_FILE"
;;

esac

gettingStarted |& tee -a "$LOG_FILE"
