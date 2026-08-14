# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "crinit configuration files for weston compositor"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

SRC_URI = " \
    file://udevd.crinit \
    file://weston.crinit \
"

do_install(){
    install -Dm0644 -t ${D}/etc/crinit/crinit.d ${WORKDIR}/udevd.crinit
    install -Dm0644 -t ${D}/etc/crinit/crinit.d ${WORKDIR}/weston.crinit
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
