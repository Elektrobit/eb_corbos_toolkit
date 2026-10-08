# Copyright 2025 Elektrobit. All rights reserved.

DESCRIPTION = "Hello Safety application"
MAINTAINER = "Hello Safety maintainer"

inherit dpkg

# BitBake recipe dependencies
DEPENDS:append = " \
    clang-20 \
    cmake \
    libclang-20-dev \
    libclang-rt-20-dev \
    lisa-elf-enabler-native \
    lld-20 \
    llvm-20-dev \
    ebclfsa-cmake \
"

# lisa-libc is only available for arm64
DEPENDS:append:arm64 = " \
    lisa-libc-dev \
    lisa-libc-tools-clang \
"

SRC_URI = " \
    file:///workspace/examples/appdev/apps/hello-safety/ \
    file://rules \
"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp ${WORKDIR}/workspace/examples/appdev/apps/hello-safety/hello.c ${S}
    cp ${WORKDIR}/workspace/examples/appdev/apps/hello-safety/CMakeLists.txt ${S}
    deb_debianize
}

# Build dependencies for the debian/control file
DEBIAN_BUILD_DEPENDS:append = " , \
    clang-20:native, \
    cmake, \
    ebclfsa-cmake, \
    libclang-20-dev:native, \
    libclang-rt-20-dev, \
    lisa-elf-enabler, \
    lisa-libc-tools-clang [arm64], \
    lld-20:native, \
    llvm-20-dev:native, \
"
