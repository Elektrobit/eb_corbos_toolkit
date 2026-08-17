# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "Allow the admin user to run all sudo commands without a password"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

DEPENDS:append = " sudo"
DEBIAN_DEPENDS:append = " , ${@ ', '.join(d.getVar('DEPENDS').split()) }"

SRC_URI = " \
    file://admin \
"

do_install(){
    install -Dm0644 -t ${D}/etc/sudoers.d ${WORKDIR}/admin
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
