FROM ubuntu:22.04
LABEL Name="cowlibration"
USER root
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /tmp
RUN apt-get update \
	&& apt-get install -y apt-utils \
	&& apt-get upgrade -y \
    && apt-get install -y  apt-utils \
	&& apt-get install -y \
        build-essential \
        cmake \
        software-properties-common \
        wget \
        dh-autoreconf \
        libcurl4-gnutls-dev \
        libexpat1-dev \
        gettext \
        libz-dev \
        libssl-dev \
        libceres-dev \
        libgoogle-glog-dev \
        python3-pip \
        libgoogle-glog-dev \
        libopencv-dev \
        libapriltag-dev \
        libcli11-dev \
        asciidoc \
        xmlto \
        docbook2x \
        install-info \
        udev \
        gnupg \
        x11-apps \
        net-tools \
        iputils-ping \
        vim \
        extra-cmake-modules \
        libboost-all-dev \
        git \
	&& rm -rf /var/lib/apt/lists/*

RUN apt-get update \
	&& apt-get install -y apt-utils \
	&& apt-get upgrade -y \
    && apt-get install -y  apt-utils \
	&& apt-get install -y \
	&& rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/michaelgtodd/cowlibration-field.git && \
    cd cowlibration-field && \
    cp -r Ceres /usr/local/lib/cmake/ && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make install

RUN

WORKDIR /
