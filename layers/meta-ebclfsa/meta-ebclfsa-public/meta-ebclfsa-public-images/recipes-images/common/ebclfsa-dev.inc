# Copyright 2026 Elektrobit. All rights reserved.

# Common EBcLfSA image development packages

# Some additional packages, useful for development images
IMAGE_INSTALL:append = " \
    apt-repo-config \
    cron \
    fdisk \
    gdbserver \
    iptables \
    kmod \
    openssh-client \
    psmisc \
    vim \
"

# Additional host architecture tools
SDK_INSTALL:append = " \
    lisa-elf-enabler \
    lisa-libc-tools-clang \
    clang-20 \
    lld-20 \
    libz3-4 \
"

# Additional target architecture development files and debug symbols
DEPENDS:append = " \
    libclang-rt-20-dev \
    libc6-dbg \
    lisa-libcxx-dev \
"
ROOTFS_PACKAGES:class-sdk += "\
    libclang-rt-20-dev:arm64 \
    libc6-dbg:arm64 \
    lisa-libcxx-dev:arm64 \
"
