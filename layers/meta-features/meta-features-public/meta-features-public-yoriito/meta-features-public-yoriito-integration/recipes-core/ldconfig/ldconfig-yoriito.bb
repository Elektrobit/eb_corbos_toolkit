# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "ldconfig config fragment for Yoriito"
DESCRIPTION = "Installs the ldconfig config fragment to /etc/ld.so.conf.d"
MAINTAINER = "Elektrobit <info@elektrobit.com>"
HOMEPAGE = "None"
SECTION = "libs"
LICENSE = "Apache-2.0"

inherit dpkg-raw

MAINTAINER = "Yoriito <info@yoriito.example>"

do_install() {
    install -d ${D}${sysconfdir}/ld.so.conf.d
    echo "${libdir}/yoriito" > ${D}${sysconfdir}/ld.so.conf.d/yoriito.conf
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
