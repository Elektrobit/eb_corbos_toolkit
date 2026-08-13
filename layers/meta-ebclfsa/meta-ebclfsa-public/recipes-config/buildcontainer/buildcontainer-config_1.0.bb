# Copyright 2026 Elektrobit. All rights reserved.

DESCRIPTION = "Mandatory buildcontainer config"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

DEPENDS:append = " \
    sudo \
    sbuild \
    locales \
    gzip \
    ncurses-base \
"
DEBIAN_DEPENDS = "${@ ', '.join(d.getVar('DEPENDS').split())}"

SRC_URI = " \
    file://postinst \
    file://developer \
"

do_install(){
    install -Dm0444 -t ${D}/etc/sudoers.d/ ${WORKDIR}/developer
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
