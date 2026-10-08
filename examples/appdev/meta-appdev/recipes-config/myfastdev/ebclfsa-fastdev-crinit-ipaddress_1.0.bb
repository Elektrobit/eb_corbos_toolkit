# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "crinit configuration file ip address"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "IP address crinit task maintainer"

DEPENDS:append = " iproute2"
DEBIAN_DEPENDS:append = " iproute2"

SRC_URI = " \
    file://ipaddress.crinit \
"

do_install(){
    install -Dm0644 -t ${D}/etc/crinit/crinit.d ${WORKDIR}/ipaddress.crinit
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
