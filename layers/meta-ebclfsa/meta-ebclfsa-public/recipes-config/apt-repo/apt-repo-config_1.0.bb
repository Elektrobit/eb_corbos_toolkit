# Copyright 2026 Elektrobit. All rights reserved.

DESCRIPTION = "Install additional upstream apt repositories"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

DPKG_ARCH = "any"

# This package can only be installed in systems containing apt
# A production image should NOT contain apt!
DEPENDS:append = " \
    apt \
    ncurses-base \
"
DEBIAN_DEPENDS = "${@ ', '.join(d.getVar('DEPENDS').split())}"

SRC_URI = " \
    file://ebcl.sources \
    file://debian.sources \
"

do_install(){
    install -Dm0644 -t ${D}/etc/apt/sources.list.d/ \
        ${WORKDIR}/ebcl.sources
    install -m 644 ${WORKDIR}/debian.sources \
        ${D}/etc/apt/sources.list.d/debian.sources
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
