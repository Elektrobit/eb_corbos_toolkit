# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "crinit configuration file for setmachineid"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

DEPENDS:append = " ebclfsa-base-setmachineid"
DEBIAN_DEPENDS:append = " , ${@ ', '.join(d.getVar('DEPENDS').split()) }"

SRC_URI = " \
    file://machine-id.crinit \
"

do_install(){
    install -Dm0644 -t ${D}/etc/crinit/crinit.d ${WORKDIR}/machine-id.crinit
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
