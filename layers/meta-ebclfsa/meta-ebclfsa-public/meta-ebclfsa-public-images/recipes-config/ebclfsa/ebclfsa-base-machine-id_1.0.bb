# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "Default machine-id for systems without systemd"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

SRC_URI = " \
    file://machine-id \
"

do_install(){
    install -Dm0644 -t ${D}/etc ${WORKDIR}/machine-id
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
