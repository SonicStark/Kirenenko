#!/bin/bash
BIN_PATH=$(readlink -f "$0")
ROOT_DIR=$(dirname $(dirname $BIN_PATH))

set -euxo pipefail

git submodule init
git submodule update

sudo apt-get update
sudo apt-get install -y libc6 libstdc++6 linux-libc-dev gcc-multilib \
    cmake clang llvm-dev g++ g++-multilib python python-pip zlib1g-dev \
    libc++-dev libc++abi-dev

PREFIX=${PREFIX:-${ROOT_DIR}/bin/}

# install Z3
pushd z3
rm -rf build
python scripts/mk_make.py
pushd build
make -j$(nproc)
sudo make install
popd
popd

mkdir -p ${PREFIX}
mkdir -p ${PREFIX}/lib
# cp target/release/fuzzer ${PREFIX}
# cp target/release/*.a ${PREFIX}/lib

pushd llvm_mode
rm -rf build
mkdir -p build
pushd build

export CC=clang
export CXX=clang++

if   [ "${BUILD_TYPE}" = "0" ]; then
    ### Build Normal ###
    cmake -DDmpConstraints_state=OFF -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_BUILD_TYPE=Release ..
elif [ "${BUILD_TYPE}" = "1" ]; then
    ### Build for dumping constraints ###
    cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_BUILD_TYPE=Release ..
elif [ "${BUILD_TYPE}" = "2" ]; then
    ### Build for dumping constraints(with line split for debug) ###
    cmake -DDmpConstraints_debug=ON -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_BUILD_TYPE=Release ..
else
    echo "Bad BUILD_TYPE"
    exit
fi

make -j$(nproc)
sudo make install
popd
popd

