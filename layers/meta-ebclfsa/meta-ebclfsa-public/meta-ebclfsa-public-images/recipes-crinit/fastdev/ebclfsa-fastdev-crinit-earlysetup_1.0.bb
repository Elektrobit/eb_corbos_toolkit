# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "crinit configuration file for earlysetup"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

DEPENDS:append = " \
    hostname \
"

DEBIAN_DEPENDS:append = " , ${@ ', '.join(d.getVar('DEPENDS').split()) }"

SRC_URI = " \
    file://earlysetup.crinit \
"

do_install(){
    install -Dm0644 -t ${D}/etc/crinit/crinit.d ${WORKDIR}/earlysetup.crinit
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
