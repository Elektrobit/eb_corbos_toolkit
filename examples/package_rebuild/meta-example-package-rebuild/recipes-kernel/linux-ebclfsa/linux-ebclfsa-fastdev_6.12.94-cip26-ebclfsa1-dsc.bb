# Copyright 2026 Elektrobit. All rights reserved.

inherit dpkg_kernel_rebuild
require recipes-kernel/linux-ebclfsa-fastdev/linux-ebclfsa-fastdev_6.12.94-cip26-ebclfsa1+r0.src.inc

SRC_URI += "file://0001-Add-custom-extraversion.patch"
SRC_URI += "file://synproxy.cfg"

S = "${WORKDIR}/linux-ebclfsa-fastdev-6.12.94-cip26-ebclfsa1"
