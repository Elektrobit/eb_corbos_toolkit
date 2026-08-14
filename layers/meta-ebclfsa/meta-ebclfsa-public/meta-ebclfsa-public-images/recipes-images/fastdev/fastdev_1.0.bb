# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "EBcLfSA fastdev image"
LICENSE = "CLOSED"

inherit ebclfsa_image

# Include BSP-specific image configuration if available
# (keep the next line empty - there is a bug in oelint that requires this)

# nooelint: oelint.file.requireinclude oelint.file.includenotfound
include recipes-images/fastdev/fastdev-bsp.inc

# Default values for qemu environment
EBCLFSA_FASTDEV_COMPATIBLE_MACHINE ?= "ebcl-qemuarm64"
EBCLFSA_FASTDEV_FSTAB_CONFIG ?= "ebclfsa-fastdev-fstab"
EBCLFSA_FASTDEV_NETWORK_CONFIG ?= "ebclfsa-fastdev-network"
EBCLFSA_FASTDEV_SERIAL_CONFIG ?= "ebclfsa-fastdev-crinit-getty"

IMAGE_FSTYPES = "wic"
WKS_FILE = "baremetal-${MACHINE}.wks.in"

KERNEL_IMAGE_PKG = "${EBCLFSA_FASTDEV_KERNEL_PKG}"

COMPATIBLE_MACHINE = "${EBCLFSA_FASTDEV_COMPATIBLE_MACHINE}"

EBCL_BOOTLOADER = "1"

require recipes-images/common/ebclfsa-common.inc

# Additional fastdev-specific system packages
IMAGE_INSTALL:append = " \
    apt-repo-config \
    cron \
    cryptsetup-bin \
    fdisk \
    gdbserver \
    init-system-helpers \
    iptables \
    kmod \
    ntpsec-ntpdate \
    openssh-client \
    psmisc \
    vim \
"

# Additional fastdev-specific config packages
IMAGE_INSTALL:append = " \
    ebclfsa-fastdev-crinit-earlysetup\
"

# BSP-specific packages
IMAGE_INSTALL:append = " \
    ${EBCLFSA_FASTDEV_FSTAB_CONFIG} \
    ${EBCLFSA_FASTDEV_NETWORK_CONFIG} \
    ${EBCLFSA_FASTDEV_SERIAL_CONFIG} \
"

# Fastdev-specific packages created from BitBake recipes
IMAGE_INSTALL:append = " \
    ebclfsa-comfwdlib-sim \
    ebclfsa-hi-cflinit \
    ebclfsa-hi-demo \
    ebclfsa-li-demo \
"

# Graphics: DRM/Mesa — only when 'graphics' feature is enabled
IMAGE_INSTALL:append = " \
    ${@ bb.utils.contains('EBCLFSA_DISTRO_FEATURES', 'graphics', ' \
    libdrm2 \
    libgbm1 \
    libegl1 \
    libgles2 \
    libgl1-mesa-dri \
    mesa-utils \
    kmscube \
    ', '', d)} \
"

# Wayland compositor: Weston + udev + crinit services — only when 'compositor' feature is enabled
IMAGE_INSTALL:append = " \
    ${@ bb.utils.contains('EBCLFSA_DISTRO_FEATURES', 'compositor', ' \
    weston \
    xwayland \
    udev \
    ebclfsa-base-crinit-weston \
    ', '', d)} \
"

# Qt6: runtime libraries and examples — only when 'qt' feature is enabled
IMAGE_INSTALL:append = " \
    ${@ bb.utils.contains('EBCLFSA_DISTRO_FEATURES', 'qt', ' \
    qt6-wayland \
    libqt6qml6 \
    libqt6quick6 \
    libqt6widgets6 \
    qml6-module-qtquick \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-window \
    qt6-base-examples \
    ', '', d)} \
"

UNWANTED_PKGS = " \
    linux-firmware \
    wireless-regdb \
"

SDK_INSTALL:append = " \
    lisa-elf-enabler \
    lisa-libc-tools-clang \
    clang-20 \
    lld-20 \
    libz3-4 \
"

DEPENDS:append = " libclang-rt-20-dev"
ROOTFS_PACKAGES:class-sdk += "libclang-rt-20-dev:arm64"

# Add user and group for elos
GROUPS += "elos"
GROUP_elos[flags] = "system"

USERS += "elos"
USER_elos[gid] = "elos"
USER_elos[shell] = "/bin/false"

# Do not update fstab when creating wic images
WIC_CREATE_EXTRA_ARGS:append = " --no-fstab-update"
