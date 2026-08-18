# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "Set environment variable for cfl simulation"
LICENSE = "CLOSED"
MAINTAINER = "Elektrobit <info@elektrobit.com>"

inherit dpkg-raw

SRC_URI = "file://50-cfl-sim.sh"

do_install() {
    install -Dm0755 -t ${D}/etc/profile.d ${WORKDIR}/50-cfl-sim.sh
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
