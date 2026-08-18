# Copyright 2026 Elektrobit. All rights reserved.

# From https://gitext.elektrobitautomotive.com/EB-Linux/bart-images/blob/71eebb5d2dc40b2479777d90308d4142ee6259f8/baseos/s32-ut-kis-image/root/usr/sbin/setmachineid
SUMMARY = "Script to set the machine-id based on hardware identifiers"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

DEPENDS:append = " \
    uuid \
    grep \
"

DEBIAN_DEPENDS:append = " , ${@ ', '.join(d.getVar('DEPENDS').split()) }"

SRC_URI = " \
    file://setmachineid \
"

do_install(){
    install -Dm0755 -t ${D}/usr/sbin ${WORKDIR}/setmachineid
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
