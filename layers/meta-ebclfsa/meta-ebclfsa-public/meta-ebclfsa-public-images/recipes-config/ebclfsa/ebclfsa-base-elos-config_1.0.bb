# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "Elos configuration files"
LICENSE = "CLOSED"

inherit dpkg-raw

SRC_URI = "file://eventlogging_json.json"

do_install() {
    install -Dm0755 -t ${D}/etc/elos/eventlogging.d/ ${WORKDIR}/eventlogging_json.json
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
