# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "crinit configuration file for sshd"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

DEPENDS:append = " \
    ebclfsa-openssh-server-keys-crinit \
"

DEBIAN_DEPENDS = " \
    \${misc:Depends}, \
    ${@ ', '.join(d.getVar('DEPENDS').split()) } \
"

SRC_URI = " \
    file://sshd.crinit \
"

do_install(){
    install -Dm0644 -t ${D}/etc/crinit/crinit.d ${WORKDIR}/sshd.crinit
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
