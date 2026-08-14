# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "RPI-specific crinit configuration file for getty"
LICENSE = "CLOSED"
MAINTAINER = "Elektrobit <info@elektrobit.com>"

inherit dpkg-raw

DEBIAN_DEPENDS:append = " , ${@ ', '.join(d.getVar('DEPENDS').split()) }"

SRC_URI = " \
    file://getty-tty1.crinit \
    file://getty-ttyS0.crinit \
"

do_install(){
    install -Dm0644 -t ${D}/etc/crinit/crinit.d ${WORKDIR}/getty-tty1.crinit
    install -Dm0644 -t ${D}/etc/crinit/crinit.d ${WORKDIR}/getty-ttyS0.crinit
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
