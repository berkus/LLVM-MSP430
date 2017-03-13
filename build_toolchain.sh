#!/bin/sh

echo "===================================================================="
echo "I will try to fetch and build everything needed for a freestanding"
echo "cross-compiler toolchain. This includes llvm, clang, and lld"
echo "and may take quite a while to build. Play some tetris and check back"
echo "every once in a while. The process is largely automatic and should"
echo "not require any manual intervention. Fingers crossed!"
echo
echo "You'll need UNIX tools git, cmake, and ninja."
echo
echo "Specify LIBCXX_TRIPLE if you're not on mac"
echo "===================================================================="
echo

# *** USER-ADJUSTABLE SETTINGS ***

export LLVM_TARGETS="MSP430"

export LLVM_REVISION=origin/master
export CLANG_REVISION=origin/master
export COMPILER_RT_REVISION=origin/master
export LIBCXX_REVISION=origin/master
export LIBCXXABI_REVISION=origin/master
export LLD_REVISION=origin/master
if [ -z $LIBCXX_TRIPLE ]; then
    export LIBCXX_TRIPLE=-apple-
fi

# END OF USER-ADJUSTABLE SETTINGS

which git || (echo "Install git: brew install git"; exit)
which cmake || (echo "Install cmake: brew install cmake"; exit)
which ninja || (echo "Install ninja: brew install ninja"; exit)

mkdir -p toolchain/{build/llvm,sources}
cd toolchain/

export TOOLCHAIN_DIR=`pwd`

REPOBASE=https://github.com/llvm-mirror

echo "===================================================================="
echo "Checking out llvm [$LLVM_REVISION] / compiler-rt [$COMPILER_RT_REVISION]..."
echo "===================================================================="

if [ ! -d sources/llvm ]; then
    git clone $REPOBASE/llvm.git sources/llvm
    (cd sources/llvm; git checkout $LLVM_REVISION)
else
    (cd sources/llvm; git fetch; git checkout $LLVM_REVISION)
fi

if [ ! -d sources/llvm/projects/compiler-rt ]; then
    git clone $REPOBASE/compiler-rt.git sources/llvm/projects/compiler-rt
    (cd sources/llvm/projects/compiler-rt; git checkout $COMPILER_RT_REVISION)
else
    (cd sources/llvm/projects/compiler-rt; git fetch; git checkout $COMPILER_RT_REVISION)
fi

echo "===================================================================="
echo "Checking out clang [$CLANG_REVISION]..."
echo "===================================================================="

if [ ! -d sources/llvm/tools/clang ]; then
    git clone $REPOBASE/clang.git sources/llvm/tools/clang
    (cd sources/llvm/tools/clang; git checkout $CLANG_REVISION)
else
    (cd sources/llvm/tools/clang; git fetch; git checkout $CLANG_REVISION)
fi

echo "===================================================================="
echo "Checking out lld [$LLD_REVISION]..."
echo "===================================================================="

if [ ! -d sources/llvm/tools/lld ]; then
    git clone $REPOBASE/lld.git sources/llvm/tools/lld
    (cd sources/llvm/tools/lld; git checkout $LLD_REVISION)
else
    (cd sources/llvm/tools/lld; git fetch; git checkout $LLD_REVISION)
fi

echo "===================================================================="
echo "Checking out recent libcxx/libcxxabi [$LIBCXX_REVISION]..."
echo "===================================================================="

if [ ! -d sources/llvm/projects/libcxx ]; then
    git clone $REPOBASE/libcxx.git sources/llvm/projects/libcxx
    (cd sources/llvm/projects/libcxx; git checkout $LIBCXX_REVISION)
else
    (cd sources/llvm/projects/libcxx; git fetch; git checkout $LIBCXX_REVISION)
fi

if [ ! -d sources/llvm/projects/libcxxabi ]; then
    git clone $REPOBASE/libcxxabi.git sources/llvm/projects/libcxxabi
    (cd sources/llvm/projects/libcxxabi; git checkout $LIBCXXABI_REVISION)
else
    (cd sources/llvm/projects/libcxxabi; git fetch; git checkout $LIBCXXABI_REVISION)
fi

echo "===================================================================="
echo "Configuring llvm..."
echo "===================================================================="

if [ ! -f build/llvm/.config.succeeded ]; then
    cd build/llvm && \
    cmake -DCMAKE_BUILD_TYPE=Release -G Ninja -DCMAKE_INSTALL_PREFIX=$TOOLCHAIN_DIR/clang -DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++" -DLLVM_ENABLE_CXX1Y=ON -DLLVM_TARGETS_TO_BUILD=$LLVM_TARGETS -DLLVM_TARGET_ARCH=$LLVM_TARGETS -DLLVM_CREATE_XCODE_TOOLCHAIN=ON ../../sources/llvm && \
    touch .config.succeeded && \
    cd ../.. || exit 1
else
    echo "build/llvm/.config.succeeded exists, NOT reconfiguring llvm!"
fi

echo "===================================================================="
echo "Building llvm... this may take a long while"
echo "===================================================================="

if [ ! -f build/llvm/.build.succeeded ]; then
    cd build/llvm && \
    ninja && \
    touch .build.succeeded && \
    cd ../.. || exit 1
else
    echo "build/llvm/.build.succeeded exists, NOT rebuilding llvm!"
fi

echo "===================================================================="
echo "Installing llvm, libcxx, clang & lld..."
echo "===================================================================="

if [ ! -f build/llvm/.install.succeeded ]; then
    cd build/llvm && \
    ninja install && \
    touch .install.succeeded && \
    cd ../.. || exit 1
else
    echo "build/llvm/.install.succeeded exists, NOT reinstalling llvm!"
fi

echo "===================================================================="
echo "To clean up:"
echo "cd toolchain"
echo "rm -rf build sources"
echo
echo "Toolchain binaries will remain in clang/ and libcxx/"
echo "where Metta configure will find them."
echo "===================================================================="
echo
echo "===================================================================="
echo "===================================================================="
echo "All done, enjoy!"
echo "===================================================================="
echo "===================================================================="

cd ..
