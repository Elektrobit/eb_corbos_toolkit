# Copyright 2026 Elektrobit. All rights reserved.

inherit multiarch_helper

# Common dependencies
SBUILD_CHROOT_COMPAT_PREINSTALL ?= ""
SBUILD_CHROOT_PREINSTALL_EXTRA:append = " \
    gzip \
"

# Ensure all dependencies are fetched prior to build
RDEPENDS:append = " ${@isar_multiarch_recipes('ROOTFS_PACKAGES', 'ROOTFS_ARCH', d)}"
