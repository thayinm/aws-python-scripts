#!/usr/bin/env bash

GCC_VERSION=gcc-12.4.0
git clone -b releases/${GCC_VERSION} https://github.com/gcc-mirror/gcc.git ${GCC_VERSION}

cd ${GCC_VERSION} && ./contrib/download_prerequisites
mkdir build && cd build
../configure --enable-languages=c,c++ --prefix=/usr/local --disable-multilib --disable-bootstrap
make && sudo make install
exit 0