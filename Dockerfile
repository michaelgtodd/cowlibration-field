FROM ubuntu:22.04
LABEL Name="cowlibration"
USER root
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /tmp
RUN apt-get update \
	&& apt-get install -y apt-utils \
	&& apt-get upgrade -y \
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
        nlohmann-json3-dev \
        libeigen3-dev \
	&& rm -rf /var/lib/apt/lists/*

RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    apt-get update && \
    apt-get -y install cuda && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ceres-solver/ceres-solver.git --branch 2.2.0 && \
    cd ceres-solver && \
    mkdir build && \
    cd build && \
    CUDACXX=/usr/local/cuda-12.8/bin/nvcc cmake .. -DBUILD_EXAMPLES=OFF -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF && \
    make -j4 install && \
    cp /usr/local/lib/cmake/Ceres/CeresConfig.cmake /usr/local/lib/cmake/Ceres/ceresConfig.cmake

RUN git clone https://github.com/michaelgtodd/cowlibration-field.git && \
    cd cowlibration-field && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j && \
    cp ./FieldCalibrator /usr/bin



# #Cheap fix for sudo issues
# RUN usermod -aG sudo ubuntu \
#     && echo 'ubuntu:ubuntu' | chpasswd \
#     && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | (sudo su -c 'EDITOR="tee -a" visudo') \
#     && useradd -m -s $(which bash) -G sudo ubuntu1 \
#     && echo 'ubuntu1:ubuntu' | chpasswd \
#     && echo "ubuntu1 ALL=(ALL) NOPASSWD:ALL" | (sudo su -c 'EDITOR="tee -a" visudo') \
#     && useradd -m -s $(which bash) -G sudo ubuntu2 \
#     && echo 'ubuntu2:ubuntu' | chpasswd \
#     && echo "ubuntu2 ALL=(ALL) NOPASSWD:ALL" | (sudo su -c 'EDITOR="tee -a" visudo') \
#     && useradd -m -s $(which bash) -G sudo ubuntu3 \
#     && echo 'ubuntu3:ubuntu' | chpasswd \
#     && echo "ubuntu3 ALL=(ALL) NOPASSWD:ALL" | (sudo su -c 'EDITOR="tee -a" visudo') \
#     && useradd -m -s $(which bash) -G sudo ubuntu4 \
#     && echo 'ubuntu4:ubuntu' | chpasswd \
#     && echo "ubuntu4 ALL=(ALL) NOPASSWD:ALL" | (sudo su -c 'EDITOR="tee -a" visudo')


SHELL ["/bin/sh", "-c"]

RUN mkdir /mnt/working

WORKDIR /mnt/working
