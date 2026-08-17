# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "Auto-detect terminal size on serial console login"
DESCRIPTION = "Installs a profile.d script that queries the actual terminal \
dimensions via ANSI escape sequences and sets stty rows/cols accordingly. \
Fixes line-wrapping issues when using QEMU -nographic or other serial consoles \
where the guest defaults to 80x24."
LICENSE = "CLOSED"
MAINTAINER = "Elektrobit <info@elektrobit.com>"

inherit dpkg-raw

SRC_URI = "file://50-serial-console-resize.sh"

do_install() {
    install -Dm0755 -t ${D}/etc/profile.d ${WORKDIR}/50-serial-console-resize.sh
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
