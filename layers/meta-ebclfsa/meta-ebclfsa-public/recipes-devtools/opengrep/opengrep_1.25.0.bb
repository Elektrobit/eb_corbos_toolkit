# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "OpenGrep static binary"
DESCRIPTION = "Code search, linting, and rewriting tool"
HOMEPAGE = "https://github.com/opengrep/opengrep"
SECTION = "devtools"
LICENSE = "LGPL-2.1-only"
MAINTAINER = "Elektrobit <info@elektrobit.com>"

inherit dpkg-raw

DPKG_ARCH = "amd64"

python() {
    if d.getVar('DISTRO_ARCH') != 'amd64':
        raise bb.parse.SkipRecipe("opengrep is only available for amd64")
}

SRC_URI = "https://github.com/opengrep/opengrep/releases/download/v${PV}/opengrep_manylinux_x86;name=bin"
SRC_URI[bin.sha256sum] = "9ac4aebb47ba3f7b0d8fc641ac8749cb6c2f253f616131a67d9631e00d4bea33"

DEB_BUILD_OPTIONS:append = " nostrip noautodbgsym"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -Dm0755 ${WORKDIR}/opengrep_manylinux_x86 ${D}/usr/bin/opengrep
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
