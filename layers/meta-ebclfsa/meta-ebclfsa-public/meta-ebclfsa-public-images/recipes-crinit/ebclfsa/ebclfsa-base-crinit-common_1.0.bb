# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "crinit common configuration files for EBcLfSA"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

DEPENDS:append = " \
    elosd \
    iputils-ping \
    netifd \
    ntpsec-ntpdate \
    ubus \
"

DEBIAN_DEPENDS:append = " , ${@ ', '.join(d.getVar('DEPENDS').split()) }"

SRC_URI = " \
    file://default.series \
    file://crinit.d \
"

do_install(){
    install -Dm0644 -t ${D}/etc/crinit/ ${WORKDIR}/default.series
    install -Dm0644 -t ${D}/etc/crinit/crinit.d ${WORKDIR}/crinit.d/*
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
