# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "Yoriito VSS JSON file based on COVESA v5.0 release"
DESCRIPTION = "Installs vss.json to /etc/yoriito/viss and the CSV catalogue to \
/usr/share/yoriito from the v5.0 release of the COVESA Vehicle Signal Specification"
MAINTAINER = "Elektrobit <info@elektrobit.com>"
HOMEPAGE = "https://github.com/yoriito/yoriito-vss"
SECTION = "misc"
LICENSE = "Apache-2.0"

SRC_URI = "https://github.com/yoriito/yoriito-vss/archive/refs/tags/v${PV}.tar.gz;downloadfilename=${PN}-${PV}.tar.gz;name=src"
SRC_URI[src.sha256sum] = "9aba7f8fb0e51a9af270617abf29e4702aa3473ffc5ac3f70364153b12cb51bd"

# Debian packaging files, fetched as local files and placed into ${S}/debian
# so that ISAR can build the package from source via dpkg-buildpackage.
SRC_URI += " \
    file://debian/changelog;subdir=${PN}-${PV} \
    file://debian/control;subdir=${PN}-${PV} \
    file://debian/copyright;subdir=${PN}-${PV} \
    file://debian/rules;subdir=${PN}-${PV} \
    file://debian/source/format;subdir=${PN}-${PV} \
"

S = "${WORKDIR}/${PN}-${PV}"

inherit dpkg
