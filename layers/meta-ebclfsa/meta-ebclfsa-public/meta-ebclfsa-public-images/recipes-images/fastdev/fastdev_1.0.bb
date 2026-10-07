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

require recipes-images/common/ebclfsa-dev.inc

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

# Add included features to rootfs
IMAGE_INSTALL:append = " \
    ${EBCLFSA_FASTDEV_FEATURES_CONTENT} \
"

UNWANTED_PKGS = " \
    linux-firmware \
    wireless-regdb \
"

# Do not update fstab when creating wic images
WIC_CREATE_EXTRA_ARGS:append = " --no-fstab-update"
