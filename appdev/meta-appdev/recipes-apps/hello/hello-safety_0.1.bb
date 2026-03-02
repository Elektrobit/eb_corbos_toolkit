# Copyright 2025 Elektrobit Automotive GmbH
# All rights reserved

DESCRIPTION = "Hello Safety application"
MAINTAINER = "Hello Safety maintainer"

inherit dpkg
require common_appdev.inc

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
    lisa-libc \
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
