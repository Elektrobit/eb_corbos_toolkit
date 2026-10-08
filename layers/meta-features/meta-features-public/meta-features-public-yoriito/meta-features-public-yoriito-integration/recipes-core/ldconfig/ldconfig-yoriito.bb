# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "ldconfig config fragment for Yoriito"
DESCRIPTION = "Installs the ldconfig config fragment to /etc/ld.so.conf.d"
AUTHOR = "Yoriito"
HOMEPAGE = "None"
BUGTRACKER = "None"
SECTION = "libs"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${YORIITO_LICENSE_PATH}/Apache-2.0;md5=e23fadd6ceef8c618fc1c65191d846fa"

inherit dpkg-raw

MAINTAINER = "Yoriito <info@yoriito.example>"

do_install() {
    install -d ${D}${sysconfdir}/ld.so.conf.d
    echo "${libdir}/yoriito" > ${D}${sysconfdir}/ld.so.conf.d/yoriito.conf
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
