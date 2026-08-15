# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "crinit configuration file for getty"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

DEBIAN_DEPENDS:append = " , ${@ ', '.join(d.getVar('DEPENDS').split()) }"

SRC_URI = " \
    file://getty-console.crinit \
"

do_install(){
    install -Dm0644 -t ${D}/etc/crinit/crinit.d ${WORKDIR}/getty-console.crinit
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
