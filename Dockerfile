# TODO: clean-up after apt-get commands
#       see: https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/
#
# SOSRepair requires two different versions of LLVM/Clang:
#
# * SOSRepair itself uses the "latest" version of Clang (TODO: fix this to a particular version)
# * KLEE, a dependency of SOSRepair, requires LLVM/Clang 3.4
#
#
FROM ubuntu:14.04
MAINTAINER Afsoon Afzal (afsoona@cs.cmu.edu)

# Install basic dependencies
RUN apt-get update && \
    apt-get install -y  subversion \
                        vim \
                        git \
                        g++ \
                        python \
                        perl \
                        cmake \
                        unzip \
                        wget \
                        curl \
                        build-essential \
                        bison \
                        flex ssh gdb
ENV CXX=g++

###############################################################################
# Z3
###############################################################################
ENV Z3_REV ce123d9dbcc1b5902bf831c4730e5628387c79dc
RUN git clone https://github.com/Z3Prover/z3.git /tmp/z3 && \
    cd /tmp/z3 && \
    git checkout "${Z3_REV}" && \
    python scripts/mk_make.py && \
    cd build && \
    make -j$(nproc) && \
    make install PREFIX=/opt/sosrepair && \
    rm -rf /tmp/*

###############################################################################
# Clang 3.4.2
###############################################################################
WORKDIR /usr/local/src
RUN wget -O llvm-3.4.tar.gz https://releases.llvm.org/3.4/llvm-3.4.src.tar.gz && \
    tar xf llvm-3.4.tar.gz && rm -f llvm-3.4.tar.gz

WORKDIR /usr/local/src/llvm-3.4/tools
RUN wget -O clang-3.4.tar.gz https://releases.llvm.org/3.4/clang-3.4.src.tar.gz && \
    tar xf clang-3.4.tar.gz && rm -f clang-3.4.tar.gz && mv clang-3.4 clang

WORKDIR /usr/local/src/llvm-3.4/tools/clang/tools
RUN wget -O tools.tar.gz https://releases.llvm.org/3.4/clang-tools-extra-3.4.src.tar.gz && \
    tar xf tools.tar.gz && rm -f tools.tar.gz && mv clang-tools-extra-3.4 extra

RUN apt-get install groff-base
WORKDIR /usr/local/src/llvm-3.4
RUN ./configure --enable-optimized --enable-targets=x86_64 && make -j$(nproc)
RUN make -j$(nproc) install

###############################################################################
# uclibc
###############################################################################
# WARNING: this isn't fixed to a particular version!
RUN mkdir -p /opt/sosrepair
RUN apt-get install -y  libcap-dev \
	                libncurses5-dev \
                        python-minimal \
                        python-pip \
                        groff \
                        libboost-all-dev \
                        zlib1g-dev
RUN git clone https://github.com/klee/klee-uclibc.git /tmp/uclibc && \
    ls /usr/bin && \
    cd /tmp/uclibc && \
    ./configure --with-llvm-config /usr/local/bin/llvm-config \
                --make-llvm-lib && \
    make -j$(nproc) && \
    make install PREFIX=/opt/sosrepair && \
    rm -rf /tmp/*

###############################################################################
# minisat
###############################################################################
# WARNING: this isn't fixed to a particular version!
ENV MINISAT_REV 37dc6c67e2af26379d88ce349eb9c4c6160e8543
RUN git clone https://github.com/stp/minisat.git /tmp/minisat && \
    cd /tmp/minisat && \
    git checkout "${MINISAT_REV}" && \
    mkdir build && \
    cd build && \
    cmake -DSTATIC_BINARIES=ON -DCMAKE_INSTALL_PREFIX=/opt/sosrepair ../ && \
    make -j$(nproc) install && \
    cd / && \
    rm -rf /tmp/*

###############################################################################
# stp
###############################################################################
RUN cd /tmp && \
    wget --quiet https://github.com/stp/stp/archive/2.1.2.tar.gz && \
    tar -xf 2.1.2.tar.gz && \
    cd stp* && \
    mkdir build && \
    cd build && \
    cmake -DSTATIC_BINARIES=ON \
          -DBUILD_SHARED_LIBS:BOOL=OFF \
          -DENABLE_PYTHON_INTERFACE:BOOL=OFF \
          -DCMAKE_INSTALL_PREFIX=/opt/sosrepair .. && \
    make -j$(nproc) && \
    make install && \
    ulimit -s unlimited && \
    rm -rf /tmp/*

###############################################################################
# KLEE
###############################################################################
RUN git clone https://github.com/klee/klee.git /tmp/klee && \
    cd /tmp/klee && \
    git checkout v1.4.0
RUN cd /tmp/klee && \
    ln -s /usr/local/bin/llvm-config /usr/bin/llvm-config && \
    ./configure prefix=/opt/sosrepair \
      --with-stp=/opt/sosrepair \
      --with-uclibc=/opt/sosrepair/usr/x86_64-linux-uclibc/usr/ \
      --enable-posix-runtime \
      LDFLAGS=-L$/opt/sosrepair/lib \
      CPPFLAGS=-I/opt/sosrepair/include && \
    make install -j$(nproc) && \
    cd / && \
    rm -rf /tmp/*

###############################################################################
# patchelf
###############################################################################
RUN apt-get install -y autoconf && \
    cd /tmp && \
    wget -nv https://github.com/NixOS/patchelf/archive/0.9.tar.gz && \
    tar -xf 0.9.tar.gz && \
    cd patchelf-0.9 && \
    ./bootstrap.sh && \
    ./configure && \
    make install && \
    rm -rf /tmp/* && \
    apt-get remove -y autoconf

###############################################################################
# Customised Clang/LLVM installation
###############################################################################
ENV CMAKE_LOCATION /opt/cmake
RUN cd /tmp && \
    wget -nv https://cmake.org/files/v3.10/cmake-3.10.2-Linux-x86_64.tar.gz && \
    tar -xzvf cmake-3.10.2-Linux-x86_64.tar.gz && \
    rm -f cmake-3.10.2-Linux-x86_64.tar.gz && \
    mv cmake-3.10.2-Linux-x86_64 "${CMAKE_LOCATION}"

ADD docker/binary-op.patch /tmp/binary-op.patch
RUN git clone https://github.com/llvm-mirror/llvm /tmp/llvm && \
    cd /tmp/llvm && \
    mkdir build && \
    git checkout release_50 && \
    cd tools && \
    git clone https://github.com/llvm-mirror/clang.git && \
    cd clang && \
    git checkout release_50 && \
    git apply /tmp/binary-op.patch
RUN cd /tmp/llvm/build && \
    /opt/cmake/bin/cmake -G "Unix Makefiles" .. -DCMAKE_BUILD_TYPE=MinSizeRel && \
    make -j$(nproc)
RUN cd /tmp/llvm/build && \
    /opt/cmake/bin/cmake -DCMAKE_INSTALL_PREFIX=/opt/sosrepair/llvm -P cmake_install.cmake
RUN cp -r /tmp/llvm/tools/clang/bindings/python /opt/sosrepair/bindings


###############################################################################
# install postgres
###############################################################################

RUN apt-get install -y postgresql libpq-dev && python -m pip install postgres
USER postgres
RUN  /etc/init.d/postgresql start && psql --command "CREATE USER root WITH SUPERUSER;"
USER root
RUN /etc/init.d/postgresql start && sleep 10 && createdb testdb

###############################################################################
# SOSRepair
###############################################################################
ENV PYTHONPATH="/opt/sosrepair/bindings:${PYTHONPATH}"
ENV CPATH=":/opt/sosrepair/include"
ENV PATH="/opt/sosrepair/bin:$PATH"
RUN mkdir -p /opt/sosrepair/sosrepair && mkdir /opt/sosrepair/sosrepair/logs && mkdir /opt/sosrepair/prepare
WORKDIR /opt/sosrepair/sosrepair
ADD run.py run.py
ADD docker/settings.py settings.py
ADD utils utils
ADD repository repository
ADD fault_localization fault_localization
ADD profile profile

ADD docker/setup.sh /opt/sosrepair/prepare/setup.sh

###############################################################################
# Uninstall build-time dependencies
###############################################################################

###############################################################################
# Create portable volume
###############################################################################
ADD docker/port.py /bin/port
WORKDIR /
RUN port /opt/sosrepair /opt/sosrepair/bin/z3 && \
    port /opt/sosrepair /opt/sosrepair/bin/minisat && \
    port /opt/sosrepair /opt/sosrepair/bin/minisat_core && \
    port /opt/sosrepair /opt/sosrepair/bin/stp-2.1.2 && \
    port /opt/sosrepair /opt/sosrepair/bin/stp_simple && \
    port /opt/sosrepair /opt/sosrepair/bin/kleaver \
        libffi.so.6 libtinfo.so.5 libdl.so.2 && \
    port /opt/sosrepair /opt/sosrepair/bin/klee \
        libffi.so.6 libtinfo.so.5 libdl.so.2
RUN cp /usr/local/bin/clang /opt/sosrepair/bin/clang-3.4 && \
    port /opt/sosrepair /opt/sosrepair/bin/clang-3.4
VOLUME /opt/sosrepair
