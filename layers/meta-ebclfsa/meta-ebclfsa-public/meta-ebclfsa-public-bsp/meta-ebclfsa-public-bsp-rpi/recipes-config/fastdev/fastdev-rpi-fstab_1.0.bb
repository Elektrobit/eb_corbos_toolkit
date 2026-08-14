# Copyright 2026 Elektrobit. All rights reserved.

DESCRIPTION = "RPI-specific mount configuration for fastdev"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

SRC_URI = " \
    file://fstab \
"

do_install(){
    install -Dm0644 -t ${D}/etc ${WORKDIR}/fstab

    # Create mount point
    install -dm0755 ${D}/data
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
