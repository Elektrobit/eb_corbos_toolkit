# Copyright 2025 Elektrobit. All rights reserved.

DESCRIPTION = "Hello Safety application"
MAINTAINER = "Hello Safety maintainer"

inherit dpkg

SRC_URI = " \
    file:///workspace/appdev/apps/hello-safety/ \
    file:///workspace/appdev/cmake/toolchain \
    file://rules \
"

# Copy source and CMake toolchain files from fetched directories.
prepare_app_source(){
    cp ${WORKDIR}/workspace/appdev/apps/hello-safety/hello.c ${S}
    cp ${WORKDIR}/workspace/appdev/apps/hello-safety/CMakeLists.txt ${S}
    cp -r ${WORKDIR}/workspace/appdev/cmake ${S}
}

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    prepare_app_source
    deb_debianize
}

# BitBake recipe dependencies
DEPENDS:append = " \
    clang-20 \
    cmake \
    libclang-20-dev \
    libclang-rt-20-dev \
    lisa-elf-enabler-native \
    lld-20 \
    llvm-20-dev \
"

# lisa-libc is only available for arm64
DEPENDS:append:arm64 = " \
    lisa-libc-dev \
    lisa-libc-tools-clang \
"

# Build dependencies for the debian/control file
DEBIAN_BUILD_DEPENDS:append = " , \
    clang-20:native, \
    cmake, \
    libclang-20-dev:native, \
    libclang-rt-20-dev, \
    lisa-elf-enabler, \
    lisa-libc-tools-clang [arm64], \
    lld-20:native, \
    llvm-20-dev:native, \
"
