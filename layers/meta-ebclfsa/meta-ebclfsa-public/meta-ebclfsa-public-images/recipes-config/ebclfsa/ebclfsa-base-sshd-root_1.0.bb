# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "Allow root login over SSH"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

DEPENDS:append = " openssh-server"
DEBIAN_DEPENDS:append = " , ${@ ', '.join(d.getVar('DEPENDS').split()) }"

SRC_URI = " \
    file://10-root-login.conf \
"

do_install(){
    install -Dm0644 -t ${D}/etc/ssh/sshd_config.d ${WORKDIR}/10-root-login.conf
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
